## Context

Turbo Boost Switcher 是一个 macOS 状态栏应用，用于控制 Intel CPU 的 Turbo Boost 功能。当前代码库：

**当前架构**:
```
┌─────────────────────────────────────────────────────────────────────┐
│  AppDelegate (Objective-C)                                          │
│  ├── NSStatusItem + NSMenu (状态栏 UI)                              │
│  ├── TurboBoostManager (统一管理)                                   │
│  ├── 5+ WindowControllers (各种窗口)                                │
│  └── 定时器 + 传感器读取                                            │
├─────────────────────────────────────────────────────────────────────┤
│  SystemCommands (Objective-C)                                       │
│  ├── Kext 加载/卸载 (AuthorizationRef)                              │
│  ├── SMC 访问 (温度/风扇)                                           │
│  └── CPU 频率读取 (powermetrics)                                    │
├─────────────────────────────────────────────────────────────────────┤
│  Helper Tool (Swift)                                                │
│  ├── KextManager (root 权限操作)                                    │
│  ├── SMCManager (硬件访问)                                          │
│  └── XPC Server (SecureXPC)                                        │
├─────────────────────────────────────────────────────────────────────┤
│  UI 组件                                                            │
│  ├── ChartViews.swift (SwiftUI - 已迁移)                           │
│  ├── 5 个 .xib 文件 (AppKit)                                        │
│  └── 11 种本地化 (.lproj)                                           │
└─────────────────────────────────────────────────────────────────────┘
```

**约束**:
- NSStatusItem 和 NSMenu 必须保持 AppKit (SwiftUI 无替代方案)
- IOKit/SMC 访问必须保持 C/Objective-C 桥接
- Helper Tool 架构必须完整保留 (用户体验核心)
- macOS 最低版本升级到 10.15 后可使用完整 SwiftUI

## Goals / Non-Goals

**Goals:**
1. 精简代码库 - 移除 40%+ 的冗余代码和功能
2. 现代化 UI - About 窗口迁移到 SwiftUI
3. 简化维护 - 减少本地化语言，清理遗留代码
4. 保持稳定 - 核心功能 (TB 开关 + Helper + 图表) 完整保留

**Non-Goals:**
- 不重写状态栏 UI (NSStatusItem 必须保持 AppKit)
- 不改变 Helper Tool 架构
- 不添加新功能
- 不改变应用签名/公证流程

## Decisions

### Decision 1: 功能精简策略

**选择**: 大幅移除非核心功能，而非逐步优化

**理由**:
- 用户明确只需要 TB 开关 + 图表 + Helper
- 移除功能比重构功能成本更低
- 减少维护负担，降低 bug 风险

**替代方案**:
- ❌ 保留所有功能，只优化代码 — 无法解决维护成本问题
- ❌ 渐进式移除 — 增加迁移复杂度，延长项目周期

### Decision 2: SwiftUI 迁移范围

**选择**: 仅迁移 About 窗口，保持状态栏 AppKit

**理由**:
- NSStatusItem 无 SwiftUI 替代方案
- 图表 UI 已是 SwiftUI (ChartViews.swift)
- About 窗口简单，适合 SwiftUI 练手
- 最小化风险，保持核心功能稳定

**替代方案**:
- ❌ 全面 SwiftUI 重写 — 状态栏无法实现，风险高
- ❌ 保持纯 AppKit — 错过现代化机会，技术债务增加

### Decision 3: 本地化策略

**选择**: 仅保留英文和简体中文，使用系统语言自动匹配

**理由**:
- 减少翻译维护成本
- 大部分用户使用英文或中文
- macOS 系统级语言切换已足够

**实现方式**:
```swift
// 自动检测系统语言
let preferredLanguage = Locale.preferredLanguages.first ?? "en"
let isChinese = preferredLanguage.hasPrefix("zh")
Bundle.main.localizations = isChinese ? ["zh-Hans"] : ["en"]
```

**替代方案**:
- ❌ 保留 11 种语言 — 维护成本高，翻译质量参差不齐
- ❌ 仅英文 — 排除大量中文用户

### Decision 4: 图表数据精简

**选择**: 移除风扇转速图表，保留温度/CPU负载/CPU频率

**理由**:
- 用户明确只需要温度/负载/频率
- 风扇转速对 TB 决策帮助有限
- 减少数据采集频率和 CPU 开销

**影响**:
- 移除 `ChartDataSet.fanData`
- 移除 `addFanEntry:` 方法
- 保留 SMC 风扇读取代码 (可能其他地方使用)

### Decision 5: 菜单传感器显示

**选择**: 完全移除菜单中的传感器实时显示

**理由**:
- 用户通过图表查看历史数据
- 菜单显示增加定时器负担
- 简化菜单结构，提升用户体验

**实现**:
- 移除 `txtCpuTemp`, `txtCpuFan`, `txtCpuLoad` 等 IBOutlet
- 移除 `updateSensorValues` 中的 UI 更新代码
- 保留数据采集逻辑 (图表需要)

### Decision 6: About 窗口内容设计

**选择**: 重新设计 About 窗口，突出原作者贡献

**内容结构**:
```
┌─────────────────────────────────────────────────────────────────┐
│  [App Icon]                                                      │
│  Turbo Boost Switcher                                            │
│  Version 2.x.x                                                   │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  🙏 致敬原作者                                                    │
│                                                                  │
│  本项目 fork 自 Rubén García Pérez 的开源项目:                   │
│  github.com/rugarciap/Turbo-Boost-Switcher                      │
│                                                                  │
│  原项目采用 GPL v2 许可证发布。                                   │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  💎 推荐升级 Pro 版本                                            │
│                                                                  │
│  Pro 版本提供更多高级功能:                                        │
│  • 自动模式 (温度/CPU/电池/应用触发)                              │
│  • 图表导出                                                      │
│  • 优先支持                                                      │
│                                                                  │
│  [了解 Pro 版本] [关闭]                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Risks / Trade-offs

### Risk 1: macOS 版本升级导致用户流失

**风险**: 升级到 macOS 10.15+ 后，10.13/10.14 用户无法使用

**缓解**:
- 在 README 中明确说明最低版本要求
- 提供 2.x (旧版) 下载链接给老系统用户
- 监控用户系统版本分布 (如果可能)

### Risk 2: 偏好设置迁移问题

**风险**: 现有用户升级后，热键等设置丢失

**缓解**:
- 移除的设置键值不会导致崩溃 (UserDefaults 允许不存在的键)
- 首次启动时无需特殊迁移逻辑
- 在 Release Notes 中说明变更

### Risk 3: 本地化文件冲突

**风险**: 移除 .lproj 目录可能导致 Xcode 项目引用错误

**缓解**:
- 使用 Xcode 移除本地化引用 (不是直接删除文件)
- 更新 .xcodeproj 中的 knownRegions
- 构建测试确保无引用错误

### Risk 4: SwiftUI 与 AppKit 桥接问题

**风险**: About 窗口 SwiftUI 视图在 AppKit 窗口中显示异常

**缓解**:
- 使用 NSHostingController 标准桥接方式
- 参考 ChartViews.swift 中已成功的桥接模式
- 测试窗口缩放、深色模式等场景

## Migration Plan

### 阶段 1: 清理非核心功能 (低风险)

1. 删除文件:
   - HotKeysWindowController.h/.m/.xib
   - HelpWindowController.h/.m/.xib
   - CheckUpdatesWindowController.h/.m/.xib
   - CheckUpdatesHelper.h/.m
   - ChartView.h/.m (遗留实现)
   - ChartDataEntry.h/.m (遗留实现)
   - ChartDataDelegate.h (遗留实现)

2. 清理根目录孤立文件 (Xcode 已不使用):
   - 根目录的 AppDelegate.m/.h 等

3. 从 Xcode 项目中移除引用

### 阶段 2: 简化 AppDelegate (中等风险)

1. 移除菜单传感器显示代码
2. 移除热键相关代码
3. 移除更新检查相关代码
4. 移除 Pro 提示代码
5. 移除语言切换菜单

### 阶段 3: 图表功能精简 (低风险)

1. 从 ChartViews.swift 移除风扇转速图表
2. 从 ChartWindowController 移除风扇数据入口
3. 从 AppDelegate 移除风扇数据推送

### 阶段 4: 本地化精简 (中等风险)

1. 移除非 en/zh-Hans 的 .lproj 目录
2. 更新 Xcode 项目 knownRegions
3. 实现系统语言自动检测

### 阶段 5: About 窗口 SwiftUI 重写 (中等风险)

1. 创建 AboutView.swift (SwiftUI)
2. 创建 AboutWindowController.swift (桥接层)
3. 更新 Xcode 项目配置
4. 测试深色模式、窗口行为

### 阶段 6: 项目配置更新 (低风险)

1. 更新 Deployment Target: 10.13 → 10.15
2. 更新 Swift Language Version (如果需要)
3. 更新 Info.plist 最低版本说明
4. 清理无用的 Build Settings

### 回滚策略

如果迁移失败，可通过 Git 回退:
```bash
git revert HEAD~N  # N 为提交数量
git checkout .     # 恢复文件
```

保留原项目标签:
```bash
git tag v2.x-legacy  # 标记旧版本
```

## Open Questions

1. **CPU 频率读取**: 当前使用 `powermetrics` 需要 root 权限。Helper Tool 已处理，但需要确认降级模式下的行为是否正确。

2. **图表数据保留时长**: 当前保留 5 分钟历史数据，是否需要调整？用户未提及，保持不变。

3. **签名和公证**: 移除功能后是否需要重新签名和公证？是的，需要重新处理。

4. **版本号策略**: 精简后版本号如何更新？建议保持 2.x.x 系列，但需要在 Release Notes 中说明重大变更。
