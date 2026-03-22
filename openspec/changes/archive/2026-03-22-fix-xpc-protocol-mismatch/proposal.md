## Why

GUI App 的 XPC 客户端调用的方法选择器与 Helper Tool 服务端定义的方法签名不匹配，导致所有 XPC 操作（readSMCKey、loadKext、getStatus）都超时失败。用户无法禁用 Turbo Boost，图表显示 N/A。

这是一个严重的功能缺陷，Helper Tool 已安装并运行（PID 存在），但由于 ObjC 选择器名称不匹配，XPC 消息无法被正确路由。

## What Changes

- 修复 `HelperTool/main.swift` 中的 `ObjCHelperToolProtocol` 协议方法，添加 `@objc` 选择器映射使其与客户端期望的选择器名称匹配
- 在 `SMCManager.swift` 的 `openSMCConnection()` 方法中添加错误检查和日志
- 确保以下 XPC 方法的选择器正确映射：
  - `loadKextAtPath:use32Bit:completion:`
  - `unloadKextAtPath:completion:`
  - `readSMCKey:type:completion:`
  - `getStatusWithCompletion:`

## Capabilities

### New Capabilities

无新增能力。

### Modified Capabilities

- `xpc-communication`: 修复 XPC 协议方法签名，确保 GUI App 与 Helper Tool 之间的 XPC 通信正常工作

## Impact

**代码影响：**
- `HelperTool/main.swift` — 添加 `@objc` 选择器映射到 `HelperXPCDelegate` 的所有方法
- `HelperTool/SMCManager.swift` — 添加错误检查和日志

**功能影响：**
- Turbo Boost 禁用/启用功能恢复
- CPU 温度、风扇转速、CPU 频率图表恢复正常显示
- Helper Tool 状态检测恢复正常

**用户影响：**
- 所有使用 Helper Tool 的用户（已安装 Helper 的用户）都会遇到此问题
- 修复后需要重新安装 Helper Tool