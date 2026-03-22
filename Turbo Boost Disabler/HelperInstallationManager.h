#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHelperBundleIdentifier;
extern NSString * const kHelperMachServiceName;

typedef void (^HelperInstallCompletionBlock)(BOOL success, NSError * _Nullable error);
typedef void (^HelperUninstallCompletionBlock)(BOOL success, NSError * _Nullable error);

@interface HelperInstallationManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isHelperInstalled;
@property (nonatomic, readonly, nullable) NSString *installedVersion;

- (void)checkHelperStatus;
- (void)installHelperWithCompletion:(HelperInstallCompletionBlock)completion;
- (void)uninstallHelperWithCompletion:(HelperUninstallCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END