## 1. 修复 XPC 客户端框架兼容性问题（SecureXPC 客户端实现）

### 1.1 准备工作

- [x] 1.1.1 分析 SecureXPC 客户端 API 使用方法，参考 SharedXPC 模块
- [x] 1.1.2 检查 Xcode 项目配置，确认 Swift 支持已启用
- [x] 1.1.3 确认 SharedXPC 模块已正确集成到主应用

### 1.2 创建 Swift XPC 客户端

- [x] 1.2.1 创建 `Turbo Boost Disabler/XPCClient.swift` 文件
- [x] 1.2.2 实现 `@objc(XPCClient) public class XPCClient: NSObject`
- [x] 1.2.3 实现 `loadKext(atPath:use32Bit:completion:)` 方法
- [x] 1.2.4 实现 `unloadKext(atPath:completion:)` 方法
- [x] 1.2.5 实现 `readSMCKey(_:type:completion:)` 方法
- [x] 1.2.6 实现 `getStatus(completion:)` 方法

### 1.3 Swift/ObjC 桥接配置

- [x] 1.3.1 在 Xcode 项目中添加 Swift 文件引用
- [x] 1.3.2 配置 `DEFINES_MODULE = YES`
- [x] 1.3.3 配置 `SWIFT_OBJC_INTERFACE_HEADER_NAME`
- [ ] 1.3.4 创建桥接头（如果需要）

### 1.4 修改 TurboBoostManager 使用新客户端

- [x] 1.4.1 更新 `TurboBoostManager.m` 导入 Swift 桥接头
- [x] 1.4.2 替换 `loadKextAtPath:` 调用为 Swift XPCClient
- [x] 1.4.3 替换 `unloadKextAtPath:` 调用为 Swift XPCClient
- [x] 1.4.4 替换 `readSMCKey:` 调用为 Swift XPCClient
- [x] 1.4.5 替换 `getStatus:` 调用为 Swift XPCClient
- [x] 1.4.6 删除 AuthorizationRef 相关代码

### 1.5 清理旧代码

- [ ] 1.5.1 备份并删除 `XPCClientWrapper.m` 和 `XPCClientWrapper.h`
- [ ] 1.5.2 更新 Xcode 项目文件移除旧文件引用
- [ ] 1.5.3 更新 AGENTS.md 和 DEVELOPER.md 文档

## 2. 修复传感器数据读取和回调逻辑

- [x] 2.1 修复 `TurboBoostManager.m` 中 `readSensorsWithCompletion` 的 dispatch_group 逻辑
- [x] 2.2 确保即使部分传感器读取失败，也能返回已读取的数据
- [x] 2.3 修改 `tryReadTemperatureKeys` 方法，允许返回值为 0 的情况
- [x] 2.4 修改 `tryReadFanKeys` 方法，允许返回值为 0 的情况
- [x] 2.5 增加更多的 SMC key 作为备选（如 TC0P, TC1C, TC2C 等）
- [ ] 2.6 验证传感器数据正确传递到 `AppDelegate` 的 `updateSensorUIWithTemperature`

## 3. 增强调试日志和错误处理

- [x] 3.1 在 `TurboBoostManager` 的关键路径添加详细日志
- [x] 3.2 在 XPC 调用开始和结束时添加日志
- [x] 3.3 在传感器读取的每个 key 尝试后添加日志
- [x] 3.4 在状态栏更新时添加日志，显示当前状态
- [x] 3.5 添加 XPC 连接状态检查和错误处理
- [x] 3.6 添加 Helper 可用性检查日志

## 4. 验证 UI 更新在主线程执行

- [ ] 4.1 检查 `AppDelegate.m` 中所有 UI 更新操作是否在主线程
- [ ] 4.2 验证 `updateStatus` 方法的调用时机
- [ ] 4.3 验证 `updateSensorValues` 方法的调用时机
- [ ] 4.4 确保 `disableTurboBoost` 和 `enableTurboBoost` 的 completion 在主线程执行
- [ ] 4.5 检查图表窗口的数据更新是否在主线程

## 5. 测试和验证

- [x] 5.1 构建项目，确保无编译错误
- [x] 5.2 测试禁用 Turbo Boost 后状态栏图标是否变化
- [x] 5.3 测试启用 Turbo Boost 后状态栏图标是否变化
- [x] 5.4 测试图表窗口中温度数据是否更新
- [x] 5.5 测试图表窗口中风扇转速数据是否更新
- [x] 5.6 检查控制台日志输出，确认 XPC 通信正常
- [x] 5.7 测试降级模式（非 XPC）是否仍然正常工作

## 6. 关键修复总结

### 6.1 XPC 框架不兼容问题（核心问题）- 已修复
- **问题**: 客户端使用 NSXPCConnection (ObjC)，服务端使用 SecureXPC (Swift)，两者协议不兼容
- **原因分析**:
  - NSXPCConnection 使用 NSSecureCoding + Protocol-based API
  - SecureXPC 使用 Codable + Route-based API
  - 两者消息格式完全不同，无法互通
- **解决方案**: 已创建 Swift XPC 客户端使用 SecureXPC 库
  - 创建了 `XPCClient.swift` 使用 SecureXPC
  - 更新了 `TurboBoostManager.m` 使用新的 Swift 客户端
  - 删除了所有 AuthorizationRef 相关代码

### 6.2 最终目标
- [x] 实现 SecureXPC 客户端，替换 NSXPCConnection
- [x] 实现真正的免密码操作
- [x] 删除 AuthorizationRef 降级模式代码

### 6.3 崩溃修复
- **问题**: `updateSensorUIWithTemperature` 中 `tempString` 可能为 nil 导致崩溃
- **修复**: 确保 `tempString` 始终有值（即使是 "N/A"）

### 6.4 Kext 路径问题
- **问题**: `pathForResource:ofType:` 找不到 kext 文件
- **修复**: 添加 `getKextPath` 方法，使用与 SystemCommands 相同的路径逻辑

## 8. 移除 AuthorizationRef 降级模式

### 8.1 需要删除的代码

- [x] 8.1.1 删除 `TurboBoostManager.m` 中的 `refreshAuthRef` 方法
- [x] 8.1.2 删除 `TurboBoostManager.m` 中的 `_authorizationRef` 属性
- [x] 8.1.3 删除 `TurboBoostManager.m` 中的 `AuthorizationRef` 导入
- [x] 8.1.4 删除 `TurboBoostManager.m` 中的 `dealloc` AuthorizationFree 调用

### 8.2 需要删除的日志

- [x] 8.2.1 删除 "暂时使用降级模式，因为 XPC 框架不兼容" 日志
- [x] 8.2.2 删除 "Helper 未安装，使用降级模式" 日志
- [x] 8.2.3 删除 "Failed to create authorization" 日志

### 8.3 需要删除的注释

- [x] 8.3.1 删除所有提及 "降级模式" 的注释
- [x] 8.3.2 更新所有提及 "AuthorizationRef" 的注释

## 7. 修复效果验证

### 7.1 验证 XPC 客户端工作正常

- [ ] 7.1.1 日志显示 `[XPCClient] Connected to Helper via SecureXPC`
- [ ] 7.1.2 禁用 Turbo Boost 无需输入密码
- [ ] 7.1.3 启用 Turbo Boost 无需输入密码
- [ ] 7.1.4 传感器数据通过 XPC 读取（非 SystemCommands）

### 7.2 预期日志输出

```
[XPCClient] loadKextAtPath: /path/to/kext, use32Bit: NO
[XPCClient] loadKextAtPath callback: success=YES, error=nil
[AppDelegate] Turbo Boost disabled successfully
[AppDelegate] updateStatus: isTurboBoostEnabled=NO
```

### 7.3 降级模式完全移除

- [ ] 7.3.1 `TurboBoostManager.m` 中无 AuthorizationRef 代码
- [ ] 7.3.2 日志无 "使用降级模式" 或 "AuthorizationRef" 字样
- [ ] 7.3.3 `SystemCommands` 仅用于传感器读取（不再用于 kext 操作）
