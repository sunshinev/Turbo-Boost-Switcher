#import "HelperInstallationManager.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

NSString * const kHelperBundleIdentifier = @"com.sunshinev.TurboBoostSwitcher.helper";
NSString * const kHelperMachServiceName = @"com.sunshinev.TurboBoostSwitcher.helper";

@interface HelperInstallationManager ()
@property (nonatomic, readwrite) BOOL isHelperInstalled;
@property (nonatomic, readwrite, nullable) NSString *installedVersion;
@end

@implementation HelperInstallationManager

+ (instancetype)sharedManager {
    static HelperInstallationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HelperInstallationManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self checkHelperStatus];
    }
    return self;
}

- (void)checkHelperStatus {
    NSString *helperPath = [@"/Library/PrivilegedHelperTools" stringByAppendingPathComponent:kHelperBundleIdentifier];
    NSString *launchdPath = [@"/Library/LaunchDaemons" stringByAppendingPathComponent:[kHelperBundleIdentifier stringByAppendingString:@".plist"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL helperExists = [fm fileExistsAtPath:helperPath];
    BOOL launchdExists = [fm fileExistsAtPath:launchdPath];
    
    self.isHelperInstalled = helperExists && launchdExists;
    
    if (self.isHelperInstalled) {
        NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:[helperPath stringByAppendingString:@"/Contents/Info.plist"]];
        self.installedVersion = infoPlist[@"CFBundleShortVersionString"] ?: infoPlist[@"CFBundleVersion"];
    } else {
        self.installedVersion = nil;
    }
}

- (void)installHelperWithCompletion:(HelperInstallCompletionBlock)completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AuthorizationRef authRef = NULL;
        OSStatus status;
        
        status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authRef);
        if (status != errAuthorizationSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"HelperInstallation" code:status userInfo:@{NSLocalizedDescriptionKey: @"Failed to create authorization"}];
                    completion(NO, error);
                }
            });
            return;
        }
        
        AuthorizationItem authItem = {kAuthorizationRightExecute, 0, NULL, 0};
        AuthorizationRights authRights = {1, &authItem};
        AuthorizationFlags authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
        
        status = AuthorizationCopyRights(authRef, &authRights, NULL, authFlags, NULL);
        if (status != errAuthorizationSuccess) {
            AuthorizationFree(authRef, kAuthorizationFlagDefaults);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"HelperInstallation" code:status userInfo:@{NSLocalizedDescriptionKey: @"Authorization denied"}];
                    completion(NO, error);
                }
            });
            return;
        }
        
        CFErrorRef blessErrorRef = NULL;
        BOOL success = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)kHelperBundleIdentifier, authRef, &blessErrorRef);
        
        NSError *blessError = nil;
        if (blessErrorRef) {
            blessError = CFBridgingRelease(blessErrorRef);
        }
        
        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkHelperStatus];
            if (completion) {
                completion(success, blessError);
            }
        });
    });
}

- (void)uninstallHelperWithCompletion:(HelperUninstallCompletionBlock)completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *helperPath = [@"/Library/PrivilegedHelperTools" stringByAppendingPathComponent:kHelperBundleIdentifier];
        NSString *launchdPath = [@"/Library/LaunchDaemons" stringByAppendingPathComponent:[kHelperBundleIdentifier stringByAppendingString:@".plist"]];
        
        NSError *error = nil;
        
        if ([fm fileExistsAtPath:launchdPath]) {
            [fm removeItemAtPath:launchdPath error:&error];
        }
        
        if ([fm fileExistsAtPath:helperPath]) {
            [fm removeItemAtPath:helperPath error:&error];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkHelperStatus];
            if (completion) {
                completion(error == nil, error);
            }
        });
    });
}

@end