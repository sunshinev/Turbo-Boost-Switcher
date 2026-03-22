#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^KextOperationCompletionBlock)(BOOL success, NSString * _Nullable errorMessage);
typedef void (^SMCReadCompletionBlock)(BOOL success, float value, NSString * _Nullable errorMessage);
typedef void (^StatusCompletionBlock)(BOOL isKextLoaded, NSString *helperVersion, BOOL turboBoostEnabled);

@protocol HelperToolProtocol <NSObject>

- (void)loadKextAtPath:(NSString *)kextPath use32Bit:(BOOL)use32Bit completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;
- (void)unloadKextAtPath:(NSString *)kextPath completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;
- (void)readSMCKey:(NSString *)key type:(NSString *)type completion:(void (^)(BOOL success, float value, NSString * _Nullable errorMessage))completion;
- (void)getStatusWithCompletion:(void (^)(BOOL isKextLoaded, NSString *helperVersion, BOOL turboBoostEnabled))completion;

@end

@interface XPCClientWrapper : NSObject

+ (instancetype)sharedClient;

@property (nonatomic, readonly) BOOL isConnected;

- (void)connect;
- (void)disconnect;

- (void)loadKextAtPath:(NSString *)kextPath use32Bit:(BOOL)use32Bit completion:(KextOperationCompletionBlock)completion;
- (void)unloadKextAtPath:(NSString *)kextPath completion:(KextOperationCompletionBlock)completion;
- (void)readSMCKey:(NSString *)key type:(NSString *)type completion:(SMCReadCompletionBlock)completion;
- (void)getStatusWithCompletion:(StatusCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END