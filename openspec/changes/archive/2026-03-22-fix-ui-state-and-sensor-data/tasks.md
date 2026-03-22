## 1. 修复 UI 状态同步问题

- [x] 1.1 修改 `AppDelegate.m` 的 `updateStatus` 方法，使用 `TurboBoostManager.isTurboBoostEnabled` 替代直接查询 kext 状态
- [x] 1.2 验证状态切换后 UI 正确更新（状态栏图标、菜单文本）
- [x] 1.3 测试唤醒后状态恢复场景

## 2. 诊断和修复传感器数据读取

- [x] 2.1 在 `TurboBoostManager.m` 的 `readSensorsWithCompletion` 中添加详细日志，记录 XPC 调用结果
- [x] 2.2 在 `HelperTool/SMCManager.swift` 中添加 SMC 读取失败的详细日志
- [x] 2.3 修改 `TurboBoostManager` 尝试多个温度 SMC 键 (TC0D, TCAH, TC0F, TC0H)
- [x] 2.4 修改 `TurboBoostManager` 尝试多个风扇 SMC 键 (F0Ac, F1Ac)
- [x] 2.5 验证传感器数据正确显示在图表中

## 3. 测试和验证

- [x] 3.1 测试 Helper 模式下的状态切换和传感器读取
- [x] 3.2 测试降级模式下的状态切换和传感器读取（确保向后兼容）
- [x] 3.3 检查日志输出，确认错误信息清晰有用
- [x] 3.4 运行构建验证无编译错误
