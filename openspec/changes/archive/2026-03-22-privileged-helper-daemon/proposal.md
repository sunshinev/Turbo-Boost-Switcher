# Privileged Helper Daemon

## Why

当前 Turbo Boost Switcher 使用 `AuthorizationRef` 请求管理员权限来加载/卸载内核扩展，但 macOS 的授权机制默认有 5 分钟超时限制。这导致用户在以下场景频繁被要求输入密码：

1. 系统休眠后唤醒（需要重新加载 kext）
2. 启用传感器监控时周期性读取 CPU 频率
3. 长时间未操作后再次切换 Turbo Boost 状态

这是用户最常抱怨的问题，也是 PRO 版本的核心卖点。通过实现 Privileged Helper Daemon，可以一次性获取授权并持久运行，彻底解决重复输入密码的问题。

## What Changes

- **新增** Privileged Helper Tool（以 root 权限运行的守护进程）
- **新增** XPC 通信层（GUI App ↔ Helper Tool）
- **新增** SMJobBless 安装流程（一次性授权安装）
- **修改** kext 加载/卸载逻辑从 GUI App 迁移到 Helper Tool
- **修改** SMC 读取逻辑从 GUI App 迁移到 Helper Tool
- **新增** Helper Tool 生命周期管理（安装、更新、卸载）

## Capabilities

### New Capabilities

- `privileged-helper`: 特权助手守护进程，以 root 权限运行，处理需要管理员权限的操作（kext 加载/卸载、SMC 读取）
- `xpc-communication`: XPC 进程间通信机制，GUI App 与 Helper Tool 之间的安全通信通道
- `helper-installation`: Helper Tool 安装管理，使用 SMJobBless 实现一次性授权安装

### Modified Capabilities

无（这是新增功能，不改变现有能力的需求规格）

## Impact

### 代码变更

| 文件/模块 | 变更类型 | 说明 |
|-----------|----------|------|
| `Turbo Boost Disabler/` | 修改 | XPC Client 集成，替换直接授权调用 |
| `HelperTool/` | 新增 | Privileged Helper Tool target |
| `SystemCommands.m` | 重构 | 权限相关方法迁移到 Helper |
| `AppDelegate.m` | 修改 | 使用 XPC 调用替代直接操作 |

### 新增依赖

| 依赖 | 用途 |
|------|------|
| **Blessed** (Swift Package) | SMJobBless 封装，简化授权安装流程 |
| **SecureXPC** (Swift Package) | XPC 通信框架，提供类型安全的 IPC |

### 系统影响

- Helper Tool 安装位置：`/Library/PrivilegedHelperTools/`
- LaunchDaemon 配置：`/Library/LaunchDaemons/com.sunshinev.TurboBoostSwitcher.helper.plist`
- 需要代码签名（Developer ID Application）
- 首次安装需要用户授权（管理员密码）

### 兼容性

- **最低支持版本**: macOS 10.13（SMJobBless 要求）
- **推荐**: macOS 13+ 可使用 SMAppService 简化流程
- **现有行为**: 未安装 Helper 时回退到原有授权流程（保持向后兼容）