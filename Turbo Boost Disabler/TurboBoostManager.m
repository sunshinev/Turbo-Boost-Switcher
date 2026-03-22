#import "TurboBoostManager.h"
#import "XPCClientWrapper.h"
#import "HelperInstallationManager.h"
#import "SystemCommands.h"

@interface TurboBoostManager ()
@property (nonatomic, readwrite) BOOL useHelper;
@property (nonatomic, readwrite) BOOL isHelperAvailable;
@property (nonatomic, readwrite) BOOL isTurboBoostEnabled;
@end

@implementation TurboBoostManager

+ (instancetype)sharedManager {
    static TurboBoostManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TurboBoostManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isTurboBoostEnabled = YES;
        [self checkHelperAvailability];
        [self refreshStatus];
    }
    return self;
}

- (void)checkHelperAvailability {
    self.isHelperAvailable = [HelperInstallationManager sharedManager].isHelperInstalled;
    self.useHelper = self.isHelperAvailable;
    
    NSLog(@"[TurboBoostManager] Helper available: %@, useHelper: %@", 
          self.isHelperAvailable ? @"YES" : @"NO", 
          self.useHelper ? @"YES" : @"NO");
    
    if (self.useHelper) {
        NSLog(@"[TurboBoostManager] Using Helper (XPC) - 无需密码");
        [[XPCClientWrapper sharedClient] connect];
    }
}

- (NSString *)getKextPath:(BOOL *)is32Bit {
    NSString *bundlePathValue = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
    NSString *kextPath = [[bundlePathValue stringByAppendingPathComponent:@"tbswitcher_resources"] stringByAppendingPathComponent:@"DisableTurboBoost.64bits.kext"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:kextPath]) {
        kextPath = [[NSBundle mainBundle] pathForResource:@"DisableTurboBoost.64bits" ofType:@"kext"];
        if (!kextPath) {
            kextPath = [[NSBundle mainBundle] pathForResource:@"DisableTurboBoost.32bits" ofType:@"kext"];
            if (is32Bit) *is32Bit = YES;
        }
    }
    
    return kextPath;
}

- (void)enableTurboBoostWithCompletion:(TurboBoostToggleCompletionBlock)completion {
    NSLog(@"[TurboBoostManager] enableTurboBoost called, useHelper=%@", self.useHelper ? @"YES" : @"NO");
    
    // 先检查kext是否已卸载
    if (![SystemCommands isModuleLoaded]) {
        NSLog(@"[TurboBoostManager] Kext not loaded, Turbo Boost already enabled");
        self.isTurboBoostEnabled = YES;
        NSLog(@"[TurboBoostManager] isTurboBoostEnabled set to YES (kext not loaded)");
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    if (self.useHelper) {
        NSString *kextPath = [self getKextPath:nil];
        [[XPCClientWrapper sharedClient] unloadKextAtPath:kextPath completion:^(BOOL success, NSString * _Nullable errorMessage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isTurboBoostEnabled = success;
                NSLog(@"[TurboBoostManager] Turbo Boost %@ (XPC), isTurboBoostEnabled=%@", 
                      success ? @"enabled" : @"failed to enable", 
                      self.isTurboBoostEnabled ? @"YES" : @"NO");
            });
            
            if (completion) {
                NSError *error = nil;
                if (!success) {
                    error = [NSError errorWithDomain:@"TurboBoostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: errorMessage ?: @"Failed to unload kext"}];
                }
                completion(success, error);
            }
        }];
    } else {
        NSLog(@"[TurboBoostManager] enableTurboBoost: Helper not available");
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"TurboBoostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Helper not installed"}];
            completion(NO, error);
        }
    }
}

- (void)disableTurboBoostWithCompletion:(TurboBoostToggleCompletionBlock)completion {
    NSLog(@"[TurboBoostManager] disableTurboBoost called, useHelper=%@", self.useHelper ? @"YES" : @"NO");
    
    // 先检查kext是否已加载
    if ([SystemCommands isModuleLoaded]) {
        NSLog(@"[TurboBoostManager] Kext already loaded, Turbo Boost already disabled");
        self.isTurboBoostEnabled = NO;
        NSLog(@"[TurboBoostManager] isTurboBoostEnabled set to NO (kext already loaded)");
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    if (self.useHelper) {
        BOOL is32Bit = NO;
        NSString *kextPath = [self getKextPath:&is32Bit];
        
        [[XPCClientWrapper sharedClient] loadKextAtPath:kextPath use32Bit:is32Bit completion:^(BOOL success, NSString * _Nullable errorMessage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isTurboBoostEnabled = !success;
                NSLog(@"[TurboBoostManager] Turbo Boost %@ (XPC), isTurboBoostEnabled=%@", 
                      success ? @"disabled" : @"failed to disable", 
                      self.isTurboBoostEnabled ? @"YES" : @"NO");
            });
            
            if (completion) {
                NSError *error = nil;
                if (!success) {
                    error = [NSError errorWithDomain:@"TurboBoostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: errorMessage ?: @"Failed to load kext"}];
                }
                completion(success, error);
            }
        }];
    } else {
        NSLog(@"[TurboBoostManager] disableTurboBoost: Helper not available");
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"TurboBoostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Helper not installed"}];
            completion(NO, error);
        }
    }
}

- (void)readSensorsWithCompletion:(SensorReadCompletionBlock)completion {
    // Always use direct SystemCommands for sensor reading
    // (Helper Tool's SMC access may fail with kIOReturnNotPrivileged on some macOS versions)
    float temperature = [SystemCommands readCurrentCpuTemp];
    float fanSpeed = [SystemCommands readCurrentFanSpeed];
    if (completion) {
        completion(YES, temperature, fanSpeed, nil);
    }
}

- (void)readCPUTemperatureWithCompletion:(void(^)(BOOL success, float temperature, NSError * _Nullable error))completion {
    // Always use direct SystemCommands for sensor reading
    float temperature = [SystemCommands readCurrentCpuTemp];
    if (completion) {
        completion(temperature > 0, temperature, nil);
    }
}

- (void)readFanSpeedWithCompletion:(void(^)(BOOL success, float fanSpeed, NSError * _Nullable error))completion {
    // Always use direct SystemCommands for sensor reading
    float fanSpeed = [SystemCommands readCurrentFanSpeed];
    if (completion) {
        completion(fanSpeed > 0, fanSpeed, nil);
    }
}

- (void)readCPUFrequencyWithCompletion:(void(^)(BOOL success, float frequency, NSError * _Nullable error))completion {
    if (self.useHelper) {
        [[XPCClientWrapper sharedClient] readSMCKey:@"CPUF" type:@"frequency" completion:^(BOOL success, float value, NSString *errorMessage) {
            if (completion) {
                NSError *error = nil;
                if (!success) {
                    error = [NSError errorWithDomain:@"TurboBoostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: errorMessage ?: @"Failed to read CPU frequency"}];
                }
                // 确保返回 GHz: 如果值 > 100，说明是 MHz，需要转换
                float frequencyGHz = value;
                if (value > 100.0f) {
                    frequencyGHz = value / 1000.0f;
                    NSLog(@"[TurboBoostManager] Converted frequency from %.2f MHz to %.2f GHz", value, frequencyGHz);
                }
                completion(success, frequencyGHz, error);
            }
        }];
    } else {
        float frequency = [SystemCommands readCurrentCpuFreqWithAuthRef:nil];
        if (completion) {
            // 确保返回 GHz: 如果值 > 100，说明是 MHz，需要转换
            float frequencyGHz = frequency;
            if (frequency > 100.0f) {
                frequencyGHz = frequency / 1000.0f;
                NSLog(@"[TurboBoostManager] Converted frequency from %.2f MHz to %.2f GHz", frequency, frequencyGHz);
            }
            completion(frequency >= 0, frequencyGHz, nil);
        }
    }
}

- (void)refreshStatus {
    if (self.useHelper) {
        [[XPCClientWrapper sharedClient] getStatusWithCompletion:^(BOOL isKextLoaded, NSString *helperVersion, BOOL turboBoostEnabled) {
            self.isTurboBoostEnabled = turboBoostEnabled;
            NSLog(@"[TurboBoostManager] Status refreshed via XPC: isTurboBoostEnabled=%@", turboBoostEnabled ? @"YES" : @"NO");
        }];
    } else {
        self.isTurboBoostEnabled = ![SystemCommands isModuleLoaded];
    }
}

- (void)tryReadTemperatureKeys:(NSArray *)keys index:(NSInteger)index completion:(void(^)(BOOL success, float value, NSString *errorMessage))completion {
    if (index >= keys.count) {
        NSLog(@"[TurboBoostManager] All temperature keys failed after trying %lu keys", (unsigned long)keys.count);
        if (completion) {
            completion(NO, 0, @"All temperature keys failed");
        }
        return;
    }
    
    NSString *key = keys[index];
    NSLog(@"[TurboBoostManager] Trying temperature key '%@' (%ld/%lu)", key, (long)(index + 1), (unsigned long)keys.count);
    
    [[XPCClientWrapper sharedClient] readSMCKey:key type:@"temperature" completion:^(BOOL success, float value, NSString *errorMessage) {
        if (success && value >= 0) {
            NSLog(@"[TurboBoostManager] Temperature key '%@' succeeded: %.1f", key, value);
            if (completion) {
                completion(YES, value, nil);
            }
        } else {
            NSLog(@"[TurboBoostManager] Temperature key '%@' failed: success=%@, value=%.1f, error=%@", 
                  key, success ? @"YES" : @"NO", value, errorMessage ?: @"unknown");
            [self tryReadTemperatureKeys:keys index:index + 1 completion:completion];
        }
    }];
}

- (void)tryReadFanKeys:(NSArray *)keys index:(NSInteger)index completion:(void(^)(BOOL success, float value, NSString *errorMessage))completion {
    if (index >= keys.count) {
        NSLog(@"[TurboBoostManager] All fan keys failed after trying %lu keys", (unsigned long)keys.count);
        if (completion) {
            completion(NO, 0, @"All fan keys failed");
        }
        return;
    }
    
    NSString *key = keys[index];
    NSLog(@"[TurboBoostManager] Trying fan key '%@' (%ld/%lu)", key, (long)(index + 1), (unsigned long)keys.count);
    
    [[XPCClientWrapper sharedClient] readSMCKey:key type:@"fanSpeed" completion:^(BOOL success, float value, NSString *errorMessage) {
        if (success && value >= 0) {
            NSLog(@"[TurboBoostManager] Fan key '%@' succeeded: %.0f", key, value);
            if (completion) {
                completion(YES, value, nil);
            }
        } else {
            NSLog(@"[TurboBoostManager] Fan key '%@' failed: success=%@, value=%.0f, error=%@", 
                  key, success ? @"YES" : @"NO", value, errorMessage ?: @"unknown");
            [self tryReadFanKeys:keys index:index + 1 completion:completion];
        }
    }];
}

@end
