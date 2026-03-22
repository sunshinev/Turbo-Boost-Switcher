# Privileged Helper

特权助手守护进程，以 root 权限运行，处理需要管理员权限的操作。

## ADDED Requirements

### Requirement: Helper Tool 以 root 权限运行

Helper Tool 必须以 root 用户权限运行，以便执行 kext 加载/卸载和 SMC 读取操作。

#### Scenario: Helper Tool 启动
- **WHEN** 系统启动或 launchd 加载 Helper Tool
- **THEN** Helper Tool 以 root 权限运行
- **AND** Helper Tool 创建 XPC 服务端监听请求

### Requirement: Helper Tool 持续运行

Helper Tool 必须作为守护进程持续运行，不应退出。

#### Scenario: Helper Tool 保持运行
- **WHEN** Helper Tool 启动完成
- **THEN** Helper Tool 保持运行状态
- **AND** 响应来自 GUI App 的 XPC 请求

#### Scenario: Helper Tool 异常退出后重启
- **WHEN** Helper Tool 意外退出
- **THEN** launchd 自动重启 Helper Tool
- **AND** 恢复 XPC 服务

### Requirement: kext 加载操作

Helper Tool 必须支持加载内核扩展。

#### Scenario: 成功加载 kext
- **WHEN** 收到加载 kext 的 XPC 请求
- **THEN** Helper Tool 执行 `kextload` 命令
- **AND** 返回加载结果（成功/失败）

#### Scenario: kext 加载失败
- **WHEN** kext 加载失败
- **THEN** 返回错误信息
- **AND** 不影响 Helper Tool 继续运行

### Requirement: kext 卸载操作

Helper Tool 必须支持卸载内核扩展。

#### Scenario: 成功卸载 kext
- **WHEN** 收到卸载 kext 的 XPC 请求
- **THEN** Helper Tool 执行 `kextunload` 命令
- **AND** 返回卸载结果（成功/失败）

### Requirement: SMC 读取操作

Helper Tool 必须支持读取 SMC 传感器数据。

#### Scenario: 读取 CPU 温度
- **WHEN** 收到读取 CPU 温度的 XPC 请求
- **THEN** Helper Tool 通过 IOKit 读取 SMC
- **AND** 返回温度值（摄氏度）

#### Scenario: 读取风扇转速
- **WHEN** 收到读取风扇转速的 XPC 请求
- **THEN** Helper Tool 通过 IOKit 读取 SMC
- **AND** 返回转速值（RPM）

### Requirement: kext 状态查询

Helper Tool 必须支持查询 kext 加载状态。

#### Scenario: 查询 kext 状态
- **WHEN** 收到查询状态的 XPC 请求
- **THEN** 返回当前 kext 是否已加载
- **AND** 返回 Helper Tool 版本号