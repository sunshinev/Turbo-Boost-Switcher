## Context

### 当前状态

XPC 通信架构：

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              GUI App (用户进程)                           │
├─────────────────────────────────────────────────────────────────────────┤
│  XPCClientWrapper.m                                                      │
│  - 连接到 mach service: com.sunshinev.TurboBoostSwitcher.helper          │
│  - 使用协议: HelperToolProtocol                                          │
│  - 调用方法: loadKextAtPath:use32Bit:completion: 等                      │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ NSXPCConnection
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Helper Tool (root 权限)                        │
├─────────────────────────────────────────────────────────────────────────┤
│  main.swift: HelperXPCDelegate                                          │
│  - 协议: ObjCHelperToolProtocol                                         │
│  - 实际方法: loadKext(atPath:withReply:) 等                              │
│  - ObjC 选择器: loadKextAtWithPathReply: 等                              │
└─────────────────────────────────────────────────────────────────────────┘
```

### 问题根因

Swift 方法映射到 Objective-C 选择器时：
- `func loadKext(atPath:withReply:)` → 选择器 `loadKextAtWithPathReply:`
- 但客户端期望 `loadKextAtPath:use32Bit:completion:`

两者不匹配，XPC 消息无法被路由到正确的方法。

### 约束

- 必须保持客户端代码不变（`XPCClientWrapper.h` 协议定义）
- 只修改 Helper Tool 端的 Swift 代码
- 修复后需要重新编译并重新安装 Helper Tool

## Goals / Non-Goals

**Goals:**
- 修复 XPC 方法选择器映射，使 GUI App 能正确调用 Helper Tool
- 添加 SMC 连接错误检查，提高诊断能力
- 保持向后兼容，不改变 API 行为

**Non-Goals:**
- 不修改客户端代码 (`XPCClientWrapper.m/.h`)
- 不修改 XPCRoutes.swift（当前未使用）
- 不重构 KextManager 或 SMCManager 的实现逻辑

## Decisions

### 决策 1: 使用 @objc 选择器映射

**选择**: 在 Swift 方法上添加 `@objc(name:)` 属性显式指定 ObjC 选择器名称

**理由**:
- 最小改动，只需修改 4 个方法声明
- 保持 Swift 方法命名风格（符合 Swift 惯例）
- 不影响现有代码逻辑

**替代方案**: 修改客户端协议定义
- 需要同时修改 `.h` 和 `.m` 文件
- 需要修改回调 block 的调用方式
- 改动更大，风险更高

### 决策 2: 添加 SMC 错误日志

**选择**: 在 `openSMCConnection()` 中添加 `print()` 日志

**理由**:
- 帮助诊断 Apple Silicon Mac 兼容性问题
- 最小改动，不影响功能
- 日志可通过 Console.app 查看

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| Helper Tool 需要重新安装 | 用户需要卸载旧 Helper 并安装新版本 |
| @objc 映射可能与其他框架冲突 | 使用完整的选择器名称，避免歧义 |
| SMC 连接失败但没有 fallback | 暂不处理，保持现有行为；未来可考虑替代 API |

## Migration Plan

### 部署步骤

1. 编译新版本的 Helper Tool
2. 用户运行新版本 GUI App
3. GUI App 检测 Helper 版本不匹配
4. 提示用户重新安装 Helper Tool
5. 使用 SMJobBless 重新安装

### 回滚策略

如果修复失败：
1. 用户可通过菜单卸载 Helper Tool
2. 降级到使用 AuthorizationRef 的原有流程（TurboBoostManager 的降级模式）