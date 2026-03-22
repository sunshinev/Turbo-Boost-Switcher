# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-22
**Commit:** 454c189
**Branch:** master

## OVERVIEW
macOS status bar app to enable/disable Intel Turbo Boost via kernel extensions. Pure Objective-C (主应用) + Swift (Helper Tool). GPL v2 licensed.

## STRUCTURE
```
.
├── Turbo Boost Disabler/    # 主应用源代码 — 所有 UI 和业务逻辑
├── HelperTool/              # Privileged Helper — 以 root 权限运行
├── Shared/XPC/              # 共享代码 — XPC 路由定义
├── *.lproj/                  # 本地化 (11 种语言)
├── *.m, *.h                  # 孤立文件 — 不要编辑 (重复)
└── Turbo Boost Switcher.xcodeproj
```

## CRITICAL: Duplicate Files Warning

**根目录的 .m/.h 文件是孤立的** — Xcode 只从 `Turbo Boost Disabler/` 构建。

| Root File | Status | Actual Source |
|-----------|--------|---------------|
| `AppDelegate.m` | ❌ 较旧 (31KB) | `Turbo Boost Disabler/AppDelegate.m` (44KB) |
| `StartupHelper.m` | ❌ 较旧 (7KB) | `Turbo Boost Disabler/StartupHelper.m` (10KB) |
| `SystemCommands.m` | ❌ 重复 | `Turbo Boost Disabler/SystemCommands.m` |
| `AboutWindowController.m` | ❌ 重复 | `Turbo Boost Disabler/AboutWindowController.m` |

**规则: 始终编辑 `Turbo Boost Disabler/` 子目录中的文件。**

## WHERE TO LOOK

| Task | Location |
|------|----------|
| 应用生命周期, 状态栏 UI | `Turbo Boost Disabler/AppDelegate.m` |
| Kext 加载/卸载, SMC 访问 | `Turbo Boost Disabler/SystemCommands.m` |
| CPU 温度, 风扇转速读取 | `Turbo Boost Disabler/smc.h`, `SystemCommands.m` |
| 偏好设置持久化 | `Turbo Boost Disabler/StartupHelper.m` |
| 更新检查 | `Turbo Boost Disabler/CheckUpdatesHelper.m` |
| 图表 UI | `Turbo Boost Disabler/ChartWindowController.m` |
| 热键 | `Turbo Boost Disabler/HotKeysWindowController.m` |
| 本地化字符串 | `*.lproj/Localizable.strings` |
| **Helper 安装管理** | `Turbo Boost Disabler/HelperInstallationManager.m` |
| **XPC 客户端** | `Turbo Boost Disabler/XPCClientWrapper.m` |
| **Turbo Boost 统一管理** | `Turbo Boost Disabler/TurboBoostManager.m` |
| **Helper 状态 UI** | `Turbo Boost Disabler/HelperStatusMenuController.m` |
| **Helper Tool 入口** | `HelperTool/main.swift` |
| **Kext 管理器** | `HelperTool/KextManager.swift` |
| **SMC 管理器** | `HelperTool/SMCManager.swift` |
| **XPC 路由定义** | `Shared/XPC/XPCRoutes.swift` |

## ARCHITECTURE

### Entry Points
- `main.m` → `NSApplicationMain()` → 加载 `MainMenu.xib`
- `AppDelegate` 作为 `NSApplication.delegate` 在 NIB 中连接
- `awakeFromNib` 初始化状态栏、定时器、偏好设置

### Core Components

| Class | Role |
|-------|------|
| `AppDelegate` | 主控制器: 状态栏, Turbo Boost 切换, 传感器更新 |
| `SystemCommands` | 内核扩展管理, SMC 硬件访问 |
| `StartupHelper` | UserDefaults 持久化, 登录项 |
| `*WindowController` | MVC 窗口 |
| **`TurboBoostManager`** | **统一管理器: Helper/XPC/降级逻辑** |
| **`XPCClientWrapper`** | **XPC 客户端封装** |
| **`HelperInstallationManager`** | **Helper 安装/卸载管理** |

### Data Flow (NEW)

```
用户点击 → TurboBoostManager → [Helper 可用?]
                                    │
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
              [使用 Helper]                   [降级模式]
                    │                               │
                    ↓                               ↓
            XPCClientWrapper                 原有授权流程
                    │                        (AuthorizationRef)
                    ↓
            Helper Tool (root)
                    │
        ┌───────────┼───────────┐
        ↓           ↓           ↓
   KextManager  SMCManager  状态查询
```

### Privileged Helper Architecture

```
┌─────────────────┐                    ┌─────────────────────┐
│   GUI App       │                    │  Helper Tool        │
│   (用户进程)     │                    │  (root 权限)        │
├─────────────────┤                    ├─────────────────────┤
│ XPC Client      │◀────XPC/Mach IPC──▶│ XPC Server          │
│                 │                    │                     │
│ TurboBoostMgr   │                    │ KextManager         │
│                 │                    │ SMCManager          │
└─────────────────┘                    └─────────────────────┘
```

## CONVENTIONS

### Documentation Language
**所有生成的 Markdown 文档必须使用中文描述。** This project requires all generated `.md` files (AGENTS.md, README, design docs, etc.) to be written in Chinese (简体中文). Code comments and technical terms may remain in English where appropriate.

### Header Style
Every file includes GPL v2 license header with author (Rubén García Pérez).

### Naming
- Window controllers: `*WindowController.h/.m/.xib`
- Helpers: `*Helper.h/.m`
- Managers: `*Manager.swift` (Helper Tool)
- IB outlets: `IBOutlet` prefix
- Actions: `IBAction` return type

### Properties
```objc
@property(nonatomic, strong) ClassName *propertyName;
```

### Localization
- 11 languages: en, es, es-ES, fr, de, zh-Hans, pl, ru, sv, cs, it
- Keys in `Localizable.strings` (e.g., `"cpu_temp"`, `"enable_menu"`)

## ANTI-PATTERNS (THIS PROJECT)

### TODO: Language Menu Refactoring
`AppDelegate.m:569-630` — Long if-else chain for language selection. Should use `NSMutableDictionary` lookup.

### TODO: Deprecated Method
`SystemCommands.m:297` — `runProcess:withArguments:output:errorDescription:asAdministrator:` marked for removal.

## UNIQUE STYLES

### Kernel Extension Bundling
Precompiled kexts bundled in app:
- `DisableTurboBoost.32bits.kext`
- `DisableTurboBoost.64bits.kext`

No kext source in repo — binaries only.

### Authorization Flow
Uses `AuthorizationRef` for admin privileges when loading/unloading kernel extensions.

### SMC Access
Direct hardware access via IOKit for:
- CPU temperature (keys: TC0D, TCAH, TC0F, TC0H)
- Fan RPM (keys: F0Ac, F1Ac)

### Privileged Helper (NEW)
- Helper Tool 安装位置: `/Library/PrivilegedHelperTools/`
- LaunchDaemon 配置: `/Library/LaunchDaemons/com.sunshinev.TurboBoostSwitcher.helper.plist`
- 使用 SMJobBless 进行一次性授权安装
- XPC 通信提供安全的进程间调用

## COMMANDS

### Build (Xcode)
```bash
# Open in Xcode
open "Turbo Boost Switcher.xcodeproj"

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

### Helper Tool Management
```bash
# 检查 Helper 状态
ls /Library/PrivilegedHelperTools/
ls /Library/LaunchDaemons/ | grep TurboBoost

# 手动加载 Helper
sudo launchctl load /Library/LaunchDaemons/com.sunshinev.TurboBoostSwitcher.helper.plist

# 手动卸载 Helper
sudo launchctl unload /Library/LaunchDaemons/com.sunshinev.TurboBoostSwitcher.helper.plist
```

## NOTES

- **No CI/CD** — Manual builds only
- **No tests** — Zero test infrastructure
- **Deployment target**: macOS 10.13+ (已更新)
- **Hardened runtime**: Disabled (may affect notarization)
- **Code signing**: 需要 Developer ID Application 证书
- **Swift Package 依赖**: SecureXPC, Blessed

## SEE ALSO

- [DEVELOPER.md](DEVELOPER.md) — 开发者指南，包含 Helper Tool 配置说明