## Why

Turbo Boost Switcher 是一个功能丰富的 macOS 状态栏应用，但经过多年迭代积累了大量辅助功能，导致代码复杂度高、维护成本大。本项目 fork 自 [rugarciap/Turbo-Boost-Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher)，目标是创建一个精简、现代化的版本，专注于核心功能。

**问题**：
- 代码库包含 15+ 个窗口控制器和辅助功能模块，大部分用户不需要
- 本地化支持 11 种语言，维护成本高
- UI 基于 AppKit + XIB，与现代 SwiftUI 开发模式脱节
- 最低支持 macOS 10.13，限制了现代 API 的使用

**机会**：通过精简和现代化，创造一个更易维护、用户体验更好的精简版本。

## What Changes

### 功能精简

- **移除热键功能** — 删除 HotKeysWindowController 及相关代码
- **移除更新检查** — 删除 CheckUpdatesHelper 和 CheckUpdatesWindowController
- **移除 Help 窗口** — 简单应用不需要独立帮助文档
- **移除 Pro 提示** — 删除运行次数计数和 Pro 推广弹窗
- **简化图表** — 保留温度/CPU负载/CPU频率，移除风扇转速图表
- **简化状态栏菜单** — 移除菜单中的传感器实时显示（温度/风扇/负载/电池），用户通过图表查看
- **简化本地化** — 仅保留英文和简体中文，使用系统语言自动匹配，移除语言切换菜单

### 保留的核心功能

- **Turbo Boost 开关** — 核心功能，完整保留
- **Privileged Helper** — 避免每次操作输入密码，保留
- **图表窗口** — 保留温度/CPU负载/CPU频率历史曲线
- **开机设置** — Open at Login 和 Disable TB at Launch
- **About 窗口** — 优化内容，致敬原作者，推荐 Pro 版本

### 技术现代化

- **BREAKING** — 最低版本从 macOS 10.13 升级到 macOS 10.15 (Catalina)
- **SwiftUI 迁移** — About 窗口使用 SwiftUI 重写
- **清理遗留代码** — 移除已弃用的 ChartView (Objective-C)、ChartDataEntry 等文件

## Capabilities

### New Capabilities

- `about-window`: 重新设计的 About 窗口，使用 SwiftUI 实现，包含原作者致敬和 Pro 版本推荐

### Modified Capabilities

- `chart-visualization`: 图表功能精简，移除风扇转速图表，保留温度/CPU负载/CPU频率
- `helper-integration`: 无变化，完整保留现有 Helper Tool 架构

### Removed Capabilities

- `hotkeys`: 全局热键配置功能
- `update-check`: 自动更新检查功能
- `help-window`: 独立帮助窗口
- `sensor-menu-display`: 状态栏菜单中的传感器实时显示
- `language-menu`: 语言切换菜单（改为系统语言自动匹配）

## Impact

### 文件删除

```
Turbo Boost Disabler/
├── HotKeysWindowController.h/.m/.xib      # 热键配置
├── HelpWindowController.h/.m/.xib         # 帮助窗口
├── CheckUpdatesWindowController.h/.m/.xib # 更新检查
├── CheckUpdatesHelper.h/.m                # 更新辅助
├── ChartView.h/.m                         # 遗留图表实现
├── ChartDataEntry.h/.m                    # 遗留数据模型
├── ChartDataDelegate.h                    # 遗留代理协议
└── *.lproj/ (部分)                        # 移除非 en/zh-Hans 本地化

根目录孤立文件 (已不使用):
├── AppDelegate.m/.h
├── StartupHelper.m/.h
├── SystemCommands.m/.h
├── AboutWindowController.m/.h
└── AboutWindowController.xib
```

### 文件修改

```
Turbo Boost Disabler/
├── AppDelegate.m           # 移除传感器菜单显示、热键、更新检查、语言菜单
├── AppDelegate.h           # 移除相关 IBOutlet 和属性
├── StartupHelper.m/.h      # 移除热键、更新检查相关偏好设置
├── ChartViews.swift        # 移除风扇转速图表
└── MainMenu.xib            # 简化菜单结构

openspec/specs/
├── chart-visualization/    # 更新规格，移除风扇转速
└── (新增) about-window/    # About 窗口规格
```

### API 影响

- 无公共 API 变更（应用无 SDK/框架）
- 偏好设置键值变更：
  - 移除: `isHotKeysEnabled`, `turboBoostHotKeys`, `chartHotKey`
  - 移除: `isCheckUpdatesOnStart`, `neverShowProMessage`, `runCount`
  - 移除: `currentLocale` (改为自动检测)

### 依赖影响

- Swift Package 依赖保持不变: SecureXPC, Blessed
- macOS 最低版本: 10.13 → 10.15

### 用户影响

- 现有用户的偏好设置中热键配置将丢失（功能已移除）
- 传感器实时显示从菜单移至图表窗口
- 非英文/中文用户将看到英文界面
- macOS 10.13/10.14 用户将无法使用新版本
