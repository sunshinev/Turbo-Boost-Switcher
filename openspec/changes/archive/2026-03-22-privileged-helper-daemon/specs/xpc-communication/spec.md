# XPC Communication

XPC 进程间通信机制，GUI App 与 Helper Tool 之间的安全通信通道。

## ADDED Requirements

### Requirement: XPC 连接建立

GUI App 必须能够建立与 Helper Tool 的 XPC 连接。

#### Scenario: 成功建立连接
- **WHEN** GUI App 启动并检测到 Helper Tool 已安装
- **THEN** GUI App 创建 XPC 客户端连接
- **AND** 连接到 Helper Tool 的 Mach Service

#### Scenario: Helper Tool 未安装
- **WHEN** GUI App 尝试连接但 Helper Tool 未安装
- **THEN** 返回连接错误
- **AND** GUI App 回退到原有授权流程

### Requirement: XPC 请求验证

Helper Tool 必须验证 XPC 请求的来源。

#### Scenario: 验证合法调用者
- **WHEN** 收到 XPC 请求
- **THEN** Helper Tool 验证调用者的代码签名
- **AND** 只接受来自同一 Team ID 的请求

#### Scenario: 拒绝非法调用者
- **WHEN** 收到来自未授权进程的 XPC 请求
- **THEN** Helper Tool 拒绝该请求
- **AND** 记录安全日志

### Requirement: 异步请求处理

XPC 通信必须支持异步请求和响应。

#### Scenario: 异步 kext 操作
- **WHEN** GUI App 发送 kext 加载请求
- **THEN** 请求异步执行
- **AND** 完成后通过回调返回结果

#### Scenario: 请求超时处理
- **WHEN** XPC 请求超过 30 秒未响应
- **THEN** 返回超时错误
- **AND** GUI App 显示错误提示

### Requirement: XPC 路由定义

XPC 必须定义清晰的路由结构。

#### Scenario: kext 路由
- **WHEN** GUI App 调用 `kext/load` 或 `kext/unload` 路由
- **THEN** Helper Tool 执行相应的 kext 操作

#### Scenario: SMC 路由
- **WHEN** GUI App 调用 `smc/read` 路由
- **THEN** Helper Tool 读取指定的 SMC 键值

#### Scenario: 状态路由
- **WHEN** GUI App 调用 `status/get` 路由
- **THEN** Helper Tool 返回当前状态

### Requirement: 错误传递

XPC 通信必须正确传递错误信息。

#### Scenario: 操作失败
- **WHEN** Helper Tool 执行操作失败
- **THEN** 返回错误类型和描述
- **AND** GUI App 显示适当的错误信息