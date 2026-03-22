## ADDED Requirements

### Requirement: CPU 频率单位一致性

系统 SHALL 确保所有 CPU 频率数据源返回相同单位（GHz）。

#### Scenario: Helper 模式下频率单位正确
- **WHEN** 用户使用 Helper Tool 读取 CPU 频率
- **THEN** 返回值 SHALL 为 GHz 单位（如 2.9 表示 2.9 GHz）

#### Scenario: 降级模式下频率单位正确
- **WHEN** Helper Tool 不可用，使用 SystemCommands 读取 CPU 频率
- **THEN** 返回值 SHALL 为 GHz 单位（如 2.9 表示 2.9 GHz）

#### Scenario: 图表 Y 轴刻度与数据匹配
- **WHEN** CPU 频率为 2.9 GHz
- **THEN** 图表 SHALL 在 Y 轴显示 0-4 GHz 范围
- **AND** 数据点 SHALL 在正确位置渲染

### Requirement: 显示文本正确性

系统 SHALL 显示正确的单位文本。

#### Scenario: 频率显示文本格式
- **WHEN** 显示当前 CPU 频率
- **THEN** 文本格式 SHALL 为 "{value} GHz"（注意大小写）
- **AND** 不 SHALL 显示 "Ghz" 或其他错误拼写

### Requirement: 项目构建成功

系统 SHALL 能够成功编译。

#### Scenario: Xcode 构建验证
- **WHEN** 执行 xcodebuild 命令
- **THEN** 构建结果 SHALL 为 "BUILD SUCCEEDED"
- **AND** 无编译错误