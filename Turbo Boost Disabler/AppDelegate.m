//
//  AppDelegate.m
//  Turbo Boost Switcher
//
//  Created by Rubén García Pérez on 19/07/13.
//  Copyright (c) 2013 Rubén García Pérez.
//  rugarciap.com
//
/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "AppDelegate.h"
#import "SystemCommands.h"
#import "AboutWindowController.h"
#import "StartupHelper.h"
#import "TurboBoostManager.h"
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

@implementation AppDelegate

@synthesize aboutWindow, refreshTimer, chartWindowController;

// Struct to take the cpu samples
struct cpusample {
    uint64_t totalSystemTime;
    uint64_t totalUserTime;
    uint64_t totalIdleTime;
    
};

// The two samples
struct cpusample sample_one;
struct cpusample sample_two;


// On wake up reinstall the module if needed
- (void) receiveWakeNote: (NSNotification*) note
{
    TurboBoostManager *manager = [TurboBoostManager sharedManager];
    [manager refreshStatus];
    
    // Reload the module if the current status is on, since OSX enables turbo boost after an
    // undetermined time on sleep / hibernation
    if (!manager.isTurboBoostEnabled) {
        // Kext is loaded (TB disabled), need to reload to re-disable TB
        __weak typeof(self) weakSelf = self;
        
        // First unload, then load
        [manager enableTurboBoostWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [manager disableTurboBoostWithCompletion:^(BOOL success, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf updateStatus];
                    });
                }];
            }
        }];
    }
    
    // Add another status bar refresh just to be sure, since depending on mac cpu load it can take a little longer
    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:2];
    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:5];
    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:10];
    
    // Refresh timers after wake up.., a couple of users reported issues after long sleep period
    [self performSelector:@selector(refreshTimerAfterWakeUp) withObject:nil afterDelay:2];

}

// Refersh timers after wakeup
- (void) refreshTimerAfterWakeUp {
   
   if (([StartupHelper isMonitoringEnabled]) && (self.refreshTimer != nil)) {
        
        [self.refreshTimer invalidate];
        
        NSRunLoop * rl = [NSRunLoop mainRunLoop];
        
        // Timer to update the sensor readings (cpu & fan rpm) each 4 seconds
        NSInteger refreshTimeValue = [StartupHelper sensorRefreshTime];
        if (refreshTimeValue < 4) {
            refreshTimeValue = 4;
        }
        
        self.refreshTimer = [NSTimer timerWithTimeInterval:refreshTimeValue target:self selector:@selector(updateSensorValues) userInfo:nil repeats:YES];
        [rl addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
   }
}

// Suscribe to wake up notifications
- (void) fileNotifications
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
}

- (void) awakeFromNib {
    
    // First, check for kext. If not preset, display an user message warning to get the app reinstalled.
    NSString *modulePath = [SystemCommands getModulePath:[SystemCommands is32bits]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:modulePath]) {
        
        // If tbswitcher_resources is not found, alert and exit
        NSLog(@"TBS: KEXT NOT FOUND AT %@", modulePath);
        
        // If private/var is present -> translocation -> app was not dragged manually by the user
        if ([modulePath rangeOfString:@"/private/var"].location != NSNotFound) {
            
            // Translocation!
            NSAlert *alert = [[NSAlert alloc] init];
            NSString *msgText = [NSString stringWithFormat:@"%@\n\nPath not found: %@",@"Hi!\n\nIt seems the install process did not finish properly and you're suffering from App Translocation. Please, open the .dmg again and drag the .app file to Applications folder. More info at the HELP included with the .dmg\n\nThanks.", modulePath];
            
            [alert setMessageText:NSLocalizedString(@"alert_kext_missing_title", nil)];
            [alert setInformativeText:msgText];
            
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
            exit(-1);
        }
        
        // Display alert and exit the app
        NSAlert *alert = [[NSAlert alloc] init];
        
        NSString *msgText = [NSString stringWithFormat:@"%@\n\nPath not found: %@",NSLocalizedString(@"alert_kext_missing_detail", nil), modulePath];
        
        [alert setMessageText:NSLocalizedString(@"alert_kext_missing_title", nil)];
        [alert setInformativeText:msgText];
        
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        exit(-1);
    }
    
    [[TurboBoostManager sharedManager] checkHelperAvailability];
    
    // Init the cpu load samples
    sample_one.totalIdleTime = 0;
    sample_two.totalIdleTime = 0;
    
    // Item to show up on the status bar
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    statusImageOn = [NSImage imageNamed:@"icon"];
    statusImageOff = [NSImage imageNamed:@"icon_off"];
    
    [statusImageOn setTemplate:YES];
    [statusImageOff setTemplate:YES];
    
    [statusItem setToolTip:@"Turbo Boost Switcher"];

    [statusItem setHighlightMode:YES];
    [statusItem setImage:statusImageOn];
 
    [statusItem setAction:@selector(statusItemClicked)];
    [statusItem setTarget:self];
    
    // Add delegate to status menu to refresh status
    // when opening
    [statusMenu setDelegate:self];
    
    // Charting menu item
    [chartsMenuItem setTitle:NSLocalizedString(@"menuCharting", nil)];
    
    // Update open at login status
    [checkOpenAtLogin setState:[StartupHelper isOpenAtLogin]];
    [checkOpenAtLogin setTitle:NSLocalizedString(@"open_login", nil)];
    
    // Update check monitoring
    [checkMonitoring setState:[StartupHelper isMonitoringEnabled]];
    
    // Update disable at login status
    [checkDisableAtLaunch setState:[StartupHelper isDisableAtLaunch]];
    [checkDisableAtLaunch setTitle:NSLocalizedString(@"disable_login", nil)];
    
    // Update translations
    [settingsLabel setTitleWithMnemonic:NSLocalizedString(@"settings", nil)];
    [aboutItem setTitle:NSLocalizedString(@"about", nil)];
    [exitItem setTitle:NSLocalizedString(@"quit", nil)];
    
    // Status strings init
    statusOnOff = [[NSMutableString alloc] initWithString:@""];
    
    [checkOnOffText setState:[StartupHelper isStatusOnOffEnabled]];
    [checkOnOffText setTitle:NSLocalizedString(@"onOffMenu", nil)];
    [checkOnOffText setFont:[statusMenu font]];
       
    // Update fonts
    [settingsLabel setFont:[statusMenu font]];
    [checkDisableAtLaunch setFont:[statusMenu font]];
    [checkOpenAtLogin setFont:[statusMenu font]];
    [checkMonitoring setFont:[statusMenu font]];
    
    // Init the chart window controller
    if (self.chartWindowController == nil) {
        self.chartWindowController = [[ChartWindowController alloc] initWithWindowNibName:@"ChartWindowController"];
        [self.chartWindowController initData];
    }
    
    // Disable at launch if enabled
    if (([StartupHelper isDisableAtLaunch]) && (![SystemCommands isModuleLoaded])) {
        [self disableTurboBoost];
    }
    
    // Refresh the status
    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:2.0];
    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:5.0];
    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:10.0];
    
    // Timer to update the sensor readings (cpu & fan rpm) each 4 seconds
    NSInteger refreshTimeValue = [StartupHelper sensorRefreshTime];
    if (refreshTimeValue < 4) {
        refreshTimeValue = 4;
    }
    [sliderRefreshTime setIntegerValue:refreshTimeValue];
   
    [checkMonitoring setTitle:[NSString stringWithFormat:NSLocalizedString(@"sliderRefreshTimeLabel", nil), sliderRefreshTime.integerValue]];
    
    self.refreshTimer = [NSTimer timerWithTimeInterval:refreshTimeValue target:self selector:@selector(updateSensorValues) userInfo:nil repeats:YES];
    NSRunLoop * rl = [NSRunLoop mainRunLoop];
    [rl addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
    
    // Subscribe to sleep and wake up notifications
    [self fileNotifications];
    
    // Configure sensors view
    
    // Update monitoring state depending on monitoring enabled / disabled
    [self updateMonitoringState];
    
    // Assign the menu
    statusItem.menu = statusMenu;
    [self updateStatus];
}

// Invoked when the user clicks on the satus menu
- (void)statusItemClicked {
    statusItem.menu = statusMenu;
    [self updateStatus];
}

// Refresh status when the menu is clicked
- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu == statusMenu)
    {
        // Refresh status
        [self updateStatus];
    }
}

// Refresh the GUI general status, including enable/disable options, on-off status
- (void) updateStatus {
    
    // Check status from TurboBoostManager (single source of truth)
    // This ensures consistency when using Helper (XPC) mode
    isTurboBoostEnabled = [[TurboBoostManager sharedManager] isTurboBoostEnabled];
    
    NSLog(@"[AppDelegate] updateStatus: isTurboBoostEnabled=%@", isTurboBoostEnabled ? @"YES" : @"NO");
    
    if (isTurboBoostEnabled) {
        
        if ([StartupHelper isStatusOnOffEnabled]) {
            [statusOnOff setString:@"On"];
        } else {
            [statusOnOff setString:@""];
        }
        
        [enableDisableItem setTitle:NSLocalizedString(@"disable_menu", nil)];
        [statusItem setImage:statusImageOn];
        
    } else {
        
        if ([StartupHelper isStatusOnOffEnabled]) {
            [statusOnOff setString:@"Off"];
        } else {
            [statusOnOff setString:@""];
        }
        
        [enableDisableItem setTitle:NSLocalizedString(@"enable_menu", nil)];
        [statusItem setImage:statusImageOff];
    }
    
    // Refresh the title
    [self refreshTitleString];
    
}

// Method to get the battery charging status
- (BOOL) isCharging {
    
    CFTimeInterval timeInterval = IOPSGetTimeRemainingEstimate();
    if (timeInterval == -2.0) {
        return YES;
    } else {
        return NO;
    }
}

// Method to transform celsius value to fahrenheit
- (float) fahrenheitValue:(float) celsius {
    return ((celsius*1.8) + 32);
}

// Update the CPU Temp & Fan speed
- (void) updateSensorValues {
    
    // If monitoring is disabled, just exit
    if (![StartupHelper isMonitoringEnabled]) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[TurboBoostManager sharedManager] readSensorsWithCompletion:^(BOOL success, float temperature, float fanSpeed, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateSensorUIWithTemperature:temperature fanSpeed:(int)fanSpeed];
        });
    }];
    
    // CPU Load calculation (doesn't require privileges, can stay synchronous)
    [self updateCPULoad];
    
    // Refresh the title string
    [self refreshTitleString];
}

// Helper method to update sensor UI (only for chart data)
- (void) updateSensorUIWithTemperature:(float)cpuTemp fanSpeed:(int)fanSpeed {
    
    // Build display strings for chart
    NSString *tempString = nil;
    if (cpuTemp > 0) {
        tempString = [NSString stringWithFormat:@"%.00f ºC", cpuTemp];
    } else {
        tempString = @"N/A";
    }
    
    NSString *rpmData = nil;
    if (fanSpeed > 0) {
        rpmData = [NSString stringWithFormat:@"%d rpm", fanSpeed];
    } else {
        rpmData = @"N/A";
    }
    
    // Refresh the chart view if present
    BOOL isTbEnabled = [[TurboBoostManager sharedManager] isTurboBoostEnabled];
    NSLog(@"[AppDelegate] updateSensorUI: isTbEnabled=%@", isTbEnabled ? @"YES" : @"NO");
    
    if (self.chartWindowController != nil) {
        // Note: Fan chart is being removed, only temp is sent
        [self.chartWindowController addTempEntry:cpuTemp withCurrentValue:tempString isTbEnabled:isTbEnabled];
    }
}

// Helper method to update CPU load (for chart data)
- (void) updateCPULoad {
    
    double cpuLoadValue = -1;
    // Get the CPU Load
    if (sample_one.totalIdleTime == 0) {
        sample(true);
    } else {
        sample(false);
        
        struct cpusample delta;
        delta.totalSystemTime = sample_two.totalSystemTime - sample_one.totalSystemTime;
        delta.totalUserTime = sample_two.totalUserTime - sample_one.totalUserTime;
        delta.totalIdleTime = sample_two.totalIdleTime - sample_one.totalIdleTime;
        
        sample_one.totalSystemTime = sample_two.totalSystemTime;
        sample_one.totalUserTime = sample_two.totalUserTime;
        sample_one.totalIdleTime = sample_two.totalIdleTime;
        
        uint64_t total = delta.totalSystemTime + delta.totalUserTime + delta.totalIdleTime;
        
        double onePercent = total/100.0f;
        
        double cpuIdleValue = (double)delta.totalIdleTime/(double)onePercent;
        cpuLoadValue = 100.0 - cpuIdleValue;
    }
    
    // Update chart with CPU load data
    double finalCpuLoadValue = cpuLoadValue > 0 ? cpuLoadValue : 0;
    BOOL isTbEnabled = [[TurboBoostManager sharedManager] isTurboBoostEnabled];
    NSLog(@"[AppDelegate] updateCPULoad: isTbEnabled=%@", isTbEnabled ? @"YES" : @"NO");
        
    if (self.chartWindowController != nil) {
        if (finalCpuLoadValue > 0) {
            [self.chartWindowController addCpuLoadEntry:finalCpuLoadValue withCurrentValue:[NSString stringWithFormat:@"%.01f%%", finalCpuLoadValue] isTbEnabled:isTbEnabled];
        }
    }
    
    // Update CPU frequency for chart (async)
    if (self.chartWindowController != nil && self.chartWindowController.isOpen) {
        __weak typeof(self) weakSelf = self;
        [[TurboBoostManager sharedManager] readCPUFrequencyWithCompletion:^(BOOL success, float frequency, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL tbEnabled = [[TurboBoostManager sharedManager] isTurboBoostEnabled];
                if (success && frequency > 0) {
                    [weakSelf.chartWindowController addCpuFreqEntry:frequency withCurrentValue:[NSString stringWithFormat:@"%.01f GHz", frequency] isTbEnabled:tbEnabled];
                } else {
                    [weakSelf.chartWindowController addCpuFreqEntry:-1.0 withCurrentValue:@"N/A" isTbEnabled:tbEnabled];
                }
            });
        }];
    }
}

// Take one cpu sample
void sample(bool isOne) {
    
    kern_return_t kernelReturn;
    mach_msg_type_number_t msgType;
    host_cpu_load_info_data_t loadInfoData;
    
    msgType = HOST_CPU_LOAD_INFO_COUNT;
    kernelReturn = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (int *)&loadInfoData, &msgType);
    if (kernelReturn != KERN_SUCCESS) {
        printf("oops: %s\n", mach_error_string(kernelReturn));
        return;
    }
    
    if (isOne) {
        sample_one.totalSystemTime = loadInfoData.cpu_ticks[CPU_STATE_SYSTEM];
        sample_one.totalUserTime = loadInfoData.cpu_ticks[CPU_STATE_USER] + loadInfoData.cpu_ticks[CPU_STATE_NICE];
        sample_one.totalIdleTime = loadInfoData.cpu_ticks[CPU_STATE_IDLE];
    } else {
        sample_two.totalSystemTime = loadInfoData.cpu_ticks[CPU_STATE_SYSTEM];
        sample_two.totalUserTime = loadInfoData.cpu_ticks[CPU_STATE_USER] + loadInfoData.cpu_ticks[CPU_STATE_NICE];
        sample_two.totalIdleTime = loadInfoData.cpu_ticks[CPU_STATE_IDLE];
    }
    
}

// Method to switch between enabled and disables states
- (IBAction) enableTurboBoost:(id)sender {
    [self enableDisableTurboBoost];
}

// Enable / Disable turbo boost depending on current status
- (void) enableDisableTurboBoost {
    
    TurboBoostManager *manager = [TurboBoostManager sharedManager];
    [manager refreshStatus];
    
    if (manager.isTurboBoostEnabled) {
        [self disableTurboBoost];
    } else {
        [self enableTurboBoost];
    }
}

- (IBAction) exitItemEvent:(id)sender {
    
    // Re-enable Turbo Boost before exit app
    if ([SystemCommands isModuleLoaded]) {
        [self enableTurboBoost];
    }
    [[NSApplication sharedApplication] terminate:self];
    
}


// Loads the kernel module disabling turbo boost feature
- (void) disableTurboBoost {
    
    NSLog(@"[AppDelegate] disableTurboBoost called");
    
    [[TurboBoostManager sharedManager] disableTurboBoostWithCompletion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success && error) {
                NSLog(@"[AppDelegate] Failed to disable Turbo Boost: %@", error.localizedDescription);
            } else {
                NSLog(@"[AppDelegate] Turbo Boost disabled successfully");
            }
            [self updateStatus];
        });
    }];
}

// Unloads the kernel module enabling turbo boost feature
- (void) enableTurboBoost {
    
    NSLog(@"[AppDelegate] enableTurboBoost called");
    
    [[TurboBoostManager sharedManager] enableTurboBoostWithCompletion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success && error) {
                NSLog(@"[AppDelegate] Failed to enable Turbo Boost: %@", error.localizedDescription);
            } else {
                NSLog(@"[AppDelegate] Turbo Boost enabled successfully");
            }
            [self updateStatus];
        });
    }];
}

// Open about window
- (IBAction) about:(id)sender {
    if (self.aboutWindow == nil) {
        // Init the about window
        self.aboutWindow = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindowController"];
    }
    
    [self.aboutWindow.window setLevel:NSStatusWindowLevel];
    [self.aboutWindow.window center];
    [self.aboutWindow refreshDarkMode];
    [self.aboutWindow showWindow:nil];
}

// Enables/disables the open at login status
- (IBAction) openAtLogin:(id)sender {
   
    [StartupHelper setOpenAtLogin:![StartupHelper isOpenAtLogin]];
    
    // Refresh open at login item status
    [checkOpenAtLogin setState:[StartupHelper isOpenAtLogin]];
}

- (IBAction) disableAtLogin:(id)sender {
    
    [StartupHelper setDisableAtLaunch:[checkDisableAtLaunch state]];
}

// Method to refresh the status bar title string
- (void) refreshTitleString {
    
    // Attributes for title string
    NSFont *labelFont = nil;
    if (@available(*, macOS 10.11)) {
        labelFont = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
    } else {
        labelFont = [NSFont fontWithName:@"Helvetica" size:11];
    }
    
    // Final title string
    NSMutableString *finalString = [[NSMutableString alloc] initWithString:@""];
    
    [finalString appendString:statusOnOff];
    
    // Refresh the title
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:finalString attributes:@{NSFontAttributeName : labelFont}];
    [statusItem setAttributedTitle:attributedTitle];
}

// On / Off check click
- (IBAction) onOffClick:(id)sender {
    
    [StartupHelper storeStatusOnOffEnabled:[checkOnOffText state] == NSOnState];
    
    // Refresh the title string
    [self updateStatus];
    [self updateSensorValues];
    
}

- (void) terminate {
    [[NSApplication sharedApplication] terminate:self];
}

// Relaunch after delay
- (void)relaunchAfterDelay:(float)seconds
{
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:[NSString stringWithFormat:@"sleep %f; open \"%@\"", seconds, [[NSBundle mainBundle] bundlePath]]];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    [task launch];
    
    [self terminate];
}

// Refresh time slider
- (IBAction) refreshTimeSliderChanged:(id)sender {
    
    [checkMonitoring setTitle:[NSString stringWithFormat:NSLocalizedString(@"sliderRefreshTimeLabel", nil), sliderRefreshTime.integerValue]];
    
    [self.refreshTimer invalidate];
    
    NSRunLoop * rl = [NSRunLoop mainRunLoop];
    
    // Timer to update the sensor readings (cpu & fan rpm) each 4 seconds
    NSInteger timerValue = sliderRefreshTime.integerValue;
    if (timerValue < 4) {
        timerValue = 4;
    }
    self.refreshTimer = [NSTimer timerWithTimeInterval:timerValue target:self selector:@selector(updateSensorValues) userInfo:nil repeats:YES];
    [rl addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
    
    [StartupHelper storeSensorRefreshTime:timerValue];
}

// Charts menu click
- (IBAction) chartsMenuClick:(id) sender {
    [self openChartWindow];
}

// Open chart window
- (void) openChartWindow {
    
    // Bring window to front
    [NSApp activateIgnoringOtherApps:YES];
    
    if (self.chartWindowController == nil) {
        self.chartWindowController = [[ChartWindowController alloc] initWithWindowNibName:@"ChartWindowController"];
        [self.chartWindowController initData];
    }
    
    // Show!
    [self.chartWindowController.window setLevel:NSStatusWindowLevel];
    [self.chartWindowController.window center];
    [self.chartWindowController showWindow:nil];
    
    self.chartWindowController.isOpen = YES;
    
}

// Get the current battery level
- (double) currentBatteryLevel
{
    
    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
    
    CFDictionaryRef pSource = NULL;
    const void *psValue;
    
    long numOfSources = CFArrayGetCount(sources);
    if (numOfSources == 0) {
        if (sources) {
            CFRelease(sources);
        }
        if (blob) {
            CFRelease(blob);
        }
        return -1.0f;
    }
    
    for (int i = 0 ; i < numOfSources ; i++)
    {
        pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
        if (!pSource) {
            if (sources) {
                CFRelease(sources);
            }
            if (blob) {
                CFRelease(blob);
            }
            return -1.0f;
        }
        
        psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));
        
        int curCapacity = 0;
        int maxCapacity = 0;
        
        double percent;
        
        // Gets the battery capacity
        psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
        CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
        
        // Gets the max capacity
        psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
        CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
        
        percent = ((double)curCapacity/(double)maxCapacity * 100.0f);
        
        if (sources) {
            CFRelease(sources);
        }
        if (blob) {
            CFRelease(blob);
        }
        return percent;
    }
    
    if (sources) {
        CFRelease(sources);
    }
    if (blob) {
        CFRelease(blob);
    }
    
    return -1.0f;
}

- (IBAction) checkMonitoringClick:(id) sender {
    [StartupHelper storeMonitoringEnabled:[checkMonitoring state] == NSOnState];
    [self updateMonitoringState];
}
    
// Update monitoring app state
- (void) updateMonitoringState {
    
    BOOL isMonitoringEnabled = [StartupHelper isMonitoringEnabled];
    
    if (isMonitoringEnabled) {
        
        // Reenable timer
        [self refreshTimeSliderChanged:nil];
        
        // Refresh title string and status bar
        [self updateSensorValues];
        
    } else {
        
        [self updateStatus];
        
        // Invalidate timer
        [self.refreshTimer invalidate];
    }
    
    // Enable/Disable charts
    [chartsMenuItem setEnabled:isMonitoringEnabled];
    
    // Disable refresh time slider
    [sliderRefreshTime setEnabled:isMonitoringEnabled];
    
}
- (void) refreshAuthRef {
    
    if (authorizationRef == NULL) {
        
        OSStatus status = AuthorizationCreate(NULL,
                                              kAuthorizationEmptyEnvironment,
                                              kAuthorizationFlagDefaults,
                                              &authorizationRef);
        
        AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
        AuthorizationRights rights = {1, &right};
        AuthorizationFlags flags = kAuthorizationFlagDefaults |
        kAuthorizationFlagInteractionAllowed |
        kAuthorizationFlagPreAuthorize |
        kAuthorizationFlagExtendRights;
        
        status = AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);
        if (status != errAuthorizationSuccess)
            NSLog(@"Copy Rights Unsuccessful: %d", status);
        
    }
}


@end
