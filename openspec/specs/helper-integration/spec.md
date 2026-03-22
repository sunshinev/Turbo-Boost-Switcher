## ADDED Requirements

### Requirement: Turbo Boost 操作使用 Privileged Helper

当 Privileged Helper 已安装并运行时，所有 Turbo Boost 相关操作（启用、禁用、状态查询）SHALL 通过 XPC 调用 Helper 执行，而非直接使用 AuthorizationRef。

#### Scenario: Helper 可用时禁用 Turbo Boost 无需密码
- **WHEN** Helper 已安装且运行中
- **AND** 用户点击"Disable Turbo Boost"
- **THEN** 系统通过 XPC 调用 Helper 加载 kext
- **AND** 不弹出密码授权窗口
- **AND** Turbo Boost 被成功禁用

#### Scenario: Helper 可用时启用 Turbo Boost 无需密码
- **WHEN** Helper 已安装且运行中
- **AND** 用户点击"Enable Turbo Boost"
- **THEN** 系统通过 XPC 调用 Helper 卸载 kext
- **AND** 不弹出密码授权窗口
- **AND** Turbo Boost 被成功启用

#### Scenario: Helper 不可用时降级到密码授权
- **WHEN** Helper 未安装或不可用
- **AND** 用户执行 Turbo Boost 操作
- **THEN** 系统使用 AuthorizationRef 方式
- **AND** 弹出密码授权窗口
- **AND** 操作按原有方式执行

### Requirement: 系统唤醒后自动重载 Kext 使用 Helper

当系统从睡眠/休眠状态唤醒时，如果 Kext 已加载，应用 SHALL 通过 Helper 重新加载 Kext 以确保 Turbo Boost 状态正确。

#### Scenario: 系统唤醒时 Kext 需要重载
- **WHEN** 系统从睡眠状态唤醒
- **AND** Kext 当前已加载（Turbo Boost 已禁用）
- **AND** Helper 可用
- **THEN** 系统通过 XPC 调用 Helper 卸载并重新加载 Kext
- **AND** 不弹出密码授权窗口

### Requirement: CPU 频率读取使用 Helper

当图表窗口打开时，CPU 频率读取 SHALL 通过 Helper 执行，以避免定时器触发密码弹窗。

#### Scenario: 图表窗口读取 CPU 频率无需密码
- **WHEN** 图表窗口打开
- **AND** Helper 可用
- **AND** 定时器触发 CPU 频率读取
- **THEN** 系统通过 XPC 调用 Helper 读取 CPU 频率
- **AND** 不弹出密码授权窗口
- **AND** CPU 频率数据正确显示

### Requirement: Helper Tool 中不使用 sudo

Helper Tool 以 root 权限运行，其内部执行 shell 命令时 SHALL NOT 使用 sudo。

#### Scenario: KextManager 加载 Kext 不使用 sudo
- **WHEN** Helper 收到加载 Kext 的 XPC 请求
- **THEN** KextManager 直接调用 `/sbin/kextload`
- **AND** 不通过 `/usr/bin/sudo`

#### Scenario: KextManager 卸载 Kext 不使用 sudo
- **WHEN** Helper 收到卸载 Kext 的 XPC 请求
- **THEN** KextManager 直接调用 `/sbin/kextunload`
- **AND** 不通过 `/usr/bin/sudo`

### Requirement: 传感器数据读取使用 Helper

当 Helper 可用时，CPU 温度和风扇转速读取 SHALL 通过 Helper 的 SMCManager 执行。

#### Scenario: 读取 CPU 温度无需密码
- **WHEN** Helper 可用
- **AND** 应用请求读取 CPU 温度
- **THEN** 系统通过 XPC 调用 Helper 的 SMCManager
- **AND** 返回正确的温度数据

#### Scenario: 读取风扇转速无需密码
- **WHEN** Helper 可用
- **AND** 应用请求读取风扇转速
- **THEN** 系统通过 XPC 调用 Helper 的 SMCManager
- **AND** 返回正确的风扇转速数据