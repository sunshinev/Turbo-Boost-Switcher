## ADDED Requirements

### Requirement: UI 状态与 TurboBoostManager 同步
当 Turbo Boost 状态改变时，UI 必须正确反映 `TurboBoostManager` 中的状态。

#### Scenario: 使用 Helper 模式切换状态
- **WHEN** 用户点击菜单切换 Turbo Boost 状态
- **AND** 使用 Helper (XPC) 模式
- **THEN** `TurboBoostManager.isTurboBoostEnabled` 被更新
- **AND** UI 状态栏图标和菜单文本反映新状态

#### Scenario: 使用降级模式切换状态
- **WHEN** 用户点击菜单切换 Turbo Boost 状态
- **AND** 使用降级模式 (AuthorizationRef)
- **THEN** `TurboBoostManager.isTurboBoostEnabled` 被更新
- **AND** UI 状态栏图标和菜单文本反映新状态

#### Scenario: 唤醒后状态恢复
- **WHEN** 系统从睡眠中唤醒
- **AND** Turbo Boost 之前被禁用
- **THEN** Helper 重新加载 kext
- **AND** UI 正确显示禁用状态
