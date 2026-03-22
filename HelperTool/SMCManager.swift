import Foundation
import IOKit
import SharedXPC

public class SMCManager {
    public static let shared = SMCManager()
    
    private init() {}
    
    public func readValue(key: String, type: SMCReadType) -> SMCReadResponse {
        switch type {
        case .temperature:
            return readTemperature(key: key)
        case .fanSpeed:
            return readFanSpeed(key: key)
        case .frequency:
            return readFrequency()
        }
    }
    
    private func readTemperature(key: String) -> SMCReadResponse {
        let conn = openSMCConnection()
        defer { closeSMCConnection(conn) }
        
        var value: Float = 0
        let result = readSMCKey(conn: conn, key: key, value: &value)
        
        if result == kIOReturnSuccess {
            print("[SMCManager] Temperature key '\(key)' read success: \(value)")
            return SMCReadResponse(success: true, value: value)
        } else {
            let errorMsg = "Failed to read temperature key '\(key)': IOKit error \(result)"
            print("[SMCManager] \(errorMsg)")
            return SMCReadResponse(success: false, errorMessage: errorMsg)
        }
    }
    
    private func readFanSpeed(key: String) -> SMCReadResponse {
        let conn = openSMCConnection()
        defer { closeSMCConnection(conn) }
        
        var value: Float = 0
        let result = readSMCKey(conn: conn, key: key, value: &value)
        
        if result == kIOReturnSuccess {
            print("[SMCManager] Fan key '\(key)' read success: \(value)")
            return SMCReadResponse(success: true, value: value)
        } else {
            let errorMsg = "Failed to read fan key '\(key)': IOKit error \(result)"
            print("[SMCManager] \(errorMsg)")
            return SMCReadResponse(success: false, errorMessage: errorMsg)
        }
    }
    
    private func readFrequency() -> SMCReadResponse {
        let task = Process()
        // Helper 以 root 运行，不需要 sudo
        task.executableURL = URL(fileURLWithPath: "/usr/bin/powermetrics")
        task.arguments = ["-n", "1", "-i", "10"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // 匹配 "System Average frequency as fraction of nominal: 131.82% (2900.01 Mhz)"
                let pattern = #"System Average frequency.*?\((\d+\.?\d*)\s*Mhz\)"#
                if let range = output.range(of: pattern, options: .regularExpression) {
                    let matched = String(output[range])
                    // 提取数字部分
                    let numPattern = #"\((\d+\.?\d*)\s*Mhz\)"#
                    if let numRange = matched.range(of: numPattern, options: .regularExpression) {
                        let numStr = matched[numRange]
                            .replacingOccurrences(of: "(", with: "")
                            .replacingOccurrences(of: " Mhz)", with: "")
                            .replacingOccurrences(of: ")", with: "")
                        if let freqMHz = Float(numStr) {
                            let freqGHz = freqMHz / 1000.0
                            print("[SMCManager] Frequency read success: \(freqMHz) MHz = \(freqGHz) GHz")
                            return SMCReadResponse(success: true, value: freqGHz)
                        }
                    }
                }
                print("[SMCManager] Could not parse frequency from powermetrics output")
                print("[SMCManager] Output preview: \(String(output.prefix(500)))")
            }
            return SMCReadResponse(success: false, errorMessage: "Could not parse frequency")
        } catch {
            print("[SMCManager] Frequency read failed: \(error.localizedDescription)")
            return SMCReadResponse(success: false, errorMessage: error.localizedDescription)
        }
    }
    
    private func openSMCConnection() -> io_connect_t {
        var masterPort: mach_port_t = 0
        var conn: io_connect_t = 0
        
        IOMasterPort(mach_port_t(MACH_PORT_NULL), &masterPort)
        
        let matchingDict = IOServiceMatching("AppleSMC")
        var iterator: io_iterator_t = 0
        IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
        let device = IOIteratorNext(iterator)
        
        IOObjectRelease(iterator)
        
        if device != 0 {
            IOServiceOpen(device, mach_task_self_, 0, &conn)
            IOObjectRelease(device)
            print("[SMCManager] SMC connection opened: \(conn)")
        } else {
            print("[SMCManager] ERROR: AppleSMC device not found - this Mac may not have SMC")
        }
        
        return conn
    }
    
    private func closeSMCConnection(_ conn: io_connect_t) {
        if conn != 0 {
            IOServiceClose(conn)
        }
    }
    
    private func readSMCKey(conn: io_connect_t, key: String, value: inout Float) -> kern_return_t {
        let keyBytes = [UInt8](key.utf8)
        var inputStruct = SMCKeyData_t()
        var outputStruct = SMCKeyData_t()
        
        inputStruct.key = _strtoul(keyBytes, 4, 16)
        inputStruct.data8 = SMC_CMD_READ_KEYINFO
        
        var inputSize = MemoryLayout<SMCKeyData_t>.size
        var outputSize = MemoryLayout<SMCKeyData_t>.size
        
        var result = IOConnectCallStructMethod(
            conn,
            UInt32(KERNEL_INDEX_SMC),
            &inputStruct,
            inputSize,
            &outputStruct,
            &outputSize
        )
        
        if result == kIOReturnSuccess {
            inputStruct.keyInfo = outputStruct.keyInfo
            inputStruct.data8 = SMC_CMD_READ_BYTES
            
            result = IOConnectCallStructMethod(
                conn,
                UInt32(KERNEL_INDEX_SMC),
                &inputStruct,
                inputSize,
                &outputStruct,
                &outputSize
            )
            
            if result == kIOReturnSuccess {
                let data = outputStruct.bytes
                if outputStruct.keyInfo.dataSize == 2 {
                    value = Float(UInt16(data.0) << 8 | UInt16(data.1)) / 256.0
                } else if outputStruct.keyInfo.dataSize == 4 {
                    value = Float(bitPattern: UInt32(data.0) << 24 | UInt32(data.1) << 16 | UInt32(data.2) << 8 | UInt32(data.3))
                }
            }
        }
        
        return result
    }
    
    private func _strtoul(_ bytes: [UInt8], _ size: Int, _ base: Int) -> UInt32 {
        var total: UInt32 = 0
        for i in 0..<size {
            if base == 16 {
                total += UInt32(bytes[i]) << UInt32((size - 1 - i) * 8)
            } else {
                total += UInt32(bytes[i]) << UInt32((size - 1 - i) * 8)
            }
        }
        return total
    }
}

private let KERNEL_INDEX_SMC: Int32 = 2
private let SMC_CMD_READ_KEYINFO: UInt8 = 9
private let SMC_CMD_READ_BYTES: UInt8 = 5

// MARK: - SMC Data Structures (matching C layout exactly)
// Total size must be 76 bytes to match the C struct in smc.h

private struct SMCVersion_t {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    // Size: 4 bytes
}

private struct SMCPLimitData_t {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
    // Size: 16 bytes
}

private struct SMCKeyInfo_t {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
    var _padding: (UInt8, UInt8, UInt8) = (0, 0, 0)  // 3 bytes padding to match C struct (12 bytes total)
}

private struct SMCKeyData_t {
    var key: UInt32 = 0                                          // offset 0, size 4
    var vers: SMCVersion_t = SMCVersion_t()                      // offset 4, size 4
    var pLimitData: SMCPLimitData_t = SMCPLimitData_t()          // offset 8, size 16
    var keyInfo: SMCKeyInfo_t = SMCKeyInfo_t()                   // offset 24, size 12
    var result: UInt8 = 0                                        // offset 36, size 1
    var status: UInt8 = 0                                        // offset 37, size 1
    var data8: UInt8 = 0                                         // offset 38, size 1
    var _padding: UInt8 = 0                                      // offset 39, size 1 (padding before data32)
    var data32: UInt32 = 0                                       // offset 40, size 4
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = 
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)       // offset 44, size 32
    // Total: 76 bytes
}