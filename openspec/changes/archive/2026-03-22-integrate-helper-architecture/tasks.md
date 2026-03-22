## 1. 修复 Helper Tool (KextManager.swift)

- [x] 1.1 修复 `KextManager.loadKext()` — 移除 `sudo`，直接调用 `/sbin/kextload`
- [x] 1.2 修复 `KextManager.unloadKext()` — 移除 `sudo`，直接调用 `/sbin/kextunload`
- [x] 1.3 验证修复后的 Helper 可独立加载/卸载 kext

## 2. 重构 AppDelegate 导入和初始化

- [x] 2.1 在 `AppDelegate.m` 中导入 `TurboBoostManager.h`
- [x] 2.2 在 `awakeFromNib` 中初始化 `TurboBoostManager` 并检查 Helper 状态
- [x] 2.3 添加 `TurboBoostManager` 的状态变化回调处理

## 3. 重构 Turbo Boost 启用/禁用方法

- [x] 3.1 重构 `disableTurboBoost` — 调用 `TurboBoostManager.disableTurboBoostWithCompletion:`
- [x] 3.2 重构 `enableTurboBoost` — 调用 `TurboBoostManager.enableTurboBoostWithCompletion:`
- [x] 3.3 更新 IBAction `enableTurboBoost:` 方法以使用新的异步 API
- [x] 3.4 移除或保留 `refreshAuthRef` 方法（仅在降级模式下使用）

## 4. 重构系统唤醒处理

- [x] 4.1 修改 `receiveWakeNote:` — 使用 `TurboBoostManager` 进行 kext 重载
- [x] 4.2 添加异步重载完成后的状态更新回调

## 5. 重构传感器数据读取

- [x] 5.1 修改 `updateSensorValues` — 使用 `TurboBoostManager.readSensorsWithCompletion:` 或单独的温度/风扇读取方法
- [x] 5.2 处理异步回调中的 UI 更新

## 6. 重构 CPU 频率读取

- [x] 6.1 检查 `XPCRoutes.swift` 是否有 `readFrequency` 路由，如无则添加
- [x] 6.2 修改 `readCpuFrequency` — 使用 `TurboBoostManager` 或直接调用 XPC
- [x] 6.3 处理异步回调中的图表数据更新

## 7. 测试验证

- [ ] 7.1 测试 Helper 已安装时的禁用/启用 Turbo Boost（无密码）
- [ ] 7.2 测试 Helper 未安装时的降级行为（有密码）
- [ ] 7.3 测试系统唤醒后的自动重载行为
- [ ] 7.4 测试图表窗口的 CPU 频率读取（无密码弹窗）
- [ ] 7.5 测试传感器数据定时更新（无密码弹窗）

## 8. 代码清理

- [x] 8.1 移除 `AppDelegate.m` 中不再使用的 `authorizationRef` 属性（如完全迁移）
- [x] 8.2 确保降级模式下 `authorizationRef` 仍可正常工作
- [x] 8.3 更新代码注释和文档