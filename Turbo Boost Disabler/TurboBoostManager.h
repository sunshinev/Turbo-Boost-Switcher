#import <Foundation/Foundation.h>
#import "SystemCommands.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^TurboBoostToggleCompletionBlock)(BOOL success, NSError * _Nullable error);
typedef void (^SensorReadCompletionBlock)(BOOL success, float temperature, float fanSpeed, NSError * _Nullable error);

@interface TurboBoostManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL useHelper;
@property (nonatomic, readonly) BOOL isHelperAvailable;
@property (nonatomic, readonly) BOOL isTurboBoostEnabled;

- (void)checkHelperAvailability;

- (void)enableTurboBoostWithCompletion:(TurboBoostToggleCompletionBlock)completion;
- (void)disableTurboBoostWithCompletion:(TurboBoostToggleCompletionBlock)completion;

- (void)readSensorsWithCompletion:(SensorReadCompletionBlock)completion;
- (void)readCPUTemperatureWithCompletion:(void(^)(BOOL success, float temperature, NSError * _Nullable error))completion;
- (void)readFanSpeedWithCompletion:(void(^)(BOOL success, float fanSpeed, NSError * _Nullable error))completion;
- (void)readCPUFrequencyWithCompletion:(void(^)(BOOL success, float frequency, NSError * _Nullable error))completion;

- (void)refreshStatus;

@end

NS_ASSUME_NONNULL_END