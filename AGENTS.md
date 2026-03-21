# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-22
**Commit:** 454c189
**Branch:** master

## OVERVIEW
macOS status bar app to enable/disable Intel Turbo Boost via kernel extensions. Pure Objective-C, no Swift. GPL v2 licensed.

## STRUCTURE
```
.
├── Turbo Boost Disabler/    # ACTIVE SOURCE — all development here
├── *.lproj/                  # Localization (11 languages)
├── *.m, *.h                  # ORPHANED — do NOT edit (duplicates)
└── Turbo Boost Switcher.xcodeproj
```

## CRITICAL: Duplicate Files Warning

**Root-level .m/.h files are ORPHANED** — Xcode builds from `Turbo Boost Disabler/` only.

| Root File | Status | Actual Source |
|-----------|--------|---------------|
| `AppDelegate.m` | ❌ Older (31KB) | `Turbo Boost Disabler/AppDelegate.m` (44KB) |
| `StartupHelper.m` | ❌ Older (7KB) | `Turbo Boost Disabler/StartupHelper.m` (10KB) |
| `SystemCommands.m` | ❌ Duplicate | `Turbo Boost Disabler/SystemCommands.m` |
| `AboutWindowController.m` | ❌ Duplicate | `Turbo Boost Disabler/AboutWindowController.m` |

**Rule: Always edit files in `Turbo Boost Disabler/` subdirectory.**

## WHERE TO LOOK

| Task | Location |
|------|----------|
| App lifecycle, status bar UI | `Turbo Boost Disabler/AppDelegate.m` |
| Kext load/unload, SMC access | `Turbo Boost Disabler/SystemCommands.m` |
| CPU temp, fan speed reading | `Turbo Boost Disabler/smc.h`, `SystemCommands.m` |
| Preferences persistence | `Turbo Boost Disabler/StartupHelper.m` |
| Update checking | `Turbo Boost Disabler/CheckUpdatesHelper.m` |
| Chart UI | `Turbo Boost Disabler/ChartWindowController.m` |
| Hot keys | `Turbo Boost Disabler/HotKeysWindowController.m` |
| Localization strings | `*.lproj/Localizable.strings` |

## ARCHITECTURE

### Entry Points
- `main.m` → `NSApplicationMain()` → loads `MainMenu.xib`
- `AppDelegate` wired as `NSApplication.delegate` in NIB
- `awakeFromNib` initializes status bar, timers, preferences

### Core Components
| Class | Role |
|-------|------|
| `AppDelegate` | Main controller: status bar, Turbo Boost toggle, sensor updates |
| `SystemCommands` | Kernel extension management, SMC hardware access |
| `StartupHelper` | UserDefaults persistence, login items |
| `*WindowController` | MVC windows (About, Charts, HotKeys, Help, Updates) |

### Data Flow
```
User click → AppDelegate → SystemCommands → kext load/unload
                          ↘ SMC read (temp/fan)
                          ↘ Authorization framework (admin)
```

## CONVENTIONS

### Documentation Language
**所有生成的 Markdown 文档必须使用中文描述。** This project requires all generated `.md` files (AGENTS.md, README, design docs, etc.) to be written in Chinese (简体中文). Code comments and technical terms may remain in English where appropriate.

### Header Style
Every file includes GPL v2 license header with author (Rubén García Pérez).

### Naming
- Window controllers: `*WindowController.h/.m/.xib`
- Helpers: `*Helper.h/.m`
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

## NOTES

- **No CI/CD** — Manual builds only
- **No tests** — Zero test infrastructure
- **Deployment target**: macOS 10.7+ (Lion, 2011)
- **Hardened runtime**: Disabled (may affect notarization)
- **Code signing**: Manual, Developer ID Application