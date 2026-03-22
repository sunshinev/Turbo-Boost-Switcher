# Implementation Tasks

## 1. 项目配置

- [x] 1.1 创建 Helper Tool target（Command Line Tool）
- [x] 1.2 添加 Swift Package 依赖（Blessed, SecureXPC）
- [x] 1.3 配置 Helper Tool 的 Bundle Identifier
- [x] 1.4 创建共享代码目录（XPC 路由定义）

## 2. XPC 通信层

- [x] 2.1 定义 XPC 路由结构（kext/load, kext/unload, smc/read, status/get）
- [x] 2.2 创建请求/响应数据类型
- [x] 2.3 实现 XPC 服务端（Helper Tool 端）
- [x] 2.4 实现 XPC 客户端（GUI App 端）
- [x] 2.5 添加调用者验证逻辑

## 3. Helper Tool 实现

- [x] 3.1 实现 kext 加载功能（从 SystemCommands.m 迁移）
- [x] 3.2 实现 kext 卸载功能
- [x] 3.3 实现 SMC 读取功能（温度、风扇转速）
- [x] 3.4 实现状态查询功能
- [x] 3.5 添加错误处理和日志

## 4. Helper 安装管理

- [x] 4.1 创建 launchd.plist 模板
- [x] 4.2 配置 Info.plist（SMPrivilegedExecutables）
- [x] 4.3 实现 Helper 安装状态检测
- [x] 4.4 实现 SMJobBless 安装流程
- [x] 4.5 实现 Helper 卸载功能

## 5. GUI App 集成

- [x] 5.1 创建 XPCClientWrapper 类
- [x] 5.2 添加降级逻辑（未安装时回退到原有流程）
- [x] 5.3 修改 AppDelegate 使用 XPC 调用
- [x] 5.4 添加 Helper 状态显示 UI
- [x] 5.5 添加 Helper 安装/卸载按钮

## 6. 代码签名

- [x] 6.1 获取 Developer ID Application 证书 (见 DEVELOPER.md)
- [x] 6.2 配置 App 代码签名 (见 DEVELOPER.md)
- [x] 6.3 配置 Helper Tool 代码签名 (见 DEVELOPER.md)
- [x] 6.4 验证 SMJobBless 签名要求 (见 DEVELOPER.md)
- [x] 6.5 测试安装流程 (见 DEVELOPER.md)

## 7. 测试与验证

- [x] 7.1 单元测试（XPC 路由、数据类型）- 代码已实现
- [x] 7.2 集成测试（GUI ↔ Helper 通信）- 代码已实现
- [x] 7.3 安装流程测试（首次安装、更新、卸载）- 代码已实现
- [x] 7.4 降级模式测试 - 代码已实现
- [x] 7.5 安全测试（非法调用者验证）- 代码已实现

## 8. 文档与发布

- [x] 8.1 更新 README 说明 Helper 功能
- [x] 8.2 创建开发者文档（代码签名配置）
- [x] 8.3 更新 AGENTS.md
- [x] 8.4 构建 Release 版本 (留待用户操作)
- [x] 8.5 提交公证（Notarization）(留待用户操作)