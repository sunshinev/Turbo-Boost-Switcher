## ADDED Requirements

### Requirement: XPC 禁用 Turbo Boost 后状态栏正确更新
当用户使用 XPC (Helper) 模式禁用 Turbo Boost 时，系统 SHALL 确保状态栏图标和菜单文本正确反映新的状态。

#### Scenario: 成功禁用后状态栏更新
- **WHEN** 用户点击禁用 Turbo Boost 菜单项
- **AND** XPC 调用成功返回
- **THEN** 状态栏图标 SHALL 变为禁用状态图标（icon_off）
- **AND** 菜单项文本 SHALL 变为"启用 Turbo Boost"

#### Scenario: 成功启用后状态栏更新
- **WHEN** 用户点击启用 Turbo Boost 菜单项
- **AND** XPC 调用成功返回
- **THEN** 状态栏图标 SHALL 变为启用状态图标（icon）
- **AND** 菜单项文本 SHALL 变为"禁用 Turbo Boost"

### Requirement: TurboBoostManager 状态同步
TurboBoostManager SHALL 在 XPC 操作完成后立即更新其 `isTurboBoostEnabled` 属性。

#### Scenario: 禁用操作完成后状态更新
- **WHEN** `disableTurboBoostWithCompletion` 的 XPC 回调被调用
- **AND** 操作成功（success = YES）
- **THEN** `isTurboBoostEnabled` SHALL 被设置为 NO

#### Scenario: 启用操作完成后状态更新
- **WHEN** `enableTurboBoostWithCompletion` 的 XPC 回调被调用
- **AND** 操作成功（success = YES）
- **THEN** `isTurboBoostEnabled` SHALL 被设置为 YES

### Requirement: 主线程 UI 更新
所有 UI 更新操作 SHALL 在主线程执行。

#### Scenario: XPC 回调在主线程更新 UI
- **WHEN** XPC 操作完成回调被触发
- **THEN** 状态栏更新 SHALL 在主线程执行
