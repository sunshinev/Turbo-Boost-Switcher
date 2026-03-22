## Why

状态栏弹出菜单中仍保留了一些已废弃功能的菜单项和置灰的选项，这些功能在代码中已被移除或禁用，但菜单定义（XIB 文件）和相关代码仍存在。这会导致用户困惑，并增加维护负担。

## What Changes

从状态栏菜单中移除以下废弃/未使用的菜单项和功能：

1. **移除 Charts 菜单项** - 图表功能已移除，菜单项仍存在于 XIB
2. **移除 Check Updates 菜单项** - 更新检查功能已移除
3. **移除 Help 菜单项** - 帮助窗口已移除
4. **精简 Language 子菜单** - 从 10 种语言减少到仅保留 English + 简体中文（系统语言自动匹配）
5. **移除 sensorsView 传感器显示视图** - 菜单中显示 CPU/风扇/温度的视图已废弃
6. **清理相关代码** - 移除图表更新、传感器读取等相关死代码

## Capabilities

### New Capabilities
无需新增功能。

### Modified Capabilities
无需修改现有功能规格。

## Impact

- **文件修改**:
  - `en.lproj/MainMenu.xib` / `Turbo Boost Disabler/en.lproj/MainMenu.xib` - 移除菜单项定义
  - `AppDelegate.h` / `Turbo Boost Disabler/AppDelegate.h` - 移除废弃的 IBOutlet 声明
  - `AppDelegate.m` / `Turbo Boost Disabler/AppDelegate.m` - 移除图表更新相关代码
  - `zh-Hans.lproj/Localizable.strings` - 清理废弃的本地化字符串

- **功能影响**:
  - 用户将不再看到无用的图表、帮助、更新检查等菜单项
  - 菜单更简洁，只保留核心功能（启用/禁用 Turbo Boost、设置、关于、退出）