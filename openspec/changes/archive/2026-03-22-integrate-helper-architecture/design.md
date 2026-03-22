## Context

### 当前架构问题

```
┌─────────────────────────────────────────────────────────────────────┐
│                    当前 AppDelegate.m 授权流程                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐                                                   │
│  │  用户点击     │                                                   │
│  │  或定时器触发  │                                                   │
│  └──────┬───────┘                                                   │
│         │                                                           │
│         ▼                                                           │
│  ┌──────────────────┐                                               │
│  │ refreshAuthRef() │  ← 每次都调用                                  │
│  └──────┬───────────┘                                               │
│         │                                                           │
│         ▼                                                           │
│  ┌──────────────────────────────────────────┐                       │
│  │ AuthorizationCopyRights()                │                       │
│  │ kAuthorizationFlagInteractionAllowed     │  ← 弹密码！           │
│  └──────────────────────────────────────────┘                       │
│                                                                     │
│  触发点:                                                             │
│  - receiveWakeNote: (系统唤醒时自动触发)                              │
│  - disableTurboBoost / enableTurboBoost                             │
│  - readCpuFrequency (图表窗口定时器每4秒调用)                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 已有但未使用的 Helper 架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                    已实现的 Helper 组件（未被使用）                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  TurboBoostManager.m  ← 统一管理器，已有 Helper/XPC/降级逻辑         │
│  XPCClientWrapper.m   ← XPC 客户端封装                              │
│  HelperInstallationManager.m  ← Helper 安装/状态检测                │
│  HelperTool/main.swift  ← XPC 服务端 (root)                         │
│  KextManager.swift  ← 有 bug: 使用了不必要的 sudo                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Goals / Non-Goals

**Goals:**
1. 将 `AppDelegate.m` 中所有需要授权的操作重构为使用 `TurboBoostManager`
2. 当 Helper 可用时，完全消除密码弹窗
3. 修复 `KextManager.swift` 中不必要的 `sudo` 调用
4. 保持降级模式：Helper 不可用时回退到原有授权方式

**Non-Goals:**
- 不修改 Helper 的安装流程（SMJobBless 已实现）
- 不添加新的功能特性
- 不重构其他与本次问题无关的代码（如语言菜单）

## Decisions

### 决策 1: AppDelegate 直接依赖 TurboBoostManager

**选择:** AppDelegate 直接调用 `TurboBoostManager` 的单例方法

**理由:**
- `TurboBoostManager` 已实现了完整的 Helper/XPC/降级逻辑
- 无需引入额外的抽象层
- 保持与现有架构一致（单例模式）

**替代方案:**
- 引入新的 Service 层 → 过度设计，增加复杂度
- 保留现有 AuthorizationRef 逻辑并添加条件判断 → 代码重复，难以维护

### 决策 2: 修改 TurboBoostManager 为同步 API（可选）

**选择:** 保持异步 API，AppDelegate 使用 completion block

**理由:**
- XPC 调用本身是异步的
- 保持 API 一致性
- 避免阻塞主线程

**实现方式:**
```objc
// AppDelegate.m
- (void)disableTurboBoost {
    [[TurboBoostManager sharedManager] disableTurboBoostWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus];
        });
    }];
}
```

### 决策 3: 修复 KextManager.swift 的 sudo 问题

**问题:** Helper 已以 root 运行，但代码中仍调用 `sudo kextload`

**修复:** 移除 `sudo`，直接调用 `kextload` / `kextunload`

```swift
// 修复前
task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
task.arguments = ["kextload", "-v", kextPath]

// 修复后
task.executableURL = URL(fileURLWithPath: "/sbin/kextload")
task.arguments = ["-v", kextPath]
```

### 决策 4: CPU 频率读取通过 Helper

**选择:** 将 `readCpuFrequency` 改为通过 Helper 的 `SMCManager` 读取

**理由:**
- `powermetrics` 需要 root 权限
- 通过 XPC 调用 Helper 可免密码

**实现方式:**
- 在 `XPCRoutes.swift` 中添加 `readFrequency` 路由
- `SMCManager.swift` 中已有 `readFrequency()` 方法

## Risks / Trade-offs

### 风险 1: Helper 未安装时的用户体验

**风险:** 用户首次使用仍需输入密码安装 Helper

**缓解:** 
- 这是 macOS 安全机制的预期行为
- 一次性安装后，后续无需密码
- 可在 UI 中提示用户

### 风险 2: XPC 连接失败

**风险:** Helper 崩溃或 XPC 连接断开

**缓解:** 
- `TurboBoostManager` 已有降级逻辑
- `XPCClientWrapper` 的 `interruptionHandler` 会重置连接状态
- 下次操作时自动降级到 AuthorizationRef

### 风险 3: 异步 API 导致状态不同步

**风险:** 用户快速连续点击可能导致状态不一致

**缓解:**
- 在操作期间禁用 UI 交互
- 使用 `isTurboBoostEnabled` 状态追踪

## Migration Plan

### 阶段 1: 修复 Helper Tool（可独立测试）

1. 修复 `KextManager.swift` 的 sudo 调用
2. 验证 Helper 可独立加载/卸载 kext

### 阶段 2: 集成 AppDelegate

1. 导入 `TurboBoostManager.h` 到 `AppDelegate.m`
2. 重构 `disableTurboBoost` / `enableTurboBoost`
3. 重构 `receiveWakeNote:` 的 kext 重载逻辑
4. 重构 `readCpuFrequency`

### 阶段 3: 测试验证

1. 测试 Helper 已安装场景（无密码）
2. 测试 Helper 未安装场景（降级到密码）
3. 测试系统唤醒后的行为
4. 测试图表窗口的 CPU 频率读取