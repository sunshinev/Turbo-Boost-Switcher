## Why

当前图表功能存在两个主要问题：

1. **CPU频率显示单位错误**：Helper Tool 返回的频率值为 MHz（如 2900.01），但图表配置期望 GHz，导致数值显示为 "2000.0 Ghz" 而纵轴刻度仅为 1.0、2.0，维度完全错位。

2. **显示文本拼写错误**："Ghz" 应为 "GHz"。

## What Changes

### 问题修复
- **修复 CPU 频率单位不一致**：统一 Helper Tool 返回的频率单位为 GHz
- **修正显示文本**：修复 "Ghz" 拼写错误（应为 "GHz"）

### UI 优化（推迟）
- **SwiftUI Charts 集成**：由于项目未配置 Swift 支持和模块启用，完整的 SwiftUI 集成需要在 Xcode 中手动配置。当前仅实现频率单位修复。

## Capabilities

### New Capabilities

- `chart-visualization`: 图表可视化能力，修复了 CPU 频率单位显示问题

### Modified Capabilities

- 无（现有功能行为不变，仅修复显示问题）

## Impact

### 受影响的代码

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `HelperTool/SMCManager.swift` | 修改 | `readFrequency()` 返回 GHz 而非 MHz |
| `Turbo Boost Disabler/AppDelegate.m` | 修改 | 修复显示文本 "Ghz" → "GHz" |

### 风险评估

- **低风险**：频率单位修复影响范围小，逻辑简单，已验证构建成功