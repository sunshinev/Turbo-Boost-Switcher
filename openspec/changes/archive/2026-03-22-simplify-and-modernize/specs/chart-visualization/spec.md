## REMOVED Requirements

### Requirement: 风扇转速图表显示

**Reason**: 用户仅需温度/CPU负载/CPU频率图表，风扇转速数据对 Turbo Boost 决策帮助有限。

**Migration**: 用户可通过其他系统监控工具查看风扇转速。

## ADDED Requirements

### Requirement: 图表仅显示温度/CPU负载/CPU频率

系统 SHALL 仅在图表窗口中显示温度、CPU负载和CPU频率三条历史曲线。

#### Scenario: 图表窗口显示三个图表
- **WHEN** 用户打开图表窗口
- **THEN** 窗口 SHALL 显示三个图表
- **AND** 第一个图表 SHALL 显示 CPU 温度历史
- **AND** 第二个图表 SHALL 显示 CPU 负载历史
- **AND** 第三个图表 SHALL 显示 CPU 频率历史
- **AND** 窗口 SHALL NOT 显示风扇转速图表

#### Scenario: 图表颜色编码保持不变
- **WHEN** Turbo Boost 启用时
- **THEN** 图表数据点 SHALL 使用橙色
- **WHEN** Turbo Boost 禁用时
- **THEN** 图表数据点 SHALL 使用蓝色

### Requirement: 数据采集仅保留温度/CPU负载/CPU频率

定时器触发的传感器数据采集 SHALL 仅收集温度、CPU负载和CPU频率数据。

#### Scenario: 定时器采集传感器数据
- **WHEN** 定时器触发 (默认 4 秒间隔)
- **THEN** 系统 SHALL 采集 CPU 温度
- **AND** 系统 SHALL 计算 CPU 负载
- **AND** 系统 SHALL 读取 CPU 频率
- **AND** 系统 SHALL NOT 采集风扇转速 (或仅保留内部使用)
