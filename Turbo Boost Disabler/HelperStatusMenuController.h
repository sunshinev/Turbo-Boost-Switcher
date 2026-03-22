#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface HelperStatusMenuController : NSObject

+ (instancetype)sharedController;

@property (nonatomic, readonly) NSMenuItem *helperMenuItem;
@property (nonatomic, readonly) NSMenuItem *installHelperMenuItem;

- (void)updateHelperStatus;
- (void)addToMenu:(NSMenu *)menu;

@end

NS_ASSUME_NONNULL_END