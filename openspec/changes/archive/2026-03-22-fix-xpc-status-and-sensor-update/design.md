## Context

当前项目使用 XPC (Helper Tool) 模式来管理 Turbo Boost 的启用/禁用，以及读取传感器数据（温度、风扇转速）。但存在以下问题：

1. **🔴 XPC 框架不兼容**：主应用使用 NSXPCConnection (ObjC)，Helper Tool 使用 SecureXPC (Swift)，两者无法通信
2. **状态栏不更新**：点击禁用 Turbo Boost 后，日志显示"使用 XPC (Helper)"，但状态栏图标和菜单文本没有变化
3. **图表传感器数据不更新**：图表窗口中只有 CPU 负载更新，温度和风扇转速数据不更新

### 🔴 核心问题：XPC 框架不兼容详解

```
┌─────────────────────────────────────────────────────────────────┐
│                    架构图：两套不兼容的 XPC 实现                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   主应用 (Objective-C)              Helper Tool (Swift)          │
│   ════════════════════════         ══════════════════════        │
│                                                                  │
│   XPCClientWrapper.m               main.swift                    │
│   ┌─────────────────────┐          ┌─────────────────────┐     │
│   │ NSXPCConnection     │          │ SecureXPC.XPCServer │     │
│   │ • Protocol-based    │  ✗       │ • Route-based       │     │
│   │ • ObjC selectors    │  不兼容  │ • Codable structs   │     │
│   │ • NSSecureCoding    │          │ • XPCRoute          │     │
│   └─────────────────────┘          └─────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**问题根源**：
- `NSXPCConnection` 期望 ObjC 协议 + NSSecureCoding 序列化
- `SecureXPC` 期望 Swift Codable 类型 + 自定义路由格式

**当前 workaround**：代码 fallback 到 AuthorizationRef，每次操作都需要输入密码。

### 问题 1：传感器读取逻辑缺陷

在 `TurboBoostManager.m` 的 `readSensorsWithCompletion` 方法（第127-187行）中：

```objc
- (void)readSensorsWithCompletion:(SensorReadCompletionBlock)completion {
    if (self.useHelper) {
        dispatch_group_t group = dispatch_group_create();
        // ... 温度和风扇读取代码 ...
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (completion) {
                NSError *error = nil;
                if (!tempSuccess && !fanSuccess) {
                    // 只有两者都失败时才报告错误
                    NSString *errorMsg = [NSString stringWithFormat:@"Failed to read sensors. Temp error: %@, Fan error: %@", tempError ?: @"unknown", fanError ?: @"unknown"];
                    error = [NSError errorWithDomain:@"TurboBoostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
                }
                completion(tempSuccess || fanSuccess, temperature, fanSpeed, error);
            }
        });
    }
}
```

**问题**：`dispatch_group_notify` 的回调中，如果 `tempSuccess` 和 `fanSuccess` 都为 `false`，completion 仍然会被调用，但传入的 `temperature` 和 `fanSpeed` 都是 0，这会导致 UI 显示 "N/A"。

### 问题 2：SMC 读取失败

在 `HelperTool/SMCManager.swift` 的 `readSMCKey` 方法中，如果 SMC 读取失败，返回的 `value` 为 0。在 `TurboBoostManager.m` 的 `tryReadTemperatureKeys` 和 `tryReadFanKeys` 方法中：

```objc
if (success && value > 0) {
    // 成功
} else {
    // 失败，尝试下一个 key
}
```

**问题**：如果所有 SMC key 都读取失败，最终 completion 会被调用，但 `tempSuccess` 为 `false`，导致 `AppDelegate` 中的 `updateSensorUIWithTemperature` 方法显示 "N/A"。

### 问题 3：状态栏更新时机

在 `AppDelegate.m` 的 `disableTurboBoost` 方法中：

```objc
- (void) disableTurboBoost {
    [[TurboBoostManager sharedManager] disableTurboBoostWithCompletion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success && error) {
                NSLog(@"Failed to disable Turbo Boost: %@", error.localizedDescription);
            }
            [self updateStatus];
        });
    }];
}
```

**问题**：代码逻辑看起来正确，但可能存在 XPC 回调未被正确执行的问题，或者 `TurboBoostManager` 中的 `isTurboBoostEnabled` 属性没有被正确更新。

## Goals / Non-Goals

**Goals:**
- 修复 XPC 模式下禁用/启用 Turbo Boost 后状态栏不更新的问题
- 修复图表窗口中温度和风扇转速数据不更新的问题
- 增加调试日志，帮助诊断问题
- 确保所有 UI 更新都在主线程执行

**Non-Goals:**
- 不修改降级模式（非 XPC）的逻辑
- 不修改图表 UI 的外观
- 不添加新的功能特性

## Decisions

### Decision 1: 修复传感器读取回调逻辑

**选择**：修改 `readSensorsWithCompletion` 方法，确保即使部分传感器读取失败，也能返回已读取的数据。

**理由**：当前逻辑要求 `tempSuccess || fanSuccess` 为 `true` 才返回成功，但实际上应该分别处理温度和风扇的读取结果，即使其中一个失败，另一个的数据仍然有用。

### Decision 2: 增加 XPC 操作完成后的状态刷新

**选择**：在 `TurboBoostManager` 的 `disableTurboBoostWithCompletion` 和 `enableTurboBoostWithCompletion` 方法中，确保 `isTurboBoostEnabled` 属性在 XPC 回调中被正确更新。

**理由**：`isTurboBoostEnabled` 是状态栏更新的唯一数据源，必须确保它在 XPC 操作完成后被正确设置。

### Decision 3: 增加详细的调试日志

**选择**：在关键路径上增加 NSLog 输出，包括：
- XPC 调用开始和结束
- 传感器读取的每个 key 的尝试结果
- 状态栏更新时的当前状态

**理由**：帮助用户和开发者诊断问题，特别是在不同硬件配置上的兼容性问题。

### Decision 4: 修复 SMC 读取值的判断逻辑

**选择**：修改 `tryReadTemperatureKeys` 和 `tryReadFanKeys` 方法，允许返回值为 0 的情况（某些传感器可能确实返回 0）。

**理由**：当前逻辑 `value > 0` 可能过于严格，某些合法的传感器读数可能为 0（例如风扇停止时）。

### Decision 5: 使用 SecureXPC 替换 NSXPCConnection

**选择**：创建新的 Swift XPC 客户端，使用 SecureXPC 库实现与 Helper Tool 的通信。

**架构设计**：

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          新架构：SecureXPC 客户端                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  主应用 (Objective-C)                                                     │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  TurboBoostManager.m                                               │ │
│  │       │                                                           │ │
│  │       ▼                                                           │ │
│  │  [Swift XPC Client via ObjC Bridge]                               │ │
│  │       │                                                           │ │
│  │       │ @objc(XPCClient) public class XPCClient: NSObject          │ │
│  │       │   ├── loadKext()                                          │ │
│  │       │   ├── unloadKext()                                        │ │
│  │       │   ├── readSMCKey()                                        │ │
│  │       │   └── getStatus()                                          │ │
│  └───────┼────────────────────────────────────────────────────────────┘ │
│          │                                                             │
│          │ Swift/ObjC Bridge (XPCClient-Swift.h)                       │
│          ▼                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  XPCClient.swift                                                   │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │ 使用 SecureXPC.XPCClient                                     │  │ │
│  │  │ • forMachService(named:criteria:)                            │  │ │
│  │  │ • client.sendMessage(to: XPCRoutes.xxx)                      │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│          │                                                             │
│          │ XPC/Mach IPC                                                │
│          ▼                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  Helper Tool (Swift + SecureXPC) - 无需修改                         │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │ XPCServer.forMachService(...)                                │  │ │
│  │  │ • XPCRoutes.loadKext                                         │  │ │
│  │  │ • XPCRoutes.unloadKext                                       │  │ │
│  │  │ • XPCRoutes.readSMC                                          │  │ │
│  │  │ • XPCRoutes.getStatus                                        │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**实现要点**：

1. **创建 `XPCClient.swift`**：
   ```swift
   import Foundation
   import SecureXPC
   import SharedXPC

   @objc(XPCClient)
   public class XPCClient: NSObject {
       private let client: XPCClientType
       
       @objc public override init() {
           self.client = XPCClient.forMachService(
               named: HelperConstants.machServiceName,
               withServerRequirement: .sameTeamIdentifier
           )
           super.init()
       }
       
       @objc public func loadKext(atPath: String, use32Bit: Bool, completion: @escaping (Bool, String?) -> Void) {
           let request = KextLoadRequest(kextPath: atPath, use32Bit: use32Bit)
           Task {
               do {
                   let response = try await client.sendMessage(request, to: XPCRoutes.loadKext)
                   DispatchQueue.main.async {
                       completion(response.success, response.errorMessage)
                   }
               } catch {
                   DispatchQueue.main.async {
                       completion(false, error.localizedDescription)
                   }
               }
           }
       }
       
       // ... 其他方法类似
   }
   ```

2. **ObjC 调用方式**：
   ```objc
   // TurboBoostManager.m
   #import "Turbo_Boost_Switcher-Swift.h"  // Xcode 自动生成
   
   XPCClient *client = [[XPCClient alloc] init];
   [client loadKextAtPath:path use32Bit:NO completion:^(BOOL success, NSString *error) {
       // ...
   }];
   ```

3. **Xcode 项目配置**：
   - 添加 Swift 文件到项目中
   - 设置 `SWIFT_VERSION` >= 5.0
   - 设置 `DEFINES_MODULE = YES`
   - 添加 `Turbo_Boost_Switcher-Bridging-Header.h`（如需要）

**理由**：
- SecureXPC 是 Helper Tool 使用的库，保持一致可以确保通信兼容
- Swift/ObjC 互操作成熟，Xcode 自动生成桥接头
- 最小化改动：只需创建新文件，修改 TurboBoostManager

### Decision 6: 移除 AuthorizationRef 降级模式

**选择**：在 SecureXPC 客户端实现完成后，删除 AuthorizationRef 相关代码。

**理由**：
- AuthorizationRef 已被 Apple 标记为废弃
- 使用 SecureXPC + Helper Tool 是 Apple 推荐的安全方案
- 移除降级代码可以简化代码维护

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 修改可能引入新的 bug | 保持修改最小化，只修复已知问题，不进行重构 |
| SMC key 在某些硬件上不可用 | 继续尝试多个 key，增加更多的备选 key |
| XPC 连接不稳定 | 增加连接状态检查，失败时自动重连 |
| 日志过多影响性能 | 只在关键路径添加日志，避免在循环中频繁输出 |

## Migration Plan

无需迁移，这是一个 bug 修复，不涉及数据模型或配置文件的变更。

## Open Questions

1. 是否需要增加更多的 SMC temperature key 作为备选？
2. 是否需要实现 XPC 连接失败时的自动降级机制？
3. 是否需要增加用户提示，当传感器读取失败时显示警告？
