## ADDED Requirements

### Requirement: XPC 协议方法选择器必须匹配

GUI App 的 XPC 客户端与 Helper Tool 服务端之间的协议方法选择器 SHALL 精确匹配，确保 XPC 消息能被正确路由。

#### Scenario: loadKext 方法选择器匹配
- **WHEN** 客户端调用 `loadKextAtPath:use32Bit:completion:`
- **THEN** Helper Tool 的 `loadKext(atPath:withReply:)` 方法 SHALL 使用 `@objc(loadKextAtPath:use32Bit:completion:)` 选择器映射
- **AND** XPC 调用成功执行

#### Scenario: unloadKext 方法选择器匹配
- **WHEN** 客户端调用 `unloadKextAtPath:completion:`
- **THEN** Helper Tool 的 `unloadKext(atPath:withReply:)` 方法 SHALL 使用 `@objc(unloadKextAtPath:completion:)` 选择器映射
- **AND** XPC 调用成功执行

#### Scenario: readSMCKey 方法选择器匹配
- **WHEN** 客户端调用 `readSMCKey:type:completion:`
- **THEN** Helper Tool 的 `readSMCKey(_:type:withReply:)` 方法 SHALL 使用 `@objc(readSMCKey:type:completion:)` 选择器映射
- **AND** XPC 调用成功执行

#### Scenario: getStatus 方法选择器匹配
- **WHEN** 客户端调用 `getStatusWithCompletion:`
- **THEN** Helper Tool 的 `getStatus(withReply:)` 方法 SHALL 使用 `@objc(getStatusWithCompletion:)` 选择器映射
- **AND** XPC 调用成功执行

### Requirement: SMC 连接错误必须有日志

当 SMC 连接失败时，Helper Tool SHALL 记录错误日志以便诊断问题。

#### Scenario: AppleSMC 设备不存在时记录错误
- **WHEN** `IOIteratorNext()` 返回 0（未找到 AppleSMC 设备）
- **THEN** SMCManager SHALL 记录错误日志 "[SMCManager] ERROR: AppleSMC device not found"
- **AND** 返回无效连接句柄 0

#### Scenario: SMC 连接成功时记录信息
- **WHEN** `IOServiceOpen()` 成功打开 SMC 连接
- **THEN** SMCManager SHALL 记录信息日志 "[SMCManager] SMC connection opened: <conn_id>"
- **AND** 返回有效的连接句柄