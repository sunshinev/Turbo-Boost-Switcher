## Context

Turbo Boost Switcher 应用实现了 Privileged Helper 架构，通过 XPC 通信让 Helper Tool (以 root 权限运行) 来加载/卸载内核扩展和读取 SMC 传感器数据。

当前存在两个问题：

### 问题 1: UI 状态不同步

在 `AppDelegate.m` 的 `updateStatus` 方法中，直接调用 `SystemCommands isModuleLoaded` 来查询 kext 状态：

```objc
- (void) updateStatus {
    isTurboBoostEnabled= ![SystemCommands isModuleLoaded];  // 直接查询
    // ... 更新 UI
}
```

但当使用 Helper (XPC) 模式时：
- `TurboBoostManager` 通过 XPC 异步加载/卸载 kext
- `TurboBoostManager.isTurboBoostEnabled` 被正确更新
- 但 `updateStatus` 绕过了它，直接查询 `SystemCommands`
- 由于 XPC 操作的异步性，状态可能还没同步

### 问题 2: 传感器数据缺失

图表窗口只显示 CPU 负载，温度和风扇显示 "N/A"。

`TurboBoostManager` 使用 XPC 读取 SMC 键 `TC0D` (温度) 和 `F0Ac` (风扇)，但：
- 这些 SMC 键可能在某些 Mac 型号上不存在
- Helper 的 SMC 读取实现可能有问题
- 错误没有被正确处理和记录

## Goals / Non-Goals

**Goals:**
- 修复 `updateStatus` 方法，使其使用 `TurboBoostManager` 的状态属性
- 诊断并修复 SMC 传感器读取失败的问题
- 添加详细的日志记录，便于调试
- 确保 Helper 模式和降级模式都能正常工作

**Non-Goals:**
- 不修改 XPC 协议或 Helper 架构
- 不添加新的传感器类型
- 不改变 UI 设计或布局

## Decisions

### 决策 1: 统一状态来源

**选择**: `updateStatus` 方法应该使用 `TurboBoostManager.isTurboBoostEnabled` 而非直接查询 kext

**理由**: 
- `TurboBoostManager` 是状态管理的单一来源 (Single Source of Truth)
- 它在完成 XPC 操作后会正确更新状态
- 降级模式下也会正确设置状态

**替代方案**: 保持现状 — 拒绝，因为会导致状态不同步

### 决策 2: 添加 SMC 读取日志

**选择**: 在 SMC 读取失败时添加详细的 NSLog 输出

**理由**:
- 便于诊断是哪个 SMC 键读取失败
- 了解失败原因 (权限、键不存在、通信错误等)
- 不影响性能，只在失败时输出

### 决策 3: 检查多个 SMC 温度键

**选择**: 尝试多个温度 SMC 键 (TC0D, TCAH, TC0F, TC0H)，使用第一个成功的

**理由**:
- 不同 Mac 型号使用不同的温度传感器键
- 提高兼容性，不依赖单一键名

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| SMC 键在不同 Mac 型号上差异很大 | 尝试多个已知键，添加日志记录失败的键 |
| Helper 进程可能无响应 | XPC 调用添加超时处理，失败时回退到降级模式 |
| 状态更新时序问题 | 确保所有状态变更都通过 TurboBoostManager，回调中更新 UI |

## Migration Plan

无需迁移，这是纯修复性变更，不影响用户数据或配置。

## Open Questions

1. 当前 Mac 型号支持哪些 SMC 键？需要测试验证
2. Helper 的 SMC 读取是否有权限问题？需要检查错误码
