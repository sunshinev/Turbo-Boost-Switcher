## 1. 单位修复

- [x] 1.1 修改 `HelperTool/SMCManager.swift` 的 `readFrequency()` 方法，将 MHz 转换为 GHz（除以 1000）
- [x] 1.2 修改 `Turbo Boost Disabler/AppDelegate.m` 中的显示文本，将 "Ghz" 改为 "GHz"
- [x] 1.3 验证 `SystemCommands.m` 的 `readCurrentCpuFreqWithAuthRef:` 已返回 GHz（无需修改）
- [x] 1.4 构建成功，项目可编译
- [ ] 1.5 手动测试频率显示是否正确

## 2. SwiftUI Charts 集成（已取消）

**说明**: SwiftUI Charts 需要项目配置 Swift 支持和模块启用，当前项目未配置这些设置。完整的 Swift 集成需要在 Xcode 中手动配置以下内容：

- [ ] 2.1 在 Build Settings 中启用 `CLANG_ENABLE_MODULES = YES`
- [ ] 2.2 设置 `SWIFT_VERSION = 5`
- [ ] 2.3 配置 `SWIFT_OBJC_BRIDGING_HEADER`
- [ ] 2.4 添加 Swift 文件到项目

**当前状态**: 已恢复原有 Objective-C ChartView 实现，仅保留频率单位修复。

## 3. 构建验证

- [x] 3.1 项目编译成功（`BUILD SUCCEEDED`）
- [ ] 3.2 手动运行应用测试图表功能
- [ ] 3.3 验证 CPU 频率显示单位正确（GHz）

## 文件变更摘要

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `HelperTool/SMCManager.swift` | 修改 | 频率返回值从 MHz 改为 GHz |
| `Turbo Boost Disabler/AppDelegate.m` | 修改 | 显示文本 "Ghz" → "GHz" |