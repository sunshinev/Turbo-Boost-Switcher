## Why

Turbo Boost Switcher 应用在启用 Privileged Helper (XPC) 模式后出现两个关键问题：
1. **UI 状态不更新**：用户切换 Turbo Boost 状态后，状态栏菜单和图标没有正确反映当前状态
2. **传感器数据缺失**：图表窗口只显示 CPU 负载，温度和风扇转速显示为 "N/A"

这些问题影响用户体验，需要修复以确保 Helper 模式下的功能完整性。

## What Changes

- **修复 UI 状态同步问题**：修改 `AppDelegate.updateStatus` 方法，使其使用 `TurboBoostManager` 的状态属性而非直接查询 kext 状态
- **修复传感器数据读取**：诊断并修复 SMC 传感器读取失败的问题，确保温度、风扇数据正确显示
- **增强错误日志**：添加详细的日志记录，帮助诊断 XPC 调用和 SMC 读取的问题
- **验证 SMC 键兼容性**：检查不同 Mac 型号使用的 SMC 键名，确保兼容性

## Capabilities

### New Capabilities
- `ui-state-sync`: 确保 Turbo Boost 状态切换后 UI 正确更新的能力
- `sensor-data-read`: 通过 Helper (XPC) 正确读取 SMC 传感器数据的能力

### Modified Capabilities
- 无现有 spec 需要修改

## Impact

- **受影响文件**：
  - `Turbo Boost Disabler/AppDelegate.m` - 状态更新逻辑
  - `Turbo Boost Disabler/TurboBoostManager.m` - 状态管理
  - `HelperTool/SMCManager.swift` - SMC 读取实现
  - `Turbo Boost Disabler/XPCClientWrapper.m` - XPC 客户端

- **无 API 变更**：纯内部修复，不影响外部接口
- **向后兼容**：修复后 Helper 模式和降级模式都能正常工作
