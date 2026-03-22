## ADDED Requirements

### Requirement: About 窗口显示应用信息

系统 SHALL 提供 About 窗口显示应用版本、原作者信息和 Pro 版本推荐。

#### Scenario: 显示基本应用信息
- **WHEN** 用户点击菜单中的 "About Turbo Boost Switcher"
- **THEN** 系统 SHALL 显示 About 窗口
- **AND** 窗口 SHALL 显示应用图标
- **AND** 窗口 SHALL 显示应用名称 "Turbo Boost Switcher"
- **AND** 窗口 SHALL 显示当前版本号

### Requirement: 致敬原作者

About 窗口 SHALL 明确说明本项目 fork 自原作者的开源项目。

#### Scenario: 显示原作者信息
- **WHEN** About 窗口打开
- **THEN** 窗口 SHALL 显示致敬区块
- **AND** 区块 SHALL 包含原作者姓名 "Rubén García Pérez"
- **AND** 区块 SHALL 包含原项目 GitHub 链接 "github.com/rugarciap/Turbo-Boost-Switcher"
- **AND** 区块 SHALL 说明许可证为 "GPL v2"

### Requirement: 推荐 Pro 版本

About 窗口 SHALL 推荐用户使用原作者的 Pro 版本。

#### Scenario: 显示 Pro 版本推荐
- **WHEN** About 窗口打开
- **THEN** 窗口 SHALL 显示 Pro 版本推荐区块
- **AND** 区块 SHALL 列出 Pro 版本的特性 (自动模式、图表导出、优先支持)
- **AND** 区块 SHALL 提供 "了解 Pro 版本" 链接
- **AND** 链接 SHALL 指向原作者的 Pro 版本页面

### Requirement: SwiftUI 实现

About 窗口 SHALL 使用 SwiftUI 实现，通过 NSHostingController 与 AppKit 集成。

#### Scenario: SwiftUI 视图正确渲染
- **WHEN** About 窗口打开
- **THEN** SwiftUI 视图 SHALL 正确渲染
- **AND** 窗口 SHALL 支持深色模式
- **AND** 窗口 SHALL 支持系统字体缩放

#### Scenario: 窗口关闭按钮正常工作
- **WHEN** 用户点击关闭按钮
- **THEN** 窗口 SHALL 正确关闭
- **AND** 应用 SHALL 不退出
