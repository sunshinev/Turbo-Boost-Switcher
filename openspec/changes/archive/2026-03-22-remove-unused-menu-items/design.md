## Context

### 当前状态
- 状态栏菜单（statusMenu）在 `MainMenu.xib` 中定义，包含以下废弃项目：
  - Charts 菜单项（id="Q6V-Qs-wVa"）- 图表窗口已移除
  - Check Updates 菜单项（id="564"）- 更新检查功能已移除
  - Help 菜单项 - 帮助窗口已移除
  - Language 子菜单 - 包含 10 种语言选项，但只支持 en + zh-Hans
  - sensorsView（id="YNw-n5-v8Y"）- 传感器显示视图已废弃
  - 设置视图中的 Monitoring 控件 - 监控功能部分保留但部分废弃

### 约束
- 需要保持核心功能：启用/禁用 Turbo Boost、设置、关于、退出
- 保持双语支持（en + zh-Hans）
- 不破坏现有构建

## Goals / Non-Goals

**Goals:**
- 移除 Charts、Check Updates、Help 菜单项
- 精简 Language 子菜单为仅 English + 简体中文
- 移除 sensorsView 传感器显示视图
- 清理相关的死代码和 IBOutlet 声明

**Non-Goals:**
- 不移除核心的 Turbo Boost 切换功能
- 不修改 About 窗口
- 不修改 Quit 退出功能
- 不修改 Open at Login、Disable at Launch 等设置

## Decisions

### 1. XIB 菜单项移除方案
- **方案**: 直接从 MainMenu.xib 中删除对应的 `<menuItem>` 元素
- **理由**: XIB 是 Interface Builder 的 XML 格式，可直接编辑
- **影响文件**: 
  - `Turbo Boost Disabler/en.lproj/MainMenu.xib`
  - `en.lproj/MainMenu.xib`（如有需要）

### 2. IBOutlet 清理方案
- **方案**: 从 AppDelegate.h 中删除废弃的 IBOutlet 声明
- **理由**: 避免引用不存在的元素
- **需要移除的声明**:
  - `chartsMenuItem`
  - `checkUpdatesItem`
  - `languageMenu`
  - `englishMenu` ~ `italianMenu`（所有语言菜单项）
  - `txtCpuLoad`, `txtCpuFan`, `txtCpuTemp`
  - `temperatureImage`, `cpuLoadImage`, `cpuFanImage`, `batteryImage`
  - `sensorsView`
  - `batteryLevelIndicator`, `lblBatteryInfo`

### 3. 代码清理方案
- **方案**: 从 AppDelegate.m 中删除相关的死代码
- **需要移除的代码**:
  - `updateSensorUIWithTemperature:fanSpeed:` 方法（图表数据更新）
  - `updateCPULoad` 方法（CPU 负载更新）
  - `chartsMenuClick:` 和 `openChartWindow` 方法
  - 图表相关的 sample 方法和结构体
  - 传感器相关的 Outlet 属性设置代码

## Risks / Trade-offs

**[风险] 破坏 XIB 文件结构**
→  mitigation: 使用精确的 XML 编辑，只删除完整的 `<menuItem>` 元素

**[风险] 残留代码引用导致崩溃**
→  mitigation: 清理所有相关的 IBOutlet 和方法调用