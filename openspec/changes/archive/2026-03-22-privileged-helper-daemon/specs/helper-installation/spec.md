# Helper Installation

Helper Tool 安装管理，使用 SMJobBless 实现一次性授权安装。

## ADDED Requirements

### Requirement: 检测 Helper 安装状态

GUI App 必须能够检测 Helper Tool 是否已安装。

#### Scenario: Helper 已安装
- **WHEN** GUI App 检查 Helper 状态
- **AND** Helper Tool 已安装在系统目录
- **THEN** 返回已安装状态
- **AND** 返回 Helper 版本号

#### Scenario: Helper 未安装
- **WHEN** GUI App 检查 Helper 状态
- **AND** Helper Tool 未安装
- **THEN** 返回未安装状态

### Requirement: 首次安装授权

首次安装 Helper Tool 时，必须请求用户授权。

#### Scenario: 用户授权安装
- **WHEN** 用户首次需要特权操作
- **AND** Helper Tool 未安装
- **THEN** 显示授权对话框
- **AND** 用户输入管理员密码后安装 Helper Tool

#### Scenario: 用户拒绝授权
- **WHEN** 用户取消授权对话框
- **THEN** 不安装 Helper Tool
- **AND** GUI App 回退到原有授权流程

### Requirement: SMJobBless 安装

必须使用 SMJobBless 进行 Helper Tool 安装。

#### Scenario: SMJobBless 成功
- **WHEN** 调用 SMJobBless
- **AND** 代码签名验证通过
- **THEN** Helper Tool 安装到 /Library/PrivilegedHelperTools/
- **AND** LaunchDaemon 配置安装到 /Library/LaunchDaemons/
- **AND** Helper Tool 自动启动

#### Scenario: SMJobBless 失败
- **WHEN** SMJobBless 安装失败
- **THEN** 返回详细错误信息
- **AND** GUI App 显示错误提示
- **AND** 回退到原有授权流程

### Requirement: Helper 版本更新

当 Helper Tool 版本更新时，需要重新安装。

#### Scenario: 检测到新版本
- **WHEN** GUI App 检测到 Helper Tool 版本低于内置版本
- **THEN** 提示用户更新
- **AND** 用户确认后重新安装

#### Scenario: 版本回退保护
- **WHEN** 尝试安装比现有版本更低的 Helper Tool
- **THEN** SMJobBless 拒绝安装
- **AND** 保留现有版本

### Requirement: Helper 卸载

用户必须能够卸载 Helper Tool。

#### Scenario: 通过 GUI 卸载
- **WHEN** 用户选择卸载 Helper Tool
- **THEN** 停止 Helper Tool 进程
- **AND** 删除 /Library/PrivilegedHelperTools/ 中的文件
- **AND** 删除 /Library/LaunchDaemons/ 中的配置文件
- **AND** GUI App 回退到原有授权流程

### Requirement: 代码签名验证

Helper Tool 安装必须通过代码签名验证。

#### Scenario: 签名验证通过
- **WHEN** Helper Tool 的代码签名与 Info.plist 中的要求匹配
- **THEN** 允许安装

#### Scenario: 签名验证失败
- **WHEN** Helper Tool 未签名或签名不匹配
- **THEN** 拒绝安装
- **AND** 返回签名错误信息