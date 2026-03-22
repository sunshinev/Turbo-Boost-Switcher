//
//  ChartWindowController.h
//  Turbo Boost Switcher Pro
//
//  Created by Rubén García Pérez on 8/4/18.
//  Copyright © 2018 Rubén García Pérez. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChartWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic) BOOL isOpen;
@property (nonatomic) BOOL isFahrenheit;

- (void) addTempEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled;
- (void) addFanEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled;
- (void) addCpuLoadEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled;
- (void) addCpuFreqEntry:(double)value withCurrentValue:(NSString *)strValue isTbEnabled:(BOOL)isTbEnabled;

- (void) initData;
- (IBAction) displayChartingHelp:(id)sender;

@end