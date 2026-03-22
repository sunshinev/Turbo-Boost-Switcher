#import "HelperStatusMenuController.h"
#import "HelperInstallationManager.h"

@interface HelperStatusMenuController ()
@property (nonatomic, strong) NSMenuItem *helperMenuItem;
@property (nonatomic, strong) NSMenuItem *installHelperMenuItem;
@end

@implementation HelperStatusMenuController

+ (instancetype)sharedController {
    static HelperStatusMenuController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HelperStatusMenuController alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupMenuItems];
    }
    return self;
}

- (void)setupMenuItems {
    self.helperMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    self.helperMenuItem.enabled = NO;
    
    self.installHelperMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(installHelper:) keyEquivalent:@""];
    self.installHelperMenuItem.target = self;
    
    [self updateHelperStatus];
}

- (void)updateHelperStatus {
    BOOL isInstalled = [HelperInstallationManager sharedManager].isHelperInstalled;
    NSString *version = [HelperInstallationManager sharedManager].installedVersion;
    
    if (isInstalled) {
        self.helperMenuItem.title = [NSString stringWithFormat:@"Helper: 已安装 (%@)", version ?: @"未知版本"];
        self.installHelperMenuItem.title = @"卸载 Helper";
        self.installHelperMenuItem.action = @selector(uninstallHelper:);
    } else {
        self.helperMenuItem.title = @"Helper: 未安装";
        self.installHelperMenuItem.title = @"安装 Helper (避免重复输入密码)";
        self.installHelperMenuItem.action = @selector(installHelper:);
    }
}

- (void)addToMenu:(NSMenu *)menu {
    NSMenuItem *separator = [NSMenuItem separatorItem];
    [menu addItem:separator];
    [menu addItem:self.helperMenuItem];
    [menu addItem:self.installHelperMenuItem];
}

#pragma mark - Actions

- (void)installHelper:(id)sender {
    __weak typeof(self) weakSelf = self;
    [[HelperInstallationManager sharedManager] installHelperWithCompletion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"安装成功";
                alert.informativeText = @"Helper 已安装。现在只需一次授权即可持续使用。";
                alert.alertStyle = NSAlertStyleInformational;
                [alert runModal];
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"安装失败";
                alert.informativeText = error.localizedDescription ?: @"未知错误";
                alert.alertStyle = NSAlertStyleCritical;
                [alert runModal];
            }
            [weakSelf updateHelperStatus];
        });
    }];
}

- (void)uninstallHelper:(id)sender {
    __weak typeof(self) weakSelf = self;
    [[HelperInstallationManager sharedManager] uninstallHelperWithCompletion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"卸载成功";
                alert.informativeText = @"Helper 已卸载。将恢复到原有授权流程。";
                alert.alertStyle = NSAlertStyleInformational;
                [alert runModal];
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"卸载失败";
                alert.informativeText = error.localizedDescription ?: @"未知错误";
                alert.alertStyle = NSAlertStyleCritical;
                [alert runModal];
            }
            [weakSelf updateHelperStatus];
        });
    }];
}

@end