## Why

### 核心问题：XPC 框架不兼容

项目使用 **两套完全不兼容的 XPC 技术栈**：

| 组件 | 技术栈 | 问题 |
|------|--------|------|
| Helper Tool | Swift + **SecureXPC** | 使用 Codable + Route-based API |
| 主应用 | ObjC + **NSXPCConnection** | 使用 NSSecureCoding + Protocol-based API |

这两套协议使用完全不同的序列化和消息格式，无法互通：

- **SecureXPC** 消息格式：`{__route, __payload, __request_id}`（自定义 XPC 字典键）
- **NSXPCConnection** 消息格式：Apple 私有协议（NSSecureCoding 序列化）

**结果**：
1. `HelperInstallationManager` 检测到 Helper 文件存在 → 日志显示 "Helper available: YES"
2. 但 XPC 通信根本不工作（协议不兼容）
3. 代码 fallback 到 **AuthorizationRef 降级模式**
4. 每次启用/禁用 Turbo Boost 都需要输入密码

### 用户体验问题

用户报告在使用 XPC (Helper) 模式禁用 Turbo Boost 时：
1. 日志显示"使用 XPC (Helper) - 无需密码"，但实际仍弹出密码框
2. 状态栏图标和菜单没有变化
3. 图表窗口中只有 CPU 负载更新，温度和风扇转速数据不更新

## What Changes

- **🔴 核心修复：替换 NSXPCConnection 客户端为 SecureXPC**：创建 Swift XPC 客户端，使用 SecureXPC API 连接 Helper Tool，实现真正的免密码操作
- **修复状态栏不更新问题**：确保 XPC 调用成功后，状态栏图标和菜单项正确反映 Turbo Boost 状态变化
- **修复图表传感器数据不更新问题**：修复 `readSensorsWithCompletion` 方法中传感器数据读取和回调逻辑，确保温度和风扇数据正确传递到 UI
- **改进错误处理和日志记录**：增加更多的调试日志，帮助诊断 XPC 通信和传感器读取问题
- **确保主线程更新 UI**：验证所有 UI 更新操作都在主线程执行

## Capabilities

### New Capabilities
- `xpc-securexpc-client`: 使用 SecureXPC 库创建 Swift XPC 客户端，实现与 Helper Tool 的无缝通信
- `xpc-status-update`: 修复 XPC 模式下禁用/启用 Turbo Boost 后的状态栏更新机制
- `sensor-data-refresh`: 修复图表窗口中温度和风扇转速数据的读取和显示

### Modified Capabilities
- `auth-ref-deprecation`: 移除 AuthorizationRef 降级模式依赖，实现真正的免密码操作

### Removed Capabilities
- `auth-ref-fallback`: 删除 AuthorizationRef 降级模式代码（不再需要）

## Impact

### 文件变更
- **新增**: `Turbo Boost Disabler/XPCClient.swift` - SecureXPC 客户端实现
- **修改**: `TurboBoostManager.m` - 使用新的 SecureXPC 客户端
- **删除**: `XPCClientWrapper.m` - 旧的 NSXPCConnection 客户端
- **用户界面**: 状态栏图标、菜单文本、图表数据将正确反映实际状态
- **用户体验**: 启用/禁用 Turbo Boost 不再需要输入密码

### 风险
- Swift/ObjC 混编需要正确的桥接配置
- Xcode 项目需要添加 Swift 支持
