# Turbo Boost Disabler

**Active source directory** — All development happens here. Root-level `.m/.h` files are orphaned duplicates.

## STRUCTURE
```
Turbo Boost Disabler/
├── AppDelegate.m/.h           # Main app controller (1265 lines)
├── SystemCommands.m/.h        # Kext management, SMC access (676 lines)
├── StartupHelper.m/.h         # Preferences persistence (291 lines)
├── ChartWindowController.*    # Temperature/fan charts
├── HotKeysWindowController.*  # Global hotkey config
├── CheckUpdates*.*            # Update checking
├── AboutWindowController.*    # About dialog
├── HelpWindowController.*     # Help window
├── ChartView.m/.h             # Custom chart NSView
├── main.m                     # Entry point: NSApplicationMain()
├── smc.h                      # SMC hardware interface
├── *.xib                      # Interface Builder files
├── *.kext/                    # Precompiled kernel extensions
└── *.lproj/                   # en/es localizations
```

## WHERE TO LOOK

| Feature | File | Key Methods |
|---------|------|-------------|
| Status bar item | `AppDelegate.m:97-261` | `awakeFromNib` |
| Turbo Boost toggle | `AppDelegate.m`, `SystemCommands.m` | `enableDisableTurboBoost`, `loadModuleWithAuthRef:` |
| CPU temperature | `SystemCommands.m`, `smc.h` | `readCurrentCpuTemp`, `SMCGetTemperature` |
| Fan speed | `SystemCommands.m`, `smc.h` | `readCurrentFanSpeed`, `SMCGetFanRpm` |
| Login item | `StartupHelper.m` | `setLoginItemEnabled:` |
| Preferences | `StartupHelper.m` | `getUserDefaults`, `setUserDefaults` |
| Wake/sleep handling | `AppDelegate.m` | `receiveSleepNote:`, `receiveWakeNote:` |
| Language switching | `AppDelegate.m:569-630` | `languageChanged:` |
| Hotkey registration | `HotKeysWindowController.m` | `HotKeysConfigDelegate` |

## SMC KEYS

| Key | Purpose |
|-----|---------|
| `TC0D`, `TCAH`, `TC0F`, `TC0H` | CPU temperature sensors |
| `F0Ac`, `F1Ac` | Fan RPM (current) |
| `F0Mn`, `F1Mn` | Fan RPM (minimum) |

## KERNEL EXTENSIONS

Bundled precompiled kexts (no source in repo):
- `DisableTurboBoost.32bits.kext` — 32-bit kernel
- `DisableTurboBoost.64bits.kext` — 64-bit kernel

Loading requires:
1. `AuthorizationRef` (admin password)
2. User approval on macOS 10.13+ (System Preferences → Security)

## NOTES

- `AppDelegate.m` is the largest file — refactoring opportunities exist
- Language menu uses if-else chain (TODO: use NSDictionary)
- Hardened runtime disabled — may affect notarization