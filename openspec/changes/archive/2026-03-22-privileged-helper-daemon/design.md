# Technical Design: Privileged Helper Daemon

## Context

### 当前架构

```
┌─────────────────┐
│   GUI App       │
│   (用户进程)     │
├─────────────────┤
│ AuthorizationRef│──────▶ 弹出密码框 (5分钟超时)
│                 │
│ kextload/unload │
│ SMC Read        │
└─────────────────┘
```

**问题**: 每次 `AuthorizationRef` 过期都需要重新输入密码。

### 目标架构

```
┌─────────────────┐                    ┌─────────────────────┐
│   GUI App       │                    │  Helper Tool        │
│   (用户进程)     │                    │  (root 权限)        │
├─────────────────┤                    ├─────────────────────┤
│ XPC Client      │◀────XPC/Mach IPC──▶│ XPC Server          │
│                 │                    │                     │
│ Auto Mode       │                    │ kextload/unload     │
│ UI              │                    │ SMC Read            │
└─────────────────┘                    └─────────────────────┘
                                                │
                                                ▼
                                       /Library/LaunchDaemons/
```

### 约束

- 最低支持 macOS 10.13
- 项目使用 Objective-C，Helper Tool 可使用 Swift
- 需要代码签名才能正常工作
- 必须向后兼容（未安装 Helper 时回退到原有流程）

## Goals / Non-Goals

**Goals:**

1. 实现一次性授权，用户只需输入一次密码
2. Helper Tool 以 root 权限持久运行，无需重复授权
3. 通过 XPC 安全通信，验证调用者身份
4. 支持自动安装和更新 Helper Tool
5. 保持向后兼容，未安装时回退到原流程

**Non-Goals:**

1. 不重写整个应用为 Swift
2. 不改变现有的 UI 和用户体验
3. 不支持 macOS 10.12 及以下版本
4. 不实现自动更新功能（后续版本考虑）

## Decisions

### 1. 通信框架选择

**决策**: 使用 SecureXPC + Blessed 库

**理由**:
- SecureXPC 提供类型安全的 XPC 通信，自动处理序列化
- Blessed 封装了复杂的 SMJobBless 流程，提供清晰的错误信息
- 两个库都是开源的，MIT 许可证
- 活跃维护，有完整示例项目

**替代方案**:
| 方案 | 优点 | 缺点 |
|------|------|------|
| 原生 XPC API | 无依赖 | 代码冗长，易出错 |
| NSXPCConnection | Apple 官方 | 不支持 Mach Service 的安全验证 |
| 自定义 Mach ports | 完全控制 | 复杂度高，安全隐患 |

### 2. Helper Tool 语言选择

**决策**: Helper Tool 使用 Swift 编写

**理由**:
- SecureXPC 和 Blessed 都是 Swift 库
- Swift 的并发模型更适合处理异步 XPC 请求
- 可以与 Objective-C 代码互操作
- 未来更容易迁移主应用

### 3. 安装时机

**决策**: 首次需要特权操作时安装

**流程**:
1. 用户点击"禁用 Turbo Boost"
2. 检测 Helper 是否已安装
3. 未安装 → 弹出授权对话框 → 安装 Helper
4. 已安装 → 直接通过 XPC 调用

**替代方案**: 应用启动时自动安装
- ❌ 拒绝：过于激进，用户可能不需要这个功能

### 4. 向后兼容策略

**决策**: 降级模式

```objc
// AppDelegate.m
- (void)toggleTurboBoost {
    if ([self isHelperInstalled]) {
        // 使用 XPC 调用
        [self.xpcClient loadKextWithCompletion:^(BOOL success) {
            // ...
        }];
    } else {
        // 回退到原有授权流程
        [self refreshAuthRef];
        [SystemCommands loadModuleWithAuthRef:self.authorizationRef];
    }
}
```

### 5. XPC API 设计

**路由定义**:

```swift
// 共享文件
let loadKextRoute = XPCRoute.named("kext", "load")
    .withMessageType(KextLoadRequest.self)
    .withReplyType(KextLoadResponse.self)

let unloadKextRoute = XPCRoute.named("kext", "unload")
    .withMessageType(KextUnloadRequest.self)
    .withReplyType(KextUnloadResponse.self)

let readSMCRoute = XPCRoute.named("smc", "read")
    .withMessageType(SMCReadRequest.self)
    .withReplyType(SMCReadResponse.self)

let getStatusRoute = XPCRoute.named("status", "get")
    .withMessageType(EmptyRequest.self)
    .withReplyType(StatusResponse.self)
```

## Risks / Trade-offs

### Risk 1: 代码签名复杂性

**风险**: SMJobBless 要求严格的代码签名配置，配置错误会导致安装失败。

**缓解措施**:
- 使用 Blessed 库，它提供详细的错误诊断
- 在构建脚本中自动化代码签名配置
- 提供清晰的开发者文档

### Risk 2: Helper Tool 更新

**风险**: 当 Helper Tool 需要更新时，用户需要重新授权。

**缓解措施**:
- 使用版本号检查，只在必要时提示更新
- 保持 Helper Tool 接口稳定，减少更新频率
- 在应用更新说明中提前告知用户

### Risk 3: macOS 安全策略变化

**风险**: Apple 可能收紧对特权 Helper Tool 的限制。

**缓解措施**:
- 遵循 Apple 官方指南
- 关注 macOS 13+ 的 SMAppService API 作为备选方案
- 保持代码灵活性，便于适配新政策

### Risk 4: 用户卸载 Helper

**风险**: 用户可能手动删除 Helper Tool 文件。

**缓解措施**:
- 每次调用前检查 Helper 状态
- 自动重新安装（需要再次授权）
- 在 UI 中显示 Helper 状态

## Migration Plan

### 阶段 1: 开发与测试

1. 创建 Helper Tool target
2. 集成 SecureXPC 和 Blessed
3. 实现 XPC 服务端和客户端
4. 本地测试（开发签名）

### 阶段 2: 代码签名配置

1. 获取 Developer ID Application 证书
2. 配置 Info.plist 中的 SMPrivilegedExecutables
3. 配置 Helper Tool 的代码签名要求
4. 测试安装流程

### 阶段 3: 发布

1. 构建 Release 版本
2. 公证（Notarization）
3. 打包 DMG
4. 发布更新

### 回滚策略

如果 Helper 安装失败或工作不正常：
1. 自动降级到原有授权流程
2. 记录错误日志
3. 在 UI 中显示警告信息
4. 用户可以手动禁用 Helper 功能

## Open Questions

1. **是否需要支持 macOS 13+ 的 SMAppService?**
   - SMAppService 更简单，但不支持旧系统
   - 建议：先实现 SMJobBless，后续可添加 SMAppService 分支

2. **Helper Tool 是否需要实现自动更新?**
   - 当前设计：版本检查 + 用户确认
   - 后续可以考虑 Sparkle 等自动更新框架

3. **是否需要在沙盒环境中运行?**
   - 当前项目未启用沙盒
   - 如果未来需要上架 App Store，需要重新设计