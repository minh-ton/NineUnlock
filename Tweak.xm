#import "NineUnlock.h"

// Thanks Stackoverflow!
// https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
@implementation UIColor(Hexadecimal)
+ (UIColor *)colorWithHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
@end

static BOOL SIMULATOR;

NSString *lsText;
static BOOL enabled;
static BOOL showChevron;
static BOOL lockSound;
NSInteger customTextSize;
NSString *customTextLabel;
NSString *customTextColor;

static bool isOnLockscreen = true;
static CSScrollView *scrollView;
static CSMainPageView *mainPageView;
static CSTodayContentView *todayContentView;
static CSFixedFooterViewController *fixedFooterViewController;
static CSViewController *viewController;
static CSTeachableMomentsContainerViewController *containerViewController;

void loadprefs() {
  NSMutableDictionary const *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.minhton.nineunlock.pref.plist"];

  if (!prefs) {
    NSURL *source = [NSURL fileURLWithPath:@"/Library/PreferenceBundles/NineUnlockPref.bundle/defaults.plist"];
    NSURL *destination = [NSURL fileURLWithPath:@"/var/mobile/Library/Preferences/me.minhton.nineunlock.pref.plist"];
    [[NSFileManager defaultManager] copyItemAtURL:source toURL:destination error:nil];
  }

  enabled = [[prefs objectForKey:@"enabled"] boolValue];
  showChevron = [[prefs objectForKey:@"showChevron"] boolValue];
  lockSound = [[prefs objectForKey:@"lockSound"] boolValue];
  customTextSize = [[prefs objectForKey:@"customTextSize"] integerValue];
  customTextLabel = [prefs objectForKey:@"customTextLabel"];
  customTextColor = [prefs objectForKey:@"customTextColor"];
}

void updateAll() {
  [mainPageView updateNineUnlockState]; //CSMainPageView
  [todayContentView updateNineUnlockState]; //CSTodayContentView
  [fixedFooterViewController updateNineUnlockState]; //CSFixedFooterViewController
  [containerViewController updateNineUnlockState];
}

void setIsOnLockscreen(bool value) {
    isOnLockscreen = value;
    updateAll();
}

// ===================== SLIDE TO UNLOCK =========================
// =================== NineUnlock Tweak =================

%group SlideToUnlock

// Play iOS 9 Locksound
// Doesn't work on non-passcode devices.

%hook SBSleepWakeHardwareButtonInteraction
- (void)_playLockSound {
    if (enabled && lockSound) {
      if (!(MSHookIvar<NSUInteger>([objc_getClass("SBLockStateAggregator") sharedInstance], "_lockState") == 0)) return;
      SystemSoundID sound = 0;
      AudioServicesDisposeSystemSoundID(sound);
      AudioServicesCreateSystemSoundID((CFURLRef) CFBridgingRetain([NSURL fileURLWithPath:@"/Library/Application Support/NineUnlock/lock.caf"]), &sound);
      AudioServicesPlaySystemSound((SystemSoundID)sound);
    } else {
      %orig;
    }
}
%end

%hook CSMainPageView

%property (nonatomic, retain) _UIGlintyStringView *SlideToUnlockView;

-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    mainPageView = self;
    return orig;
}

-(void)layoutSubviews {
    %orig;
    if (!self.SlideToUnlockView) {
        self.SlideToUnlockView = [[_UIGlintyStringView alloc] initWithText:customTextLabel andFont:[UIFont systemFontOfSize:customTextSize]];
    }
    [self updateNineUnlockState];
}

%new;
-(void)updateNineUnlockState {
    if (enabled && isOnLockscreen) {
        [self addSubview:self.SlideToUnlockView];
        self.SlideToUnlockView.frame = CGRectMake(0, self.frame.size.height - 150, self.frame.size.width, 150);
        [self sendSubviewToBack:self.SlideToUnlockView];
        if (showChevron) {
          [self.SlideToUnlockView setChevronStyle:1];
        } else {
          [self.SlideToUnlockView setChevronStyle:0];
        }

        [self.SlideToUnlockView hide];
        [self.SlideToUnlockView show];

        // NineMusic compatibility
        int notify_token2;

        notify_register_dispatch("me.minhton.ninemusic/shownineunlock", &notify_token2, dispatch_get_main_queue(), ^(int token) {
          [self.SlideToUnlockView show];
        });

        notify_register_dispatch("me.minhton.ninemusic/hidenineunlock", &notify_token2, dispatch_get_main_queue(), ^(int token) {
          [self.SlideToUnlockView hide];
        });

        UIColor *primaryColor = [UIColor colorWithHexString:customTextColor];
        if (viewController && [viewController legibilitySettings]) {
            CGFloat white = 0;
            CGFloat alpha = 0;
            [[viewController legibilitySettings].primaryColor getWhite:&white alpha:&alpha];
        }
        self.SlideToUnlockView.layer.sublayers[0].sublayers[2].backgroundColor = [primaryColor colorWithAlphaComponent:0.65].CGColor;
    } else {
      [self.SlideToUnlockView hide];
      [self.SlideToUnlockView removeFromSuperview];
    }
}
%end

// My sketchy way to hide the "Press home to unlock" text...
%hook SBUICallToActionLabel

- (void)setText:(id)arg1 forLanguage:(id)arg2 animated:(bool)arg3 {
	lsText = @"";
	return %orig(lsText, arg2, arg3);
}

%end

// Automatically scroll to the main lockscreen view
// if you press the "Cancel" button in the passcode view.

%hook SBUIPasscodeLockNumberPad

-(void)_cancelButtonHit {
    %orig;
    if (enabled && scrollView) {
        [scrollView scrollToPageAtIndex:1 animated:true];
    }
}

%end

// This basically check if we have completed scrolling
// to the right => Bring up the passcode screen

%hook CSScrollView

-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    scrollView = self;
    return orig;
}

- (void)_bs_didEndScrolling {
    %orig;
    if (enabled && self.currentPageIndex == 0 && self.pageRelativeScrollOffset < 0.50 && isOnLockscreen) {
        // Request unlock device
        [[%c(SBLockScreenManager) sharedInstance] lockScreenViewControllerRequestsUnlock];
    }
}

%end

// Completely empty the today view...

%hook CSTodayContentView

-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    todayContentView = self;
    return orig;
}

-(void)layoutSubviews {
    %orig;
    [self updateNineUnlockState];
}

%new;
-(void)updateNineUnlockState {
  if (enabled && isOnLockscreen) {
      self.alpha = 0.0;
      self.hidden = YES;
  } else {
      self.alpha = 1.0;
      self.hidden = NO;
  }
}

%end

// Hide the homebar on iPhoneX and newer models

%hook CSTeachableMomentsContainerViewController

-(id)init {
    id orig = %orig;
    containerViewController = self;
    return orig;
}

-(void)viewDidLoad{
    %orig;
    [self updateNineUnlockState];
}

%new;
-(void)updateNineUnlockState {
  if (enabled) {
      self.view.alpha = 0.0;
      self.view.hidden = YES;
  } else {
      self.view.alpha = 1.0;
      self.view.hidden = NO;
  }
}
%end

// Move the date & time with Slide to Unlock...
%hook CSTodayPageViewController
-(void)aggregateAppearance:(id)arg1 {
    %orig;
    if (enabled && isOnLockscreen) {
        CSComponent *dateView = [[%c(CSComponent) dateView] hidden:YES];
        [arg1 addComponent:dateView];
    }
}
%end

// My crazy workaround for the problem where coversheet doesn't want to
// disappear after unlocking.

// It will create a minor issue when you press on a message notification
// to reply => Use passcode => It will automaticatically unlock the phone to home screen.

%hook SBPasscodeEntryTransientOverlayViewController
-(void)viewDidDisappear:(BOOL)arg1 {
  [[%c(SBLockScreenManager) sharedInstance] lockScreenViewControllerRequestsUnlock];
  // Also a fix of Coversheet not automatically scroll to
  // the Notification Center main view...
  // (Doesn't work with phones have no passcode set...)
  if (enabled && scrollView) {
      [scrollView scrollToPageAtIndex:1 animated:true];
  }
  return %orig(arg1);
}
%end

// Hide lockscreen's (quite annoying) page dots.

%hook CSFixedFooterViewController

-(id)init {
    id orig = %orig;
    fixedFooterViewController = self;
    return orig;
}

-(void)viewDidLoad{
    %orig;
    [self updateNineUnlockState];
}

%new;
-(void)updateNineUnlockState {
  if (enabled) {
      self.view.alpha = 0.0;
      self.view.hidden = YES;
  } else {
      self.view.alpha = 1.0;
      self.view.hidden = NO;
  }
}

%end

%hook CSViewController

-(id)initWithPageViewControllers:(id)arg1 mainPageContentViewController:(id)arg2 {
    id orig = %orig;
    viewController = orig;
    return orig;
}

-(id)initWithPageViewControllers:(id)arg1 mainPageContentViewController:(id)arg2 legibilityProvider:(id)arg3  {
    id orig = %orig;
    viewController = orig;
    return orig;
}

-(BOOL)isPasscodeLockVisible {
    return true;
}

%end

// Hide quick actions (flashlight & camera) on iPhone X and later

%hook CSCoverSheetView
- (void)layoutSubviews {
  %orig;
  [self updateNineUnlockState];
}

%new
- (void)updateNineUnlockState {
  UIView *quickActions = MSHookIvar<UIView *>(self, "_quickActionsView");
  if (enabled) {
    quickActions.hidden = YES;
    quickActions.alpha = 0;
  } else {
    quickActions.hidden = NO;
    quickActions.alpha = 1;
  }
}
%end

// Thanks Skitty's Six(LS) Tweak!
// Set isLocked

%hook CSCoverSheetViewController

- (void)viewWillAppear:(BOOL)arg1 {
  %orig;
  setIsOnLockscreen(!self.authenticated);
}

%end

// Force enable today-view simply because this tweak
// replace the today view with the passcode view.

%hook SBMainDisplayPolicyAggregator

-(BOOL)_allowsCapabilityLockScreenTodayViewWithExplanation:(id*)arg1 {
    return true;
}

-(BOOL)_allowsCapabilityTodayViewWithExplanation:(id*)arg1 {
    return true;
}

%end

%end


static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    setIsOnLockscreen(true);
}

%ctor{

  // If you're testing with the iOS Simulator, set SIMULATOR = YES
  SIMULATOR = NO;

  if (SIMULATOR) {

    enabled = YES;
    showChevron = YES;
    lockSound = YES;
    customTextSize = 25;
    customTextLabel = @"slide to unlock";
    customTextColor = @"#000000";

  } else {

    loadprefs();
    if (mainPageView) {
      [mainPageView.SlideToUnlockView setText:customTextLabel];
      [mainPageView.SlideToUnlockView setNeedsTextUpdate:true];
      [mainPageView.SlideToUnlockView updateText];
    }
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadprefs, CFSTR("me.minhton.nineunlock/prefsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);

  }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, displayStatusChanged, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    %init(SlideToUnlock);
}
