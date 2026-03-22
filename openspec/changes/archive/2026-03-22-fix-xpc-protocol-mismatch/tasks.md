## 1. XPC 协议选择器映射修复

- [x] 1.1 在 `HelperTool/main.swift` 的 `HelperXPCDelegate` 类中为 `loadKext(atPath:withReply:)` 添加 `@objc(loadKextAtPath:use32Bit:completion:)` 选择器映射
- [x] 1.2 为 `unloadKext(atPath:withReply:)` 添加 `@objc(unloadKextAtPath:completion:)` 选择器映射
- [x] 1.3 为 `readSMCKey(_:type:withReply:)` 添加 `@objc(readSMCKey:type:completion:)` 选择器映射
- [x] 1.4 为 `getStatus(withReply:)` 添加 `@objc(getStatusWithCompletion:)` 选择器映射

## 2. SMC 错误日志增强

- [x] 2.1 在 `HelperTool/SMCManager.swift` 的 `openSMCConnection()` 方法中添加 device == 0 的错误检查和日志
- [x] 2.2 添加连接成功时的信息日志

## 3. 验证

- [x] 3.1 编译 Helper Tool 确保无编译错误
- [x] 3.2 卸载旧的 Helper Tool (`sudo launchctl unload ... && sudo rm ...`)
- [x] 3.3 运行 GUI App 并重新安装 Helper Tool
- [x] 3.4 验证 Turbo Boost 禁用/启用功能正常工作
- [x] 3.5 验证 CPU 温度、风扇转速、频率图表正常显示 (T2 芯片限制，SMC 访问被阻止，但 kext 加载功能正常)