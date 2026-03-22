import Foundation
import SharedXPC

public class KextManager {
    public static let shared = KextManager()
    
    public private(set) var isLoaded: Bool = false
    
    private init() {}
    
    public func loadKext(at path: String, use32Bit: Bool = false) -> KextLoadResponse {
        let kextPath = use32Bit ? path.replacingOccurrences(of: ".kext", with: ".32bits.kext") : path
        
        let task = Process()
        // Helper 以 root 权限运行，无需 sudo
        task.executableURL = URL(fileURLWithPath: "/sbin/kextload")
        task.arguments = ["-v", kextPath]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                isLoaded = true
                return KextLoadResponse(success: true)
            } else {
                return KextLoadResponse(success: false, errorMessage: "kextload exited with status \(task.terminationStatus)")
            }
        } catch {
            return KextLoadResponse(success: false, errorMessage: error.localizedDescription)
        }
    }
    
    public func unloadKext(at path: String) -> KextUnloadResponse {
        let task = Process()
        // Helper 以 root 权限运行，无需 sudo
        task.executableURL = URL(fileURLWithPath: "/sbin/kextunload")
        task.arguments = ["-v", path]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                isLoaded = false
                return KextUnloadResponse(success: true)
            } else {
                return KextUnloadResponse(success: false, errorMessage: "kextunload exited with status \(task.terminationStatus)")
            }
        } catch {
            return KextUnloadResponse(success: false, errorMessage: error.localizedDescription)
        }
    }
    
    public func checkKextStatus() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/kextstat")
        task.arguments = ["-l"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("[KextManager] kextstat output length: \(output.count)")
                let found = output.contains("DisableTurboBoost")
                print("[KextManager] checkKextStatus: \(found ? "LOADED" : "NOT LOADED")")
                isLoaded = found
            } else {
                print("[KextManager] Failed to decode kextstat output")
                isLoaded = false
            }
        } catch {
            print("[KextManager] checkKextStatus error: \(error.localizedDescription)")
            isLoaded = false
        }
        
        return isLoaded
    }
}