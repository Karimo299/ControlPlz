#import <PersistentConnection/PCSimpleTimer.h>
#import <SpringBoard/SpringBoard.h>
#import "JBBulletinManager.h"

@interface SBApplicationProcessState : NSObject
-(int)visibility;
-(int)taskState;
@property (nonatomic,readonly) int pid;
@end

@interface SBApplication
@property (nonatomic,readonly) NSString * bundleIdentifier;
@property (nonatomic,readonly) NSString * displayName;
@property (nonatomic, assign) double whitelistTimerTime;
@property (nonatomic, assign) double cooldownTimerTime;
@property (nonatomic, assign) PCSimpleTimer *whitelistTimer;
@property (nonatomic, assign) PCSimpleTimer *cooldownTimer;
@property (nonatomic,readonly) SBApplicationProcessState * processState;
@end

static NSUserDefaults *prefs;
BOOL enabled;
double startTime;
double whitelistTimerTime;
double cooldownTimerTime;
bool appOpen = NO;
double elapsedTime;
double dateStart;
UIAlertController *alertController;
SBApplication *app;

static void loadPrefs() {
  prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.controlplz"];
  enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
  for (NSString *bundleID in [[prefs dictionaryRepresentation] allKeys]) {
    if ([bundleID containsString:@"LockedApps"]) {
      if (![[prefs valueForKey:bundleID] boolValue]) {
        [prefs setObject:@1 forKey:bundleID];
        [prefs setObject:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:[bundleID stringByReplacingOccurrencesOfString:@"LockedApps" withString:@"Date"]];
        [prefs synchronize];
      }

      if ([prefs valueForKey:[bundleID stringByReplacingOccurrencesOfString:@"LockedApps" withString:@"Date"]] && [[prefs valueForKey:[bundleID stringByReplacingOccurrencesOfString:@"LockedApps" withString:@"Date"]] intValue] + 172800 <= (int)([[NSDate date] timeIntervalSince1970])) {
        [prefs removeObjectForKey:bundleID];
        [prefs removeObjectForKey:[bundleID stringByReplacingOccurrencesOfString:@"LockedApps" withString:@"Date"]];
      }
    }
  }
  whitelistTimerTime = [prefs objectForKey:@"whitelistTimerTime"] ? [[prefs objectForKey:@"whitelistTimerTime"] doubleValue] * 3600 : 4 * 3600;
  cooldownTimerTime = [prefs objectForKey:@"cooldownTimerTime"] ? [[prefs objectForKey:@"cooldownTimerTime"] doubleValue] * 3600 : 2 * 3600;
}


%hook SBApplication
%property (nonatomic, assign) PCSimpleTimer *whitelistTimer;
%property (nonatomic, assign) PCSimpleTimer *cooldownTimer;
%property (nonatomic, assign) double whitelistTimerTime;
%property (nonatomic, assign) double cooldownTimerTime;

-(id)initWithApplicationInfo:(id)arg1 {
  self.whitelistTimerTime = [prefs objectForKey:[NSString stringWithFormat:@"whitlistTime-%@", %orig.bundleIdentifier]] ? [[prefs objectForKey:[NSString stringWithFormat:@"whitlistTime-%@", self.bundleIdentifier]] intValue] : whitelistTimerTime;
  self.cooldownTimerTime = [prefs objectForKey:[NSString stringWithFormat:@"cooldownStart-%@", %orig.bundleIdentifier]] ? [[NSDate date] timeIntervalSince1970] - [[prefs objectForKey:[NSString stringWithFormat:@"cooldownStart-%@", %orig.bundleIdentifier]] intValue] : cooldownTimerTime;
  if ([prefs objectForKey:[NSString stringWithFormat:@"cooldownStart-%@", %orig.bundleIdentifier]]) {
    self.cooldownTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:self.cooldownTimerTime serviceIdentifier:@"com.karimo299.controlplz" target:self selector:@selector(enableAgain) userInfo:nil];
    [self.cooldownTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
  }
  return %orig;
}

-(void)_updateProcess:(id)arg1 withState:(SBApplicationProcessState *)state {
  %orig;
  if (self.whitelistTimerTime <= 0) self.whitelistTimerTime = whitelistTimerTime;
    if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", self.bundleIdentifier]] boolValue]) {
      if ([state visibility] == 2 && !appOpen) {
        app = self;
        appOpen = YES;
        if (![self.cooldownTimer isValid]) {
        dateStart = [[NSDate date] timeIntervalSince1970];
        if ([self.whitelistTimer isValid])[self.whitelistTimer invalidate];
        self.whitelistTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:self.whitelistTimerTime serviceIdentifier:@"com.karimo299.controlplz" target:self selector:@selector(killApp) userInfo:nil];
        [self.whitelistTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
      } else {
        if (!alertController) {
          alertController = [UIAlertController alertControllerWithTitle:nil  message:@"You have exceeded the time limit :(" preferredStyle:UIAlertControllerStyleAlert];
          [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (self.processState.pid > 0) {
              kill(self.processState.pid, SIGTERM);
            }
            alertController = nil;
         }]];
         [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:^{}];
      }
    }
  } else if (([state visibility] <= 1 && appOpen) || ([state taskState] == 3 && appOpen)) {
    app = nil;
    appOpen = NO;
    if ([self.whitelistTimer isValid])[self.whitelistTimer invalidate];
    elapsedTime =[[NSDate date] timeIntervalSince1970] - dateStart;
    self.whitelistTimerTime -= (int)elapsedTime;
    [prefs setObject:[NSNumber numberWithInt:self.whitelistTimerTime] forKey:[NSString stringWithFormat:@"whitlistTime-%@", self.bundleIdentifier]];
    }
  }
}

%new
-(void)killApp {
  if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", self.bundleIdentifier]] boolValue]) {
    if ([self.cooldownTimer isValid])[self.cooldownTimer invalidate];
    if (self.processState.pid > 0) {
      kill(self.processState.pid, SIGTERM);
    }
    [prefs setObject:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:[NSString stringWithFormat:@"cooldownStart-%@", self.bundleIdentifier]];
    self.cooldownTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:self.cooldownTimerTime serviceIdentifier:@"com.karimo299.controlplz" target:self selector:@selector(enableAgain) userInfo:nil];
    [self.cooldownTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
  }
}

%new
-(void)enableAgain {
  [[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:self.displayName message:[NSString stringWithFormat:@"%@ can be used now", self.displayName] bundleID:self.bundleIdentifier];
  self.whitelistTimerTime = whitelistTimerTime;
  [prefs removeObjectForKey:[NSString stringWithFormat:@"cooldownStart-%@", self.bundleIdentifier]];
  [prefs setObject:[NSNumber numberWithInt:self.whitelistTimerTime] forKey:[NSString stringWithFormat:@"whitlistTime-%@", self.bundleIdentifier]];
}
%end

%ctor {
  CFNotificationCenterAddObserver(
	CFNotificationCenterGetDarwinNotifyCenter(), NULL,
	(CFNotificationCallback)loadPrefs,
	CFSTR("com.karimo299.controlplz/prefChanged"), NULL,
	CFNotificationSuspensionBehaviorDeliverImmediately);
  loadPrefs();
}
