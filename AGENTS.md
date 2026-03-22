# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-22
**Commit:** 精简版
**Branch:** master

## OVERVIEW
macOS status bar app to enable/disable Intel Turbo Boost via kernel extensions. 
**精简版**: 纯 Objective-C (主应用) + Swift (Helper Tool + 图表). GPL v2 licensed.

Fork 自 [rugarciap/Turbo-Boost-Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher)

## STRUCTURE
```
.
├── Turbo Boost Disabler/    # 主应用源代码
│   ├── AppDelegate.m/.h      # 主控制器
│   ├── SystemCommands.m/.h   # Kext 管理, SMC 访问
│   ├── StartupHelper.m/.h    # 偏好设置
│   ├── TurboBoostManager.*   # 统一管理器
│   ├── ChartWindowController.* # 图表窗口
│   ├── ChartViews.swift      # SwiftUI 图表
│   ├── AboutWindowController.* # 关于窗口
│   └── *.xib                 # Interface Builder
├── HelperTool/              # Privileged Helper (root 权限)
├── Shared/XPC/              # XPC 路由定义
├── en.lproj/                # 英文本地化
├── zh-Hans.lproj/           # 简体中文本地化
└── Turbo Boost Switcher.xcodeproj
```

## 已移除的功能

| 功能 | 状态 |
|------|------|
| 热键配置 | ❌ 已移除 |
| 更新检查 | ❌ 已移除 |
| Help 窗口 | ❌ 已移除 |
| Pro 提示 | ❌ 已移除 |
| 风扇转速图表 | ❌ 已移除 |
| 菜单传感器显示 | ❌ 已移除 |
| 语言切换菜单 | ❌ 已移除 (使用系统语言) |
| 其他 9 种语言 | ❌ 仅保留 en + zh-Hans |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| 应用生命周期, 状态栏 UI | `Turbo Boost Disabler/AppDelegate.m` |
| Kext 加载/卸载, SMC 访问 | `Turbo Boost Disabler/SystemCommands.m` |
| CPU 温度读取 | `Turbo Boost Disabler/smc.h`, `SystemCommands.m` |
| 偏好设置持久化 | `Turbo Boost Disabler/StartupHelper.m` |
| 图表 UI | `Turbo Boost Disabler/ChartViews.swift` |
| 本地化字符串 | `en.lproj/Localizable.strings`, `zh-Hans.lproj/Localizable.strings` |
| Helper 安装管理 | `Turbo Boost Disabler/HelperInstallationManager.m` |
| XPC 客户端 | `Turbo Boost Disabler/XPCClientWrapper.m` |
| Turbo Boost 统一管理 | `Turbo Boost Disabler/TurboBoostManager.m` |
| Helper Tool 入口 | `HelperTool/main.swift` |
| Kext 管理器 | `HelperTool/KextManager.swift` |
| SMC 管理器 | `HelperTool/SMCManager.swift` |

## ARCHITECTURE

### Entry Points
- `main.m` → `NSApplicationMain()` → 加载 `MainMenu.xib`
- `AppDelegate` 作为 `NSApplication.delegate`
- `awakeFromNib` 初始化状态栏、定时器、偏好设置

### Core Components

| Class | Role |
|-------|------|
| `AppDelegate` | 主控制器: 状态栏, Turbo Boost 切换 |
| `SystemCommands` | 内核扩展管理, SMC 硬件访问 |
| `StartupHelper` | UserDefaults 持久化 |
| `TurboBoostManager` | 统一管理器: Helper/XPC/降级逻辑 |
| `XPCClientWrapper` | XPC 客户端封装 |

### Data Flow

```
用户点击 → TurboBoostManager → [Helper 可用?]
                                    │
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
              [使用 Helper]                   [降级模式]
                    │                               │
                    ↓                               ↓
            XPCClientWrapper                 AuthorizationRef
                    │
                    ↓
            Helper Tool (root)
                    │
        ┌───────────┼───────────┐
        ↓           ↓           ↓
   KextManager  SMCManager  状态查询
```

## CONVENTIONS

### Documentation Language
**所有生成的 Markdown 文档必须使用中文描述。**

### Naming
- Window controllers: `*WindowController.h/.m/.xib`
- Helpers: `*Helper.h/.m`
- Managers: `*Manager.swift` (Helper Tool)
- IB outlets: `IBOutlet` prefix
- Actions: `IBAction` return type

### Localization
- 仅支持英文和简体中文
- 使用系统语言自动匹配
- Keys in `Localizable.strings`

## COMMANDS

### Build (Xcode)
```bash
# CLI build
xcodebuild -project "Turbo Boost Switcher.xcodeproj" \
  -scheme "Turbo Boost Switcher" \
  -configuration Release
```

### Run
```bash
# As root (avoids password prompts)
sudo "/Applications/Turbo Boost Switcher.app/Contents/MacOS/Turbo Boost Switcher"
```

## NOTES

- **Deployment target**: macOS 10.15+
- **Hardened runtime**: Disabled
- **Code signing**: 需要 Developer ID Application 证书
- **Swift Package 依赖**: SecureXPC, Blessed

## SEE ALSO

- [DEVELOPER.md](DEVELOPER.md) — 开发者指南
- 原项目: https://github.com/rugarciap/Turbo-Boost-Switcher
- Pro 版本推荐: https://gumroad.com/l/YeBQUF