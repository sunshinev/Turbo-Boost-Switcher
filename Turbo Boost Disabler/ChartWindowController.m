//
//  ChartWindowController.m
//  Turbo Boost Switcher Pro
//
//  Created by Rubén García Pérez on 8/4/18.
//  Copyright © 2018 Rubén García Pérez. All rights reserved.
//

#import "ChartWindowController.h"
#import "SystemCommands.h"

#if __has_include("Turbo_Boost_Switcher-Swift.h")
#import "Turbo_Boost_Switcher-Swift.h"
#endif

@interface ChartWindowController ()

@property (nonatomic, strong) SwiftUIChartManager *chartManager;

@end

@implementation ChartWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.delegate = self;
    [self.window setTitle:NSLocalizedString(@"titCharting", nil)];
    
    self.isOpen = YES;
    
    [self setupSwiftUICharts];
}

- (void)setupSwiftUICharts {
    self.chartManager = [[SwiftUIChartManager alloc] init];
    
    float baseFreq = [SystemCommands getBaseFreq];
    NSLog(@"[ChartWindowController] baseFreq: %.2f", baseFreq);
    
    NSString *tempTitle = NSLocalizedString(@"lblTemperature", nil);
    NSString *fanTitle = NSLocalizedString(@"lblFanSpeed", nil);
    NSString *cpuLoadTitle = NSLocalizedString(@"lblCpuLoad", nil);
    NSString *cpuFreqTitle = NSLocalizedString(@"lblCpuFreq", nil);
    
    [self.chartManager createChartView:self.window.contentView
                            tempTitle:tempTitle
                             fanTitle:fanTitle
                        cpuLoadTitle:cpuLoadTitle
                        cpuFreqTitle:cpuFreqTitle
                            baseFreq:baseFreq];
    
    NSLog(@"[ChartWindowController] SwiftUI charts setup complete");
}

- (void)initData {
    self.isOpen = NO;
}

- (void)windowWillClose:(NSNotification *)notification {
    self.isOpen = NO;
}

- (void)addTempEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled {
    if (self.isOpen && self.chartManager) {
        [self.chartManager addTempEntry:value currentValue:strValue isTbEnabled:isTbEnabled];
    }
}

- (void)addFanEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled {
    if (self.isOpen && self.chartManager) {
        [self.chartManager addFanEntry:value currentValue:strValue isTbEnabled:isTbEnabled];
    }
}

- (void)addCpuLoadEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled {
    if (self.isOpen && self.chartManager) {
        [self.chartManager addCpuLoadEntry:value currentValue:strValue isTbEnabled:isTbEnabled];
    }
}

- (void)addCpuFreqEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled {
    if (self.isOpen && self.chartManager) {
        [self.chartManager addCpuFreqEntry:value currentValue:strValue isTbEnabled:isTbEnabled];
    }
}

- (IBAction)showWindow:(nullable id)sender {
    [super showWindow:sender];
}

- (IBAction)displayChartingHelp:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert.window setTitle:@"Turbo Boost Switcher Pro"];
    
    [self.window setLevel:NSNormalWindowLevel];
    [alert.window setLevel:NSStatusWindowLevel];
    
    [alert setMessageText:NSLocalizedString(@"helpCharting", nil)];
    [alert runModal];
    
    [self.window setLevel:NSStatusWindowLevel];
}

@end