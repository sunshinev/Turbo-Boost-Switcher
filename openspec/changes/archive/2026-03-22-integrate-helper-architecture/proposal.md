## Why

用户在使用 Turbo Boost Switcher 时，即使没有主动操作，也会被 macOS 弹出密码授权窗口。这是因为 `AppDelegate.m` 中仍然使用旧的 `AuthorizationRef` 方式加载内核扩展，而非使用已实现的 Privileged Helper 架构。

项目中已创建了 `TurboBoostManager`、`XPCClientWrapper`、`HelperInstallationManager` 等组件，但 `AppDelegate.m` 从未集成它们，导致 Helper 形同虚设。

## What Changes

- **重构 `AppDelegate.m`**：将所有 Turbo Boost 操作委托给 `TurboBoostManager`
- **修复授权弹窗问题**：当 Helper 可用时，通过 XPC 调用 Helper（以 root 运行），无需密码
- **修复 `KextManager.swift`**：移除不必要的 `sudo` 调用（Helper 已以 root 运行）
- **增强降级逻辑**：当 Helper 不可用时，才回退到旧的 `AuthorizationRef` 方式
- **修复 `readCpuFrequency`**：通过 Helper 读取 CPU 频率，避免定时器触发密码弹窗

## Capabilities

### New Capabilities

- `helper-integration`: 将 AppDelegate 的核心操作（启用/禁用 Turbo Boost、读取传感器、读取 CPU 频率）集成到 Privileged Helper 架构中，实现免密码操作

### Modified Capabilities

无（这是新架构的集成，不影响现有功能需求）

## Impact

**直接影响的文件：**
- `Turbo Boost Disabler/AppDelegate.m` — 重构为使用 `TurboBoostManager`
- `HelperTool/KextManager.swift` — 修复 `sudo` 调用问题

**架构变化：**
```
之前：AppDelegate → AuthorizationRef → 弹密码
之后：AppDelegate → TurboBoostManager → [Helper 可用?]
                                        ├── YES → XPC → Helper (root) → 无密码
                                        └── NO  → AuthorizationRef → 弹密码（降级）
```

**用户体验：**
- Helper 安装后，所有操作不再需要密码
- Helper 未安装时，行为与之前一致（降级模式）