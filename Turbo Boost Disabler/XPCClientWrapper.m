#import "XPCClientWrapper.h"
#import "HelperInstallationManager.h"
#import "SystemCommands.h"

@interface XPCClientWrapper ()
@property (nonatomic, strong) NSXPCConnection *connection;
@property (nonatomic, readwrite) BOOL isConnected;
@end

@implementation XPCClientWrapper

+ (instancetype)sharedClient {
    static XPCClientWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XPCClientWrapper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isConnected = NO;
    }
    return self;
}

- (void)connect {
    if (self.connection) {
        return;
    }
    
    self.connection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperMachServiceName options:NSXPCConnectionPrivileged];
    self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
    
    __weak typeof(self) weakSelf = self;
    self.connection.interruptionHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.isConnected = NO;
            weakSelf.connection = nil;
        });
    };
    
    self.connection.invalidationHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.isConnected = NO;
            weakSelf.connection = nil;
        });
    };
    
    [self.connection resume];
    self.isConnected = YES;
}

- (void)disconnect {
    if (self.connection) {
        [self.connection invalidate];
        self.connection = nil;
        self.isConnected = NO;
    }
}

- (id<HelperToolProtocol>)helperProxy {
    if (!self.isConnected) {
        [self connect];
    }
    return self.connection.remoteObjectProxy;
}

- (void)loadKextAtPath:(NSString *)kextPath use32Bit:(BOOL)use32Bit completion:(KextOperationCompletionBlock)completion {
    NSLog(@"[XPCClientWrapper] loadKextAtPath: %@, use32Bit: %@", kextPath, use32Bit ? @"YES" : @"NO");
    
    // 添加超时处理，确保即使 XPC 无响应也能回调
    __block BOOL callbackInvoked = NO;
    KextOperationCompletionBlock wrappedCompletion = ^(BOOL success, NSString * _Nullable errorMessage) {
        if (!callbackInvoked) {
            callbackInvoked = YES;
            NSLog(@"[XPCClientWrapper] loadKextAtPath callback: success=%@, error=%@", success ? @"YES" : @"NO", errorMessage ?: @"nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(success, errorMessage);
                }
            });
        }
    };
    
    // 设置 10 秒超时
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!callbackInvoked) {
            NSLog(@"[XPCClientWrapper] loadKextAtPath timeout!");
            wrappedCompletion(NO, @"XPC operation timed out");
        }
    });
    
    [[self helperProxy] loadKextAtPath:kextPath use32Bit:use32Bit completion:^(BOOL success, NSString * _Nullable errorMessage) {
        wrappedCompletion(success, errorMessage);
    }];
}

- (void)unloadKextAtPath:(NSString *)kextPath completion:(KextOperationCompletionBlock)completion {
    NSLog(@"[XPCClientWrapper] unloadKextAtPath: %@", kextPath);
    
    __block BOOL callbackInvoked = NO;
    KextOperationCompletionBlock wrappedCompletion = ^(BOOL success, NSString * _Nullable errorMessage) {
        if (!callbackInvoked) {
            callbackInvoked = YES;
            NSLog(@"[XPCClientWrapper] unloadKextAtPath callback: success=%@, error=%@", success ? @"YES" : @"NO", errorMessage ?: @"nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(success, errorMessage);
                }
            });
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!callbackInvoked) {
            NSLog(@"[XPCClientWrapper] unloadKextAtPath timeout!");
            wrappedCompletion(NO, @"XPC operation timed out");
        }
    });
    
    [[self helperProxy] unloadKextAtPath:kextPath completion:^(BOOL success, NSString * _Nullable errorMessage) {
        wrappedCompletion(success, errorMessage);
    }];
}

- (void)readSMCKey:(NSString *)key type:(NSString *)type completion:(SMCReadCompletionBlock)completion {
    NSLog(@"[XPCClientWrapper] readSMCKey: %@, type: %@", key, type);
    
    __block BOOL callbackInvoked = NO;
    SMCReadCompletionBlock wrappedCompletion = ^(BOOL success, float value, NSString * _Nullable errorMessage) {
        if (!callbackInvoked) {
            callbackInvoked = YES;
            NSLog(@"[XPCClientWrapper] readSMCKey callback: success=%@, value=%.2f, error=%@", success ? @"YES" : @"NO", value, errorMessage ?: @"nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(success, value, errorMessage);
                }
            });
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!callbackInvoked) {
            NSLog(@"[XPCClientWrapper] readSMCKey timeout for key: %@", key);
            wrappedCompletion(NO, 0, @"XPC operation timed out");
        }
    });
    
    [[self helperProxy] readSMCKey:key type:type completion:^(BOOL success, float value, NSString * _Nullable errorMessage) {
        wrappedCompletion(success, value, errorMessage);
    }];
}

- (void)getStatusWithCompletion:(StatusCompletionBlock)completion {
    NSLog(@"[XPCClientWrapper] getStatus");
    
    __block BOOL callbackInvoked = NO;
    StatusCompletionBlock wrappedCompletion = ^(BOOL isKextLoaded, NSString *helperVersion, BOOL turboBoostEnabled) {
        if (!callbackInvoked) {
            callbackInvoked = YES;
            NSLog(@"[XPCClientWrapper] getStatus callback: isKextLoaded=%@, version=%@, turboBoostEnabled=%@", isKextLoaded ? @"YES" : @"NO", helperVersion ?: @"nil", turboBoostEnabled ? @"YES" : @"NO");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(isKextLoaded, helperVersion, turboBoostEnabled);
                }
            });
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!callbackInvoked) {
            NSLog(@"[XPCClientWrapper] getStatus timeout - using fallback");
            BOOL fallbackLoaded = [SystemCommands isModuleLoaded];
            wrappedCompletion(fallbackLoaded, @"timeout", !fallbackLoaded);
        }
    });
    
    [[self helperProxy] getStatusWithCompletion:^(BOOL isKextLoaded, NSString *helperVersion, BOOL turboBoostEnabled) {
        wrappedCompletion(isKextLoaded, helperVersion, turboBoostEnabled);
    }];
}

@end