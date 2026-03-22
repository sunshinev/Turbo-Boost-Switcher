## ADDED Requirements

### Requirement: 通过 Helper 读取温度传感器
系统必须通过 XPC Helper 正确读取 CPU 温度传感器数据。

#### Scenario: 成功读取温度
- **WHEN** 定时器触发传感器更新
- **AND** 使用 Helper 模式
- **THEN** 尝试读取 SMC 温度键 (TC0D, TCAH, TC0F, TC0H)
- **AND** 第一个成功的值被用于显示
- **AND** 图表窗口显示温度数据

#### Scenario: 温度读取失败
- **WHEN** 定时器触发传感器更新
- **AND** 所有温度 SMC 键都读取失败
- **THEN** 记录错误日志，包含失败的键和错误原因
- **AND** 显示 "N/A"

### Requirement: 通过 Helper 读取风扇转速
系统必须通过 XPC Helper 正确读取风扇转速数据。

#### Scenario: 成功读取风扇转速
- **WHEN** 定时器触发传感器更新
- **AND** 使用 Helper 模式
- **THEN** 尝试读取 SMC 风扇键 (F0Ac, F1Ac)
- **AND** 第一个成功的值被用于显示
- **AND** 图表窗口显示风扇转速数据

#### Scenario: 风扇读取失败
- **WHEN** 定时器触发传感器更新
- **AND** 所有风扇 SMC 键都读取失败
- **THEN** 记录错误日志，包含失败的键和错误原因
- **AND** 显示 "N/A"

### Requirement: 传感器读取日志记录
系统必须在传感器读取失败时记录详细日志，便于诊断问题。

#### Scenario: SMC 读取失败日志
- **WHEN** SMC 键读取失败
- **THEN** 记录包含以下信息的日志：
  - 尝试读取的键名
  - 错误类型 (权限、键不存在、通信错误)
  - 当前模式 (Helper/降级)
