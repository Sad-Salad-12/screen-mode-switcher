// Runs the real asynchronous script runner with harmless scripts. No system
// settings are written and no administrator authorization is requested.
#define main ScreenModeSwitcherApplicationMain
#import "../src/ScreenModeSwitcher.m"
#undef main

@interface SMAuthSmokeDelegate : SMAppDelegate
@property(nonatomic, copy) NSString *testResult;
@property(nonatomic) SMScreenMode simulatedMode;
@property(nonatomic) NSInteger scriptsStarted;
@end

@implementation SMAuthSmokeDelegate
- (NSString *)authorizationScriptForMode:(SMScreenMode)target {
    self.scriptsStarted += 1;
    return [NSString stringWithFormat:@"delay 0.2\nreturn \"%@\"", self.testResult];
}
- (SMScreenMode)readCurrentMode {
    return self.simulatedMode;
}
@end

static void Require(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        exit(1);
    }
}

static NSInteger RunUntilFinished(SMAuthSmokeDelegate *delegate) {
    __block NSInteger responsiveTicks = 0;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                   repeats:YES
                                                     block:^(NSTimer * __unused tick) {
        if (delegate.authorizationTask.running) responsiveTicks += 1;
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:8];
    while (delegate.applying && deadline.timeIntervalSinceNow > 0) {
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
                              beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    }
    [timer invalidate];
    Require(!delegate.applying, @"script completion must restore usable controls");
    Require(delegate.authorizationTask == nil, @"completed runner must be released");
    return responsiveTicks;
}

int main(void) {
    @autoreleasepool {
        [NSApplication.sharedApplication setActivationPolicy:NSApplicationActivationPolicyProhibited];

        SMAppDelegate *production = [[SMAppDelegate alloc] init];
        for (NSNumber *mode in @[@(SMScreenModeNormal), @(SMScreenModeNeverOff)]) {
            NSAppleScript *script = [[NSAppleScript alloc]
                initWithSource:[production authorizationScriptForMode:mode.integerValue]];
            NSDictionary *error = nil;
            Require([script compileAndReturnError:&error],
                [NSString stringWithFormat:@"production authorization script compiles: %@", error]);
        }

        SMAuthSmokeDelegate *delegate = [[SMAuthSmokeDelegate alloc] init];
        delegate.statusLabel = [NSTextField labelWithString:@""];
        delegate.statusDot = [[SMStatusDot alloc] init];
        delegate.menuModeSwitch = [NSSegmentedControl segmentedControlWithLabels:
            @[@"Normal", @"Never"] trackingMode:NSSegmentSwitchTrackingSelectOne
            target:nil action:nil];
        delegate.simulatedMode = SMScreenModeNeverOff;
        delegate.testResult = @"SM_ERROR:-128:User canceled.";
        [delegate displayMode:SMScreenModeNeverOff];

        [delegate applyMode:SMScreenModeNormal];
        [delegate applyMode:SMScreenModeNormal];
        Require(delegate.applying, @"pending authorization guards against duplicate requests");
        Require(!delegate.menuModeSwitch.enabled, @"switch is disabled while authorizing");

        NSTimer *trackingTimer = [NSTimer timerWithTimeInterval:0.01 repeats:YES
                                                       block:^(NSTimer * __unused timer) {}];
        [NSRunLoop.currentRunLoop addTimer:trackingTimer forMode:NSEventTrackingRunLoopMode];
        NSDate *trackingEnd = [NSDate dateWithTimeIntervalSinceNow:0.15];
        while (trackingEnd.timeIntervalSinceNow > 0) {
            [NSRunLoop.currentRunLoop runMode:NSEventTrackingRunLoopMode beforeDate:trackingEnd];
        }
        [trackingTimer invalidate];
        Require(delegate.scriptsStarted == 0,
            @"authorization must not start inside the menu-tracking loop");
        Require(RunUntilFinished(delegate) > 2,
            @"main event loop must remain responsive while script runner waits");
        Require(delegate.scriptsStarted == 1, @"one click sequence must launch only one runner");
        Require([delegate.statusLabel.stringValue isEqualToString:@"已取消，没有修改设置"],
            @"user cancellation is not reported as failure");
        Require(delegate.menuModeSwitch.selectedSegment == 1 && delegate.menuModeSwitch.enabled,
            @"cancellation restores the actual mode and enables the switch");

        delegate.testResult = @"SM_ERROR:42:synthetic failure";
        [delegate applyMode:SMScreenModeNormal];
        RunUntilFinished(delegate);
        Require([delegate.statusLabel.stringValue isEqualToString:@"切换失败：synthetic failure"],
            @"authorization errors show the useful message and restore controls");

        delegate.testResult = @"SM_OK";
        delegate.simulatedMode = SMScreenModeNormal;
        [delegate applyMode:SMScreenModeNormal];
        RunUntilFinished(delegate);
        Require(delegate.currentMode == SMScreenModeNormal && delegate.menuModeSwitch.selectedSegment == 0,
            @"successful authorization updates the verified mode");
        Require([delegate.statusLabel.stringValue isEqualToString:@"已切换到正常模式"],
            @"successful authorization shows completion");

        puts("PASS: production scripts compile; menu tracking defers authorization; UI remains responsive; duplicate, cancellation, error, and success paths work.");
    }
    return 0;
}
