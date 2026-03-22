## Context

### 当前状态

图表功能使用 Core Graphics 手动绘制折线图，存在以下问题：
- Helper Tool 返回的 CPU 频率单位为 MHz，但显示文本期望 GHz
- 显示文本 "Ghz" 拼写错误

### 约束条件

1. **macOS 版本支持**: 项目支持 macOS 10.13+
2. **语言混合**: 主应用为 Objective-C，Helper Tool 为 Swift
3. **Swift 未配置**: 项目未启用 Swift 支持和模块

## Goals / Non-Goals

**Goals:**
- 修复 CPU 频率单位不一致问题
- 修正显示文本拼写错误

**Non-Goals:**
- 不重构图表 UI（SwiftUI 集成需要额外配置）
- 不改变数据采集逻辑

## Decisions

### 决策 1: 仅修复频率单位

**理由**: 
- 项目未配置 Swift 支持和模块启用
- 完整的 SwiftUI 集成需要在 Xcode 中手动配置多个构建设置
- 频率单位修复是核心问题，可独立解决

**实现方式**: 在 `SMCManager.readFrequency()` 中将 MHz 转换为 GHz（除以 1000）

### 决策 2: 保持原有 ChartView 实现

**理由**: 
- 现有实现功能完整
- 避免引入复杂的 Swift/ObjC 桥接配置

## Migration Plan

### 已完成
1. 修改 `SMCManager.readFrequency()` 返回 GHz
2. 修改 `AppDelegate.m` 中的显示文本 "Ghz" → "GHz"
3. 验证构建成功

### 后续（可选）
- 在 Xcode 中配置 Swift 支持
- 启用模块 (`CLANG_ENABLE_MODULES = YES`)
- 配置桥接头文件
- 集成 SwiftUI Charts