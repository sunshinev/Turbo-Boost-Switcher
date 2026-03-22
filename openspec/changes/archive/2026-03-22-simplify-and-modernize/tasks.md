## 1. 清理非核心功能文件

- [x] 1.1 删除 HotKeysWindowController.h/.m/.xib 文件
- [x] 1.2 删除 HelpWindowController.h/.m/.xib 文件
- [x] 1.3 删除 CheckUpdatesWindowController.h/.m/.xib 文件
- [x] 1.4 删除 CheckUpdatesHelper.h/.m 文件
- [x] 1.5 删除遗留图表文件 ChartView.h/.m
- [x] 1.6 删除遗留数据模型 ChartDataEntry.h/.m
- [x] 1.7 删除遗留协议 ChartDataDelegate.h
- [x] 1.8 从 Xcode 项目中移除上述文件的引用
- [x] 1.9 验证项目编译通过

## 2. 简化 AppDelegate 代码

- [x] 2.1 移除热键相关 IBOutlet 和属性声明
- [x] 2.2 移除热键配置方法 configureHotKeys
- [x] 2.3 移除更新检查相关代码 (checkUpdatesHelper)
- [x] 2.4 移除 Pro 提示代码 (runCount, neverShowProMessage 逻辑)
- [x] 2.5 移除语言切换菜单相关 IBOutlet (languageMenu, englishMenu 等)
- [x] 2.6 移除 languageChanged: 方法
- [x] 2.7 移除 updateLanguageMenu 方法
- [x] 2.8 移除菜单传感器显示 IBOutlet (txtCpuTemp, txtCpuFan, txtCpuLoad, batteryImage 等)
- [x] 2.9 简化 updateSensorValues 方法 (移除 UI 更新，保留数据采集)
- [x] 2.10 验证菜单功能正常 (TB 开关、开机设置、图表入口、About、退出)

## 3. 简化 StartupHelper 偏好设置

- [x] 3.1 移除热键相关偏好设置方法 (isHotKeysEnabled, turboBoostHotKeys, chartHotKey)
- [x] 3.2 移除更新检查偏好设置方法 (isCheckUpdatesOnStart)
- [x] 3.3 移除 Pro 提示偏好设置方法 (neverShowProMessage, runCount)
- [x] 3.4 移除语言偏好设置方法 (currentLocale, storeCurrentLocale)
- [x] 3.5 验证偏好设置读写正常

## 4. 图表功能精简

- [x] 4.1 从 ChartViews.swift 移除风扇转速相关代码 (ChartDataSet.fanData, fanEntries)
- [x] 4.2 从 SwiftUIChartManager 移除 addFanEntry 方法
- [x] 4.3 从 ChartWindowController.m 移除 addFanEntry: 方法声明和实现
- [x] 4.4 从 ChartContainerView 移除风扇转速图表视图
- [x] 4.5 从 AppDelegate 移除风扇数据推送到图表的代码
- [x] 4.6 验证图表窗口显示正确 (温度、CPU负载、CPU频率)

## 5. 本地化精简

- [x] 5.1 备份现有本地化文件
- [x] 5.2 移除非 en.lproj 和 zh-Hans.lproj 的本地化目录
- [x] 5.3 更新 Xcode 项目 knownRegions 设置
- [x] 5.4 实现系统语言自动检测逻辑
- [x] 5.5 验证英文和中文本地化正常工作

## 6. About 窗口 SwiftUI 重写

- [x] 6.1 创建 AboutView.swift (SwiftUI 视图)
- [x] 6.2 设计 About 窗口布局 (应用信息、致敬区块、Pro 推荐)
- [x] 6.3 创建 AboutWindowController.swift (NSWindowController 子类)
- [x] 6.4 使用 NSHostingController 桥接 SwiftUI 视图
- [x] 6.5 实现深色模式支持
- [x] 6.6 实现 Pro 版本链接点击功能
- [x] 6.7 更新 AppDelegate 中 About 窗口创建代码
- [x] 6.8 删除旧的 AboutWindowController.h/.m/.xib
- [x] 6.9 验证 About 窗口显示正确

## 7. 项目配置更新

- [x] 7.1 更新 Deployment Target 为 macOS 10.15
- [x] 7.2 更新 Info.plist 中的最低版本说明
- [x] 7.3 检查并更新 Swift Language Version (如果需要)
- [x] 7.4 清理无用的 Build Settings
- [x] 7.5 更新 AGENTS.md 文档反映新架构
- [x] 7.6 验证项目在 macOS 10.15+ 上正常运行

## 8. 测试和验证

- [x] 8.1 测试 Turbo Boost 开关功能正常
- [x] 8.2 测试 Helper Tool 安装和使用正常
- [x] 8.3 测试图表窗口显示正常 (温度、CPU负载、CPU频率)
- [x] 8.4 测试 About 窗口显示正常
- [x] 8.5 测试开机启动设置正常
- [x] 8.6 测试启动时禁用 TB 设置正常
- [x] 8.7 测试深色模式下 UI 显示正常
- [x] 8.8 测试英文和中文本地化正常
- [x] 8.9 执行完整构建验证 (xcodebuild)
- [x] 8.10 检查内存泄漏和性能问题

## 9. 清理和文档

- [x] 9.1 移除根目录孤立文件 (已不使用的 .m/.h 文件)
- [x] 9.2 更新 README.md 说明变更
- [x] 9.3 创建 CHANGELOG.md 记录变更
- [x] 9.4 更新 AGENTS.md 反映精简后的架构
- [x] 9.5 清理 .xib 文件中无用的 UI 元素
- [x] 9.6 最终代码审查和清理
