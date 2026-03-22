# Privileged Helper 开发者指南

本文档说明如何配置和构建带有 Privileged Helper 的 Turbo Boost Switcher。

## 概述

Privileged Helper 是一个以 root 权限运行的守护进程，用于：
- 加载/卸载内核扩展（kext）
- 读取 SMC 传感器数据
- 避免重复输入管理员密码

## 架构

```
┌─────────────────┐                    ┌─────────────────────┐
│   GUI App       │                    │  Helper Tool        │
│   (用户进程)     │                    │  (root 权限)        │
├─────────────────┤                    ├─────────────────────┤
│ XPC Client      │◀────XPC/Mach IPC──▶│ XPC Server          │
│                 │                    │                     │
│ TurboBoostMgr   │                    │ KextManager         │
│                 │                    │ SMCManager          │
└─────────────────┘                    └─────────────────────┘
```

## 代码签名要求

### 本地开发（ad-hoc 签名）

本地开发可以使用 ad-hoc 签名：

```bash
# 在 Xcode 中设置代码签名为 "Sign to Run Locally"
# 或在 Build Settings 中设置：
CODE_SIGN_IDENTITY = -
```

### 发布签名

发布版本需要 Apple Developer ID：

1. 获取 Developer ID Application 证书
2. 配置 Provisioning Profile
3. 启用 Hardened Runtime
4. 提交公证（Notarization）

## Xcode 配置步骤

### 1. 添加 Helper Tool Target

1. File → New → Target
2. 选择 macOS → Command Line Tool
3. 命名为 `TurboBoostSwitcherHelper`
4. Bundle Identifier: `com.sunshinev.TurboBoostSwitcher.helper`

### 2. 添加 Swift Package 依赖

1. File → Add Packages
2. 添加以下 URL：
   - `https://github.com/trilemma-dev/SecureXPC.git`
   - `https://github.com/trilemma-dev/Blessed.git`
3. 选择版本 0.8.0+

### 3. 配置 Info.plist

在 App 的 Info.plist 中添加：

```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.sunshinev.TurboBoostSwitcher.helper</key>
    <string>identifier "com.sunshinev.TurboBoostSwitcher.helper" and anchor apple generic</string>
</dict>
```

### 4. 配置 Helper Tool

在 Helper Tool 的 Info.plist 中添加：

```xml
<key>SMAuthorizedClients</key>
<array>
    <string>identifier "com.sunshinev.TurboBoostSwitcher" and anchor apple generic</string>
</array>
```

### 5. 配置 LaunchDaemon

将 `HelperTool/launchd.plist` 复制到构建产物中。

## 文件结构

```
Turbo Boost Switcher/
├── HelperTool/                    # Helper Tool 源代码
│   ├── main.swift                 # 入口点
│   ├── KextManager.swift          # kext 管理
│   ├── SMCManager.swift           # SMC 读取
│   ├── launchd.plist              # LaunchDaemon 配置
│   └── Info.plist                 # Helper Bundle 配置
├── Shared/XPC/                    # 共享代码
│   └── XPCRoutes.swift            # XPC 路由定义
├── Turbo Boost Disabler/          # 主应用
│   ├── HelperInstallationManager.* # 安装管理
│   ├── XPCClientWrapper.*         # XPC 客户端
│   ├── TurboBoostManager.*        # 统一管理器
│   └── HelperStatusMenuController.* # UI 控制器
└── Package.swift                  # Swift Package 配置
```

## 测试

### 本地测试

1. 构建并运行 App
2. 点击菜单中的 "安装 Helper"
3. 输入管理员密码
4. 验证 Helper 已安装：
   ```bash
   ls /Library/PrivilegedHelperTools/
   ls /Library/LaunchDaemons/ | grep TurboBoost
   ```

### 验证 XPC 通信

```bash
# 检查 Helper 进程是否运行
ps aux | grep TurboBoostSwitcher.helper

# 检查 Mach Service
sudo launchctl list | grep TurboBoost
```

## 故障排除

### SMJobBless 失败

检查以下项目：
1. App 和 Helper 的代码签名是否匹配
2. Info.plist 中的 SMPrivilegedExecutables 是否正确
3. Helper 的 Bundle Identifier 是否匹配

### Helper 无法启动

```bash
# 检查日志
log show --predicate 'subsystem == "com.apple.xpc"' --last 5m

# 手动加载
sudo launchctl load /Library/LaunchDaemons/com.sunshinev.TurboBoostSwitcher.helper.plist
```

### XPC 连接失败

1. 确认 Helper 进程正在运行
2. 检查 Mach Service 名称是否匹配
3. 验证调用者代码签名

## 参考资料

- [SMJobBless Documentation](https://developer.apple.com/documentation/servicemanagement/1431078-smjobbless)
- [SecureXPC GitHub](https://github.com/trilemma-dev/SecureXPC)
- [Blessed GitHub](https://github.com/trilemma-dev/Blessed)
- [Apple Daemons and Agents Guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)