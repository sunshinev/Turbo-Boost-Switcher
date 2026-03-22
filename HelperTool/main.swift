import Foundation
import SharedXPC

@objc public protocol ObjCHelperToolProtocol {
    @objc(loadKextAtPath:use32Bit:completion:)
    func loadKext(atPath: String, use32Bit: Bool, completion: @escaping (Bool, String?) -> Void)
    
    @objc(unloadKextAtPath:completion:)
    func unloadKext(atPath: String, completion: @escaping (Bool, String?) -> Void)
    
    @objc(readSMCKey:type:completion:)
    func readSMCKey(_ key: String, type: String, completion: @escaping (Bool, Float, String?) -> Void)
    
    @objc(getStatusWithCompletion:)
    func getStatus(completion: @escaping (Bool, String, Bool) -> Void)
}

class HelperXPCDelegate: NSObject, NSXPCListenerDelegate, ObjCHelperToolProtocol {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: ObjCHelperToolProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
    
    @objc(loadKextAtPath:use32Bit:completion:)
    func loadKext(atPath kextPath: String, use32Bit: Bool, completion: @escaping (Bool, String?) -> Void) {
        let response = KextManager.shared.loadKext(at: kextPath, use32Bit: use32Bit)
        completion(response.success, response.errorMessage)
    }
    
    @objc(unloadKextAtPath:completion:)
    func unloadKext(atPath kextPath: String, completion: @escaping (Bool, String?) -> Void) {
        let response = KextManager.shared.unloadKext(at: kextPath)
        completion(response.success, response.errorMessage)
    }
    
    @objc(readSMCKey:type:completion:)
    func readSMCKey(_ key: String, type: String, completion: @escaping (Bool, Float, String?) -> Void) {
        guard let smcType = SMCReadType(rawValue: type) else {
            completion(false, 0, "Invalid SMC type: \(type)")
            return
        }
        let response = SMCManager.shared.readValue(key: key, type: smcType)
        completion(response.success, response.value ?? 0, response.errorMessage)
    }
    
    @objc(getStatusWithCompletion:)
    func getStatus(completion: @escaping (Bool, String, Bool) -> Void) {
        let isKextLoaded = KextManager.shared.checkKextStatus()
        completion(isKextLoaded, HelperConstants.version, !isKextLoaded)
    }
}

let delegate = HelperXPCDelegate()
let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
listener.delegate = delegate
listener.resume()

dispatchMain()
