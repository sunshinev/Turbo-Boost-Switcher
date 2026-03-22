import Foundation
import SecureXPC

// MARK: - XPC Routes

/// XPC 路由定义 - GUI App 和 Helper Tool 共享
public enum XPCRoutes {
    
    // MARK: - Kext Routes
    
    /// 加载内核扩展
    public static let loadKext = XPCRoute.named("kext", "load")
        .withMessageType(KextLoadRequest.self)
        .withReplyType(KextLoadResponse.self)
    
    /// 卸载内核扩展
    public static let unloadKext = XPCRoute.named("kext", "unload")
        .withMessageType(KextUnloadRequest.self)
        .withReplyType(KextUnloadResponse.self)
    
    // MARK: - SMC Routes
    
    /// 读取 SMC 值
    public static let readSMC = XPCRoute.named("smc", "read")
        .withMessageType(SMCReadRequest.self)
        .withReplyType(SMCReadResponse.self)
    
    // MARK: - Status Routes
    
    /// 获取状态
    public static let getStatus = XPCRoute.named("status", "get")
        .withMessageType(EmptyRequest.self)
        .withReplyType(StatusResponse.self)
}

// MARK: - Kext Request/Response Types

/// Kext 加载请求
public struct KextLoadRequest: Codable {
    public let kextPath: String
    public let use32Bit: Bool
    
    public init(kextPath: String, use32Bit: Bool = false) {
        self.kextPath = kextPath
        self.use32Bit = use32Bit
    }
}

/// Kext 加载响应
public struct KextLoadResponse: Codable {
    public let success: Bool
    public let errorMessage: String?
    
    public init(success: Bool, errorMessage: String? = nil) {
        self.success = success
        self.errorMessage = errorMessage
    }
}

/// Kext 卸载请求
public struct KextUnloadRequest: Codable {
    public let kextPath: String
    
    public init(kextPath: String) {
        self.kextPath = kextPath
    }
}

/// Kext 卸载响应
public struct KextUnloadResponse: Codable {
    public let success: Bool
    public let errorMessage: String?
    
    public init(success: Bool, errorMessage: String? = nil) {
        self.success = success
        self.errorMessage = errorMessage
    }
}

// MARK: - SMC Request/Response Types

/// SMC 读取请求
public struct SMCReadRequest: Codable {
    public let key: String
    public let type: SMCReadType
    
    public init(key: String, type: SMCReadType) {
        self.key = key
        self.type = type
    }
}

/// SMC 读取类型
public enum SMCReadType: String, Codable {
    case temperature
    case fanSpeed
    case frequency
}

/// SMC 读取响应
public struct SMCReadResponse: Codable {
    public let success: Bool
    public let value: Float?
    public let errorMessage: String?
    
    public init(success: Bool, value: Float? = nil, errorMessage: String? = nil) {
        self.success = success
        self.value = value
        self.errorMessage = errorMessage
    }
}

// MARK: - Status Request/Response Types

/// 空请求
public struct EmptyRequest: Codable {
    public init() {}
}

/// 状态响应
public struct StatusResponse: Codable {
    public let isKextLoaded: Bool
    public let helperVersion: String
    public let turboBoostEnabled: Bool
    
    public init(isKextLoaded: Bool, helperVersion: String, turboBoostEnabled: Bool) {
        self.isKextLoaded = isKextLoaded
        self.helperVersion = helperVersion
        self.turboBoostEnabled = turboBoostEnabled
    }
}

// MARK: - Helper Constants

/// Helper Tool 常量
public enum HelperConstants {
    /// Helper Tool Mach Service 名称
    public static let machServiceName = "com.sunshinev.TurboBoostSwitcher.helper"
    
    /// Helper Tool Bundle Identifier
    public static let bundleIdentifier = "com.sunshinev.TurboBoostSwitcher.helper"
    
    /// Helper Tool 版本
    public static let version = "1.0.0"
}