## ADDED Requirements

### Requirement: 传感器数据正确读取和传递
当使用 XPC 模式读取传感器数据时，系统 SHALL 正确读取温度和风扇转速，并将数据传递给 UI 层。

#### Scenario: 成功读取温度和风扇数据
- **WHEN** `readSensorsWithCompletion` 被调用
- **AND** XPC 成功读取温度数据
- **AND** XPC 成功读取风扇数据
- **THEN** completion SHALL 被调用，传入正确的温度和风扇值
- **AND** UI SHALL 显示读取到的数值

#### Scenario: 部分传感器读取失败
- **WHEN** `readSensorsWithCompletion` 被调用
- **AND** 温度读取失败
- **AND** 风扇读取成功
- **THEN** completion SHALL 仍然被调用
- **AND** 温度值 SHALL 为 0 或上次有效值
- **AND** 风扇值 SHALL 为读取到的有效值

### Requirement: 图表数据实时更新
图表窗口 SHALL 实时显示传感器数据的变化。

#### Scenario: 图表窗口打开时更新温度
- **WHEN** 图表窗口处于打开状态
- **AND** 新的温度数据被读取
- **THEN** 温度图表 SHALL 更新显示新数据点
- **AND** 当前温度文本 SHALL 更新

#### Scenario: 图表窗口打开时更新风扇转速
- **WHEN** 图表窗口处于打开状态
- **AND** 新的风扇转速数据被读取
- **THEN** 风扇转速图表 SHALL 更新显示新数据点
- **AND** 当前风扇转速文本 SHALL 更新

### Requirement: SMC Key 兼容性
系统 SHALL 尝试多个 SMC key 以确保在不同硬件上的兼容性。

#### Scenario: 尝试多个温度 key
- **WHEN** 读取温度时第一个 key (TC0D) 失败
- **THEN** 系统 SHALL 尝试下一个 key (TCAH)
- **AND** 继续尝试直到成功或所有 key 都失败

#### Scenario: 尝试多个风扇 key
- **WHEN** 读取风扇转速时第一个 key (F0Ac) 失败
- **THEN** 系统 SHALL 尝试下一个 key (F1Ac)
- **AND** 继续尝试直到成功或所有 key 都失败

### Requirement: 传感器读取错误处理
当传感器读取失败时，系统 SHALL 优雅处理错误，不影响其他功能。

#### Scenario: 所有温度 key 都失败
- **WHEN** 所有温度 SMC key 都读取失败
- **THEN** 温度值 SHALL 显示为 "N/A"
- **AND** 风扇数据仍然 SHALL 正常显示（如果读取成功）

#### Scenario: 所有风扇 key 都失败
- **WHEN** 所有风扇 SMC key 都读取失败
- **THEN** 风扇转速 SHALL 显示为 "N/A"
- **AND** 温度数据仍然 SHALL 正常显示（如果读取成功）
