#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

// Match AppKit's default identity for this app's single menu-bar item. Keeping
// it stable also avoids changing Control Center's host identity on macOS 26.
static NSString * const SMMenuBarAutosaveName = @"Item-0";

typedef NS_ENUM(NSInteger, SMScreenMode) {
    SMScreenModeNormal = 0,
    SMScreenModeNeverOff = 1,
    SMScreenModeCustom = 2
};

@interface SMStatusDot : NSView
@property(nonatomic, strong) NSColor *dotColor;
@end

@implementation SMStatusDot
- (instancetype)init {
    self = [super initWithFrame:NSMakeRect(0, 0, 8, 8)];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 4;
        self.dotColor = NSColor.secondaryLabelColor;
    }
    return self;
}

- (void)setDotColor:(NSColor *)dotColor {
    _dotColor = dotColor;
    self.layer.backgroundColor = dotColor.CGColor;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(8, 8);
}
@end

@interface SMModeButton : NSButton
@property(nonatomic, strong) NSTextField *modeTitle;
@property(nonatomic, strong) NSTextField *modeSubtitle;
@property(nonatomic, strong) NSImageView *modeIcon;
@property(nonatomic, strong) NSImageView *checkIcon;
@property(nonatomic, strong) NSColor *tintColor;
@property(nonatomic) BOOL modeSelected;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                  systemImage:(NSString *)systemImage
                         tint:(NSColor *)tint;
- (void)setModeSelected:(BOOL)selected;
@end

@implementation SMModeButton
- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                  systemImage:(NSString *)systemImage
                         tint:(NSColor *)tint {
    self = [super initWithFrame:NSZeroRect];
    if (!self) return nil;

    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.wantsLayer = YES;
    self.layer.cornerRadius = 18;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.layer.borderWidth = 1;
    self.bordered = NO;
    self.title = @"";
    self.imagePosition = NSNoImage;
    self.tintColor = tint;
    self.focusRingType = NSFocusRingTypeExterior;
    self.accessibilityLabel = title;
    self.accessibilityHelp = subtitle;

    _modeIcon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    _modeIcon.translatesAutoresizingMaskIntoConstraints = NO;
    _modeIcon.image = [NSImage imageWithSystemSymbolName:systemImage
                               accessibilityDescription:title];
    _modeIcon.symbolConfiguration =
        [NSImageSymbolConfiguration configurationWithPointSize:24
                                                         weight:NSFontWeightSemibold];
    _modeIcon.contentTintColor = tint;

    _checkIcon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    _checkIcon.translatesAutoresizingMaskIntoConstraints = NO;
    _checkIcon.image = [NSImage imageWithSystemSymbolName:@"checkmark.circle.fill"
                                accessibilityDescription:@"当前模式"];
    _checkIcon.symbolConfiguration =
        [NSImageSymbolConfiguration configurationWithPointSize:17
                                                         weight:NSFontWeightSemibold];
    _checkIcon.contentTintColor = NSColor.whiteColor;
    _checkIcon.hidden = YES;

    _modeTitle = [NSTextField labelWithString:title];
    _modeTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _modeTitle.font = [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold];
    _modeTitle.textColor = NSColor.labelColor;

    _modeSubtitle = [NSTextField wrappingLabelWithString:subtitle];
    _modeSubtitle.translatesAutoresizingMaskIntoConstraints = NO;
    _modeSubtitle.font = [NSFont systemFontOfSize:12.5 weight:NSFontWeightRegular];
    _modeSubtitle.textColor = NSColor.secondaryLabelColor;
    _modeSubtitle.maximumNumberOfLines = 2;

    for (NSView *view in @[_modeIcon, _checkIcon, _modeTitle, _modeSubtitle]) {
        [self addSubview:view];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.heightAnchor constraintEqualToConstant:152],
        [_modeIcon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:18],
        [_modeIcon.topAnchor constraintEqualToAnchor:self.topAnchor constant:18],
        [_modeIcon.widthAnchor constraintEqualToConstant:28],
        [_modeIcon.heightAnchor constraintEqualToConstant:28],
        [_checkIcon.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-18],
        [_checkIcon.centerYAnchor constraintEqualToAnchor:_modeIcon.centerYAnchor],
        [_checkIcon.widthAnchor constraintEqualToConstant:19],
        [_checkIcon.heightAnchor constraintEqualToConstant:19],
        [_modeTitle.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:18],
        [_modeTitle.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-18],
        [_modeTitle.topAnchor constraintEqualToAnchor:_modeIcon.bottomAnchor constant:18],
        [_modeSubtitle.leadingAnchor constraintEqualToAnchor:_modeTitle.leadingAnchor],
        [_modeSubtitle.trailingAnchor constraintEqualToAnchor:_modeTitle.trailingAnchor],
        [_modeSubtitle.topAnchor constraintEqualToAnchor:_modeTitle.bottomAnchor constant:5]
    ]];

    [self updateAppearance];
    return self;
}

- (void)setModeSelected:(BOOL)selected {
    if (_modeSelected == selected) return;
    _modeSelected = selected;
    self.accessibilityValue = selected ? @"当前模式" : @"未选择";

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.22;
        self.animator.alphaValue = selected ? 1.0 : 0.96;
    } completionHandler:^{
        self.alphaValue = 1.0;
    }];

    [self updateAppearance];
}

- (void)updateAppearance {
    if (self.modeSelected) {
        self.layer.backgroundColor = self.tintColor.CGColor;
        self.layer.borderColor = NSColor.clearColor.CGColor;
        self.layer.shadowColor = self.tintColor.CGColor;
        self.layer.shadowOpacity = 0.22;
        self.layer.shadowRadius = 13;
        self.layer.shadowOffset = NSMakeSize(0, -6);
        self.modeIcon.contentTintColor = NSColor.whiteColor;
        self.modeTitle.textColor = NSColor.whiteColor;
        self.modeSubtitle.textColor = [NSColor.whiteColor colorWithAlphaComponent:0.78];
        self.checkIcon.hidden = NO;
    } else {
        self.layer.backgroundColor = NSColor.controlBackgroundColor.CGColor;
        self.layer.borderColor =
            [NSColor.separatorColor colorWithAlphaComponent:0.45].CGColor;
        self.layer.shadowOpacity = 0;
        self.modeIcon.contentTintColor = self.tintColor;
        self.modeTitle.textColor = NSColor.labelColor;
        self.modeSubtitle.textColor = NSColor.secondaryLabelColor;
        self.checkIcon.hidden = YES;
    }
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    [self updateAppearance];
}

- (void)mouseDown:(NSEvent *)event {
    if (!self.enabled) return;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.09;
        self.animator.alphaValue = 0.72;
    }];
    [super mouseDown:event];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.14;
        self.animator.alphaValue = 1.0;
    }];
}
@end

@interface SMAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenu *statusMenu;
@property(nonatomic, strong) NSMenuItem *menuStatusItem;
@property(nonatomic, strong) NSSegmentedControl *menuModeSwitch;
@property(nonatomic, strong) NSMenuItem *menuLaunchItem;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) SMStatusDot *statusDot;
@property(nonatomic, strong) SMModeButton *normalButton;
@property(nonatomic, strong) SMModeButton *neverButton;
@property(nonatomic, strong) NSProgressIndicator *progress;
@property(nonatomic, strong) NSButton *refreshButton;
@property(nonatomic, strong) NSSwitch *launchAtLoginSwitch;
@property(nonatomic, strong) NSTextField *launchAtLoginDetail;
@property(nonatomic, strong) NSTask *authorizationTask;
@property(nonatomic) SMScreenMode currentMode;
@property(nonatomic) BOOL applying;

- (void)verifyMode:(SMScreenMode)target attempt:(NSInteger)attempt;
- (void)syncMenuBarState;
- (void)syncLaunchAtLoginState;
- (NSString *)authorizationScriptForMode:(SMScreenMode)target;
- (void)beginAuthorizationForMode:(NSNumber *)mode;
@end

@implementation SMAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [self buildMenu];
    [self buildWindow];
    [self buildStatusItem];
    [self refresh:nil];
    [self syncLaunchAtLoginState];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.authorizationTask.running) {
        [self.authorizationTask terminate];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                    hasVisibleWindows:(BOOL)hasVisibleWindows {
    [self showControlPanel:nil];
    return YES;
}

- (void)buildMenu {
    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];

    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"屏幕模式切换"];
    [appMenu addItemWithTitle:@"退出屏幕模式切换"
                       action:@selector(terminate:)
                keyEquivalent:@"q"];
    appMenuItem.submenu = appMenu;
    NSApp.mainMenu = mainMenu;
}

- (void)buildStatusItem {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    // AppKit has no public ordering-priority API. Seed its persisted preferred
    // position before creating the item: zero requests the rightmost available
    // slot. This is a placement preference, not a guarantee over system items.
    [defaults setDouble:0 forKey:[@"NSStatusItem Preferred Position "
        stringByAppendingString:SMMenuBarAutosaveName]];
    [defaults setBool:YES forKey:[@"NSStatusItem Visible "
        stringByAppendingString:SMMenuBarAutosaveName]];
    if (@available(macOS 26.0, *)) {
        [defaults setBool:YES forKey:[@"NSStatusItem VisibleCC "
            stringByAppendingString:SMMenuBarAutosaveName]];
    }
    [defaults synchronize];

    self.statusItem = [NSStatusBar.systemStatusBar
        statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.autosaveName = SMMenuBarAutosaveName;
    self.statusItem.visible = YES;
    NSStatusBarButton *button = self.statusItem.button;
    button.target = self;
    button.action = @selector(statusItemClicked:);
    [button sendActionOn:NSEventMaskLeftMouseUp];
    button.toolTip = @"屏幕模式切换｜单击快速切换，双击打开控制面板";

    self.statusMenu = [[NSMenu alloc] initWithTitle:@"屏幕模式切换"];
    self.statusMenu.autoenablesItems = NO;

    self.menuStatusItem = [[NSMenuItem alloc] initWithTitle:@"正在读取状态…"
                                                    action:nil
                                             keyEquivalent:@""];
    self.menuStatusItem.enabled = NO;
    [self.statusMenu addItem:self.menuStatusItem];
    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSView *switchContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 268, 52)];
    self.menuModeSwitch = [NSSegmentedControl
        segmentedControlWithLabels:@[@"正常模式", @"屏幕常亮"]
                   trackingMode:NSSegmentSwitchTrackingSelectOne
                          target:self
                          action:@selector(menuModeChanged:)];
    self.menuModeSwitch.frame = NSMakeRect(14, 10, 240, 32);
    self.menuModeSwitch.segmentStyle = NSSegmentStyleTexturedRounded;
    self.menuModeSwitch.toolTip = @"选择屏幕模式";
    [self.menuModeSwitch setImage:
        [NSImage imageWithSystemSymbolName:@"clock.arrow.circlepath"
                 accessibilityDescription:@"正常模式"]
                      forSegment:0];
    [self.menuModeSwitch setImage:
        [NSImage imageWithSystemSymbolName:@"sun.max.fill"
                 accessibilityDescription:@"屏幕常亮"]
                      forSegment:1];
    [switchContainer addSubview:self.menuModeSwitch];

    NSMenuItem *switchItem = [[NSMenuItem alloc] init];
    switchItem.view = switchContainer;
    [self.statusMenu addItem:switchItem];
    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *openItem = [[NSMenuItem alloc]
        initWithTitle:@"打开控制面板…"
               action:@selector(showControlPanel:)
        keyEquivalent:@","];
    openItem.target = self;
    [self.statusMenu addItem:openItem];

    self.menuLaunchItem = [[NSMenuItem alloc]
        initWithTitle:@"登录时自动启动"
               action:@selector(toggleLaunchAtLoginFromMenu:)
        keyEquivalent:@""];
    self.menuLaunchItem.target = self;
    [self.statusMenu addItem:self.menuLaunchItem];
    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc]
        initWithTitle:@"退出屏幕模式切换"
               action:@selector(terminate:)
        keyEquivalent:@"q"];
    [self.statusMenu addItem:quitItem];
}

- (void)statusItemClicked:(id)sender {
    NSInteger clickCount = NSApp.currentEvent.clickCount;
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(showStatusMenu)
                                               object:nil];

    if (clickCount >= 2) {
        [self showControlPanel:nil];
        return;
    }

    [self performSelector:@selector(showStatusMenu)
               withObject:nil
               afterDelay:NSEvent.doubleClickInterval];
}

- (void)showStatusMenu {
    [self refresh:nil];
    [self syncLaunchAtLoginState];
    self.statusItem.menu = self.statusMenu;
    [self.statusItem.button performClick:nil];
    self.statusItem.menu = nil;
}

- (void)showControlPanel:(id)sender {
    [self refresh:nil];
    [self syncLaunchAtLoginState];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)menuModeChanged:(NSSegmentedControl *)sender {
    if (self.applying) return;
    NSInteger selected = sender.selectedSegment;
    if (selected < 0) return;
    [self.statusMenu cancelTrackingWithoutAnimation];

    SMScreenMode target = selected == 0
        ? SMScreenModeNormal
        : SMScreenModeNeverOff;
    if (target == self.currentMode) {
        [self syncMenuBarState];
        return;
    }
    [self applyMode:target];
}

- (void)toggleLaunchAtLogin:(NSSwitch *)sender {
    [self setLaunchAtLoginEnabled:(sender.state == NSControlStateValueOn)];
}

- (void)toggleLaunchAtLoginFromMenu:(NSMenuItem *)sender {
    BOOL currentlyRegistered =
        SMAppService.mainAppService.status == SMAppServiceStatusEnabled ||
        SMAppService.mainAppService.status == SMAppServiceStatusRequiresApproval;
    [self setLaunchAtLoginEnabled:!currentlyRegistered];
}

- (void)setLaunchAtLoginEnabled:(BOOL)enabled {
    SMAppService *service = SMAppService.mainAppService;
    NSError *error = nil;
    BOOL succeeded = YES;

    if (enabled) {
        if (service.status == SMAppServiceStatusNotRegistered ||
            service.status == SMAppServiceStatusNotFound) {
            succeeded = [service registerAndReturnError:&error];
        }
    } else {
        if (service.status == SMAppServiceStatusEnabled ||
            service.status == SMAppServiceStatusRequiresApproval) {
            succeeded = [service unregisterAndReturnError:&error];
        }
    }

    [self syncLaunchAtLoginState];

    if (!succeeded) {
        self.launchAtLoginDetail.stringValue = [NSString stringWithFormat:
            @"无法更改：%@", error.localizedDescription ?: @"未知错误"];
        self.launchAtLoginDetail.textColor = NSColor.systemRedColor;
        [self showControlPanel:nil];
        return;
    }

    if (service.status == SMAppServiceStatusRequiresApproval) {
        self.launchAtLoginDetail.stringValue =
            @"需要在“系统设置 > 登录项”中批准";
        self.launchAtLoginDetail.textColor = NSColor.systemOrangeColor;
        [SMAppService openSystemSettingsLoginItems];
    }
}

- (void)syncLaunchAtLoginState {
    SMAppServiceStatus status = SMAppService.mainAppService.status;
    BOOL registered = status == SMAppServiceStatusEnabled ||
                      status == SMAppServiceStatusRequiresApproval;

    self.launchAtLoginSwitch.state = registered
        ? NSControlStateValueOn
        : NSControlStateValueOff;
    self.menuLaunchItem.state = status == SMAppServiceStatusEnabled
        ? NSControlStateValueOn
        : (status == SMAppServiceStatusRequiresApproval
            ? NSControlStateValueMixed
            : NSControlStateValueOff);

    self.launchAtLoginDetail.textColor = NSColor.secondaryLabelColor;
    switch (status) {
        case SMAppServiceStatusEnabled:
            self.launchAtLoginDetail.stringValue =
                @"已开启：登录后自动驻留在菜单栏";
            break;
        case SMAppServiceStatusRequiresApproval:
            self.launchAtLoginDetail.stringValue =
                @"等待在系统设置中批准";
            self.launchAtLoginDetail.textColor = NSColor.systemOrangeColor;
            break;
        default:
            self.launchAtLoginDetail.stringValue =
                @"开机登录后驻留在菜单栏，不自动弹出窗口";
            break;
    }
}

- (void)buildWindow {
    self.window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 500, 420)
                  styleMask:NSWindowStyleMaskTitled |
                            NSWindowStyleMaskClosable |
                            NSWindowStyleMaskMiniaturizable
                    backing:NSBackingStoreBuffered
                      defer:NO];
    self.window.title = @"屏幕模式切换";
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    self.window.backgroundColor = NSColor.windowBackgroundColor;
    self.window.releasedWhenClosed = NO;
    [self.window center];

    NSView *content = self.window.contentView;

    NSTextField *heading = [NSTextField labelWithString:@"屏幕模式"];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    heading.font = [NSFont systemFontOfSize:28 weight:NSFontWeightBold];

    self.statusDot = [[SMStatusDot alloc] init];
    self.statusDot.translatesAutoresizingMaskIntoConstraints = NO;

    self.statusLabel = [NSTextField labelWithString:@"正在读取当前设置…"];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    self.statusLabel.textColor = NSColor.secondaryLabelColor;

    self.refreshButton = [NSButton buttonWithImage:
        [NSImage imageWithSystemSymbolName:@"arrow.clockwise"
                 accessibilityDescription:@"刷新状态"]
                                           target:self
                                           action:@selector(refresh:)];
    self.refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.refreshButton.bordered = NO;
    self.refreshButton.contentTintColor = NSColor.secondaryLabelColor;
    self.refreshButton.toolTip = @"刷新状态";

    self.normalButton =
        [[SMModeButton alloc] initWithTitle:@"正常模式"
                                  subtitle:@"使用正常息屏与睡眠时间预设"
                               systemImage:@"clock.arrow.circlepath"
                                      tint:NSColor.systemBlueColor];
    self.normalButton.tag = SMScreenModeNormal;
    self.normalButton.target = self;
    self.normalButton.action = @selector(modeClicked:);

    self.neverButton =
        [[SMModeButton alloc] initWithTitle:@"永不熄屏"
                                  subtitle:@"电池和电源状态下都保持亮屏"
                               systemImage:@"sun.max.fill"
                                      tint:NSColor.systemOrangeColor];
    self.neverButton.tag = SMScreenModeNeverOff;
    self.neverButton.target = self;
    self.neverButton.action = @selector(modeClicked:);

    NSStackView *buttonStack =
        [NSStackView stackViewWithViews:@[self.normalButton, self.neverButton]];
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    buttonStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    buttonStack.spacing = 14;
    buttonStack.distribution = NSStackViewDistributionFillEqually;

    self.progress = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    self.progress.translatesAutoresizingMaskIntoConstraints = NO;
    self.progress.style = NSProgressIndicatorStyleSpinning;
    self.progress.controlSize = NSControlSizeSmall;
    self.progress.displayedWhenStopped = NO;

    NSBox *settingsDivider = [[NSBox alloc] initWithFrame:NSZeroRect];
    settingsDivider.translatesAutoresizingMaskIntoConstraints = NO;
    settingsDivider.boxType = NSBoxSeparator;

    NSTextField *launchAtLoginTitle =
        [NSTextField labelWithString:@"登录时自动启动"];
    launchAtLoginTitle.translatesAutoresizingMaskIntoConstraints = NO;
    launchAtLoginTitle.font =
        [NSFont systemFontOfSize:13.5 weight:NSFontWeightMedium];

    self.launchAtLoginDetail = [NSTextField labelWithString:
        @"开机登录后驻留在菜单栏，不自动弹出窗口"];
    self.launchAtLoginDetail.translatesAutoresizingMaskIntoConstraints = NO;
    self.launchAtLoginDetail.font = [NSFont systemFontOfSize:11.5];
    self.launchAtLoginDetail.textColor = NSColor.secondaryLabelColor;

    self.launchAtLoginSwitch = [[NSSwitch alloc] initWithFrame:NSZeroRect];
    self.launchAtLoginSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.launchAtLoginSwitch.target = self;
    self.launchAtLoginSwitch.action = @selector(toggleLaunchAtLogin:);
    self.launchAtLoginSwitch.accessibilityLabel = @"登录时自动启动";

    NSImageView *footerIcon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    footerIcon.translatesAutoresizingMaskIntoConstraints = NO;
    footerIcon.image = [NSImage imageWithSystemSymbolName:@"lock.shield"
                                accessibilityDescription:@"锁屏不受影响"];
    footerIcon.contentTintColor = NSColor.secondaryLabelColor;

    NSTextField *footer = [NSTextField wrappingLabelWithString:
        @"切换时会要求管理员授权；合盖、手动锁屏和锁屏密码策略不受影响。"];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.font = [NSFont systemFontOfSize:11.5];
    footer.textColor = NSColor.secondaryLabelColor;

    for (NSView *view in @[
        heading, self.statusDot, self.statusLabel, self.refreshButton,
        buttonStack, settingsDivider, launchAtLoginTitle,
        self.launchAtLoginDetail, self.launchAtLoginSwitch,
        self.progress, footerIcon, footer
    ]) {
        [content addSubview:view];
    }

    [NSLayoutConstraint activateConstraints:@[
        [heading.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:26],
        [heading.topAnchor constraintEqualToAnchor:content.topAnchor constant:28],
        [self.statusDot.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.statusDot.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:11],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.statusDot.trailingAnchor
                                                       constant:8],
        [self.statusLabel.centerYAnchor constraintEqualToAnchor:self.statusDot.centerYAnchor],
        [self.refreshButton.trailingAnchor constraintEqualToAnchor:content.trailingAnchor
                                                          constant:-26],
        [self.refreshButton.centerYAnchor constraintEqualToAnchor:heading.centerYAnchor],
        [self.refreshButton.widthAnchor constraintEqualToConstant:30],
        [self.refreshButton.heightAnchor constraintEqualToConstant:30],
        [buttonStack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:26],
        [buttonStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-26],
        [buttonStack.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:24],
        [settingsDivider.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:26],
        [settingsDivider.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-26],
        [settingsDivider.topAnchor constraintEqualToAnchor:buttonStack.bottomAnchor constant:20],
        [launchAtLoginTitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:27],
        [launchAtLoginTitle.topAnchor constraintEqualToAnchor:settingsDivider.bottomAnchor constant:17],
        [self.launchAtLoginDetail.leadingAnchor constraintEqualToAnchor:launchAtLoginTitle.leadingAnchor],
        [self.launchAtLoginDetail.topAnchor constraintEqualToAnchor:launchAtLoginTitle.bottomAnchor constant:4],
        [self.launchAtLoginSwitch.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-27],
        [self.launchAtLoginSwitch.centerYAnchor constraintEqualToAnchor:launchAtLoginTitle.centerYAnchor],
        [self.progress.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:27],
        [self.progress.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-25],
        [self.progress.widthAnchor constraintEqualToConstant:14],
        [self.progress.heightAnchor constraintEqualToConstant:14],
        [footerIcon.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:27],
        [footerIcon.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-25],
        [footerIcon.widthAnchor constraintEqualToConstant:14],
        [footerIcon.heightAnchor constraintEqualToConstant:14],
        [footer.leadingAnchor constraintEqualToAnchor:footerIcon.trailingAnchor constant:8],
        [footer.trailingAnchor constraintLessThanOrEqualToAnchor:content.trailingAnchor
                                                       constant:-26],
        [footer.centerYAnchor constraintEqualToAnchor:footerIcon.centerYAnchor]
    ]];
}

- (void)modeClicked:(SMModeButton *)sender {
    if (self.applying) return;
    SMScreenMode target = (SMScreenMode)sender.tag;

    if (target == self.currentMode) {
        NSString *title = target == SMScreenModeNormal ? @"正常模式" : @"永不熄屏";
        NSColor *color = target == SMScreenModeNormal
            ? NSColor.systemBlueColor
            : NSColor.systemOrangeColor;
        [self setStatus:[@"已经是" stringByAppendingString:title]
                 color:color
                 error:NO];
        return;
    }

    [self applyMode:target];
}

- (void)setApplying:(BOOL)applying {
    _applying = applying;
    self.normalButton.enabled = !applying;
    self.neverButton.enabled = !applying;
    self.refreshButton.enabled = !applying;
    self.menuModeSwitch.enabled = !applying;
    self.normalButton.alphaValue = applying ? 0.68 : 1.0;
    self.neverButton.alphaValue = applying ? 0.68 : 1.0;

    if (applying) {
        [self.progress startAnimation:nil];
    } else {
        [self.progress stopAnimation:nil];
    }
}

- (void)applyMode:(SMScreenMode)target {
    if (self.applying) return;
    self.applying = YES;
    [self setStatus:@"正在等待管理员授权…"
             color:NSColor.secondaryLabelColor
             error:NO];

    // A main-queue block can run inside AppKit's nested menu-tracking loop.
    // Use a default-mode timer so authorization starts only after that loop
    // has unwound and the status menu has released keyboard focus.
    [self performSelector:@selector(beginAuthorizationForMode:)
               withObject:@(target)
               afterDelay:0
                  inModes:@[NSDefaultRunLoopMode]];
}

- (NSString *)authorizationScriptForMode:(SMScreenMode)target {

    NSString *powerCommand = target == SMScreenModeNormal
        ? @"/usr/bin/pmset -b displaysleep 2 sleep 1 && /usr/bin/pmset -c displaysleep 10 sleep 1"
        : @"/usr/bin/pmset -a displaysleep 0 sleep 0";
    NSInteger saverSeconds = target == SMScreenModeNormal ? 300 : 0;

    NSString *escapedUser =
        [NSUserName() stringByReplacingOccurrencesOfString:@"'"
                                                withString:@"'\\''"];
    NSString *userDefaultsCommand = [NSString stringWithFormat:
        @"/usr/bin/sudo -H -u '%@' /usr/bin/defaults -currentHost write com.apple.screensaver idleTime -int %ld",
        escapedUser, (long)saverSeconds];
    NSString *verifyCommand = [NSString stringWithFormat:
        @"test \"$(/usr/bin/sudo -H -u '%@' /usr/bin/defaults -currentHost read com.apple.screensaver idleTime)\" = \"%ld\"",
        escapedUser, (long)saverSeconds];
    NSString *adminCommand = [NSString stringWithFormat:@"%@ && %@ && %@",
        powerCommand, userDefaultsCommand, verifyCommand];

    NSString *escaped =
        [[adminCommand stringByReplacingOccurrencesOfString:@"\\"
                                                  withString:@"\\\\"]
            stringByReplacingOccurrencesOfString:@"\""
                                      withString:@"\\\""];
    return [NSString stringWithFormat:
        @"try\n"
         "    do shell script \"%@\" with administrator privileges\n"
         "    return \"SM_OK\"\n"
         "on error errorMessage number errorNumber\n"
         "    return \"SM_ERROR:\" & errorNumber & \":\" & errorMessage\n"
         "end try", escaped];
}

- (void)beginAuthorizationForMode:(NSNumber *)mode {
    if (!self.applying || self.authorizationTask) return;
    SMScreenMode target = mode.integerValue;

    [NSApp activateIgnoringOtherApps:YES];

    // Keep AppKit's event loop responsive while macOS owns the password UI.
    // The system script runner requests authorization in a separate process;
    // no password is collected, passed as an argument, or stored by this app.
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outputPipe = [NSPipe pipe];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/osascript"];
    task.arguments = @[@"-e", [self authorizationScriptForMode:target]];
    task.standardOutput = outputPipe;
    task.standardError = outputPipe;
    self.authorizationTask = task;

    __weak SMAppDelegate *weakSelf = self;
    task.terminationHandler = ^(NSTask *completedTask) {
        NSData *data = [outputPipe.fileHandleForReading readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data
                                               encoding:NSUTF8StringEncoding] ?: @"";
        output = [output stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];

        dispatch_async(dispatch_get_main_queue(), ^{
            SMAppDelegate *self = weakSelf;
            if (!self || self.authorizationTask != completedTask) return;
            self.authorizationTask = nil;

            if (completedTask.terminationStatus == 0 &&
                [output isEqualToString:@"SM_OK"]) {
                [self setStatus:@"设置已写入，正在等待系统刷新…"
                         color:NSColor.systemOrangeColor
                         error:NO];
                [self verifyMode:target attempt:0];
                return;
            }

            self.applying = NO;
            [self displayMode:[self readCurrentMode]];
            if ([output hasPrefix:@"SM_ERROR:-128:"]) {
                [self setStatus:@"已取消，没有修改设置"
                         color:NSColor.secondaryLabelColor
                         error:NO];
            } else {
                NSString *detail = output.length ? output : @"授权进程已结束";
                if ([detail hasPrefix:@"SM_ERROR:"]) {
                    NSRange messageStart = [detail rangeOfString:@":"
                                                        options:0
                                                          range:NSMakeRange(9, detail.length - 9)];
                    if (messageStart.location != NSNotFound) {
                        detail = [detail substringFromIndex:messageStart.location + 1];
                    }
                }
                [self setStatus:[@"切换失败：" stringByAppendingString:detail]
                         color:NSColor.systemRedColor
                         error:YES];
            }
        });
    };

    NSError *launchError = nil;
    if (![task launchAndReturnError:&launchError]) {
        self.authorizationTask = nil;
        self.applying = NO;
        [self displayMode:[self readCurrentMode]];
        [self setStatus:[@"无法发起授权：" stringByAppendingString:
            launchError.localizedDescription ?: @"未知错误"]
                 color:NSColor.systemRedColor
                 error:YES];
    }
}

- (void)verifyMode:(SMScreenMode)target attempt:(NSInteger)attempt {
    SMScreenMode actual = [self readCurrentMode];

    if (actual == target) {
        self.applying = NO;
        [self displayMode:actual];
        NSString *title =
            target == SMScreenModeNormal ? @"正常模式" : @"永不熄屏";
        [self setStatus:[@"已切换到" stringByAppendingString:title]
                 color:(target == SMScreenModeNormal
                            ? NSColor.systemBlueColor
                            : NSColor.systemOrangeColor)
                 error:NO];
        return;
    }

    // powerd and cfprefsd can take a moment to publish their updated values.
    // Retry instead of reporting a false failure immediately.
    if (attempt < 8) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                [self verifyMode:target attempt:attempt + 1];
            }
        );
        return;
    }

    self.applying = NO;
    [self displayMode:actual];
    [self setStatus:@"设置已写入；系统状态刷新较慢，可点右上角刷新"
             color:NSColor.systemOrangeColor
             error:NO];
}

- (void)refresh:(id)sender {
    if (self.applying) return;
    SMScreenMode mode = [self readCurrentMode];
    [self displayMode:mode];
    NSString *title = mode == SMScreenModeNormal
        ? @"正常模式"
        : (mode == SMScreenModeNeverOff ? @"永不熄屏" : @"自定义设置");
    NSColor *color = mode == SMScreenModeNormal
        ? NSColor.systemBlueColor
        : (mode == SMScreenModeNeverOff
            ? NSColor.systemOrangeColor
            : NSColor.secondaryLabelColor);
    [self setStatus:[@"当前：" stringByAppendingString:title]
             color:color
             error:NO];
}

- (void)displayMode:(SMScreenMode)mode {
    self.currentMode = mode;
    [self.normalButton setModeSelected:(mode == SMScreenModeNormal)];
    [self.neverButton setModeSelected:(mode == SMScreenModeNeverOff)];
    [self syncMenuBarState];
}

- (void)syncMenuBarState {
    NSString *symbolName;
    NSString *statusText;

    switch (self.currentMode) {
        case SMScreenModeNormal:
            symbolName = @"display";
            statusText = @"当前：正常模式";
            self.menuModeSwitch.selectedSegment = 0;
            break;
        case SMScreenModeNeverOff:
            symbolName = @"sun.max.fill";
            statusText = @"当前：屏幕常亮";
            self.menuModeSwitch.selectedSegment = 1;
            break;
        default:
            symbolName = @"display.trianglebadge.exclamationmark";
            statusText = @"当前：自定义设置";
            self.menuModeSwitch.selectedSegment = -1;
            break;
    }

    NSImage *image = [[NSImage imageWithSystemSymbolName:symbolName
                               accessibilityDescription:@"屏幕模式切换"]
        imageWithSymbolConfiguration:
            [NSImageSymbolConfiguration configurationWithPointSize:15
                                                             weight:NSFontWeightMedium]];
    // Let the menu bar render the same monochrome foreground as system icons
    // (white on a dark menu bar), rather than using the control-panel palette.
    image.template = YES;
    self.statusItem.button.image = image;
    self.statusItem.button.contentTintColor = nil;
    self.menuStatusItem.title = statusText;
}

- (void)setStatus:(NSString *)text
            color:(NSColor *)color
            error:(BOOL)error {
    self.statusLabel.stringValue = text;
    self.statusLabel.textColor = error ? NSColor.systemRedColor
                                      : NSColor.secondaryLabelColor;
    self.statusDot.dotColor = color;
    if (self.menuStatusItem && self.applying) {
        self.menuStatusItem.title = text;
    }
}

- (SMScreenMode)readCurrentMode {
    NSDictionary *root =
        [NSDictionary dictionaryWithContentsOfFile:
            @"/Library/Preferences/com.apple.PowerManagement.plist"];
    NSDictionary *battery = root[@"Battery Power"];
    NSDictionary *adapter = root[@"AC Power"];
    if (!battery || !adapter) return SMScreenModeCustom;

    NSInteger batteryDisplay = [battery[@"Display Sleep Timer"] integerValue];
    NSInteger batterySleep = [battery[@"System Sleep Timer"] integerValue];
    NSInteger adapterDisplay = [adapter[@"Display Sleep Timer"] integerValue];
    NSInteger adapterSleep = [adapter[@"System Sleep Timer"] integerValue];

    NSDictionary *saverResult =
        [self runExecutable:@"/usr/bin/defaults"
                  arguments:@[
                      @"-currentHost", @"read", @"com.apple.screensaver", @"idleTime"
                  ]];
    if ([saverResult[@"exitCode"] intValue] != 0) return SMScreenModeCustom;

    NSInteger saver =
        [saverResult[@"output"] stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet].integerValue;

    if (batteryDisplay == 0 && batterySleep == 0 &&
        adapterDisplay == 0 && adapterSleep == 0 && saver == 0) {
        return SMScreenModeNeverOff;
    }

    if (batteryDisplay == 2 && batterySleep == 1 &&
        adapterDisplay == 10 && adapterSleep == 1 && saver == 300) {
        return SMScreenModeNormal;
    }

    return SMScreenModeCustom;
}

- (NSDictionary *)runExecutable:(NSString *)executable
                       arguments:(NSArray<NSString *> *)arguments {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    task.executableURL = [NSURL fileURLWithPath:executable];
    task.arguments = arguments;
    task.standardOutput = outputPipe;
    task.standardError = errorPipe;

    NSError *launchError = nil;
    BOOL launched = [task launchAndReturnError:&launchError];
    if (!launched) {
        return @{
            @"exitCode": @1,
            @"output": launchError.localizedDescription ?: @"无法运行命令"
        };
    }

    [task waitUntilExit];
    NSMutableData *combined = [NSMutableData data];
    [combined appendData:
        [outputPipe.fileHandleForReading readDataToEndOfFile]];
    [combined appendData:
        [errorPipe.fileHandleForReading readDataToEndOfFile]];
    NSString *output =
        [[NSString alloc] initWithData:combined encoding:NSUTF8StringEncoding] ?: @"";
    return @{@"exitCode": @(task.terminationStatus), @"output": output};
}
@end

int main(void) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        SMAppDelegate *delegate = [[SMAppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
