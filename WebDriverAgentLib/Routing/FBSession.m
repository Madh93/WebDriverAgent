/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSession.h"
#import "FBSession-Private.h"

#import <objc/runtime.h>

#import "FBApplication.h"
#import "FBElementCache.h"
#import "FBMacros.h"
#import "FBHomeboardApplication.h"
#import "XCAccessibilityElement.h"
#import "XCAXClient_iOS.h"
#import "XCUIElement.h"

NSString *const FBApplicationCrashedException = @"FBApplicationCrashedException";

@interface FBSession ()
@property (nonatomic) NSString *testedApplicationBundleId;
@property (nonatomic, strong, readwrite) FBApplication *testedApplication;
@property (nonatomic) NSDictionary<NSString *, FBApplication *> *applications;
@end

@implementation FBSession

static FBSession *_activeSession;
+ (instancetype)activeSession
{
  return _activeSession ?: [FBSession sessionWithApplication:nil];
}

+ (void)markSessionActive:(FBSession *)session
{
  if (_activeSession && _activeSession.testedApplication.bundleID != session.testedApplication.bundleID) {
    [_activeSession kill];
  }
  _activeSession = session;
}

+ (instancetype)sessionWithIdentifier:(NSString *)identifier
{
  if (!identifier) {
    return nil;
  }
  if (![identifier isEqualToString:_activeSession.identifier]) {
    return nil;
  }
  return _activeSession;
}

+ (instancetype)sessionWithApplication:(FBApplication *)application
{
  FBSession *session = [FBSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.testedApplicationBundleId = nil;
  NSMutableDictionary *apps = [NSMutableDictionary dictionary];
  if (application) {
    [apps setObject:application forKey:application.bundleID];
    session.testedApplicationBundleId = application.bundleID;
  }
  session.applications = apps.copy;
  session.elementCache = [FBElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

- (void)kill
{
  
  if (self.testedApplicationBundleId) {
    [[self.applications objectForKey:self.testedApplicationBundleId] terminate];
  }
  _activeSession = nil;
}

- (FBApplication *)activeApplication
{
  FBApplication *application = [FBApplication fb_activeApplication];
  FBApplication *testedApplication = nil;
  if (self.testedApplicationBundleId) {
    testedApplication = [self.applications objectForKey:self.testedApplicationBundleId];
  }
  if (testedApplication && !testedApplication.running) {
    NSString *description = [NSString stringWithFormat:@"The application under test with bundle id '%@' is not running, possibly crashed", self.testedApplicationBundleId];
    [[NSException exceptionWithName:FBApplicationCrashedException reason:description userInfo:nil] raise];
  }
  return application;
}

- (FBApplication *)application
{
  if (self.testedApplication && !self.testedApplication.running) {
    [[NSException exceptionWithName:FBApplicationCrashedException reason:@"Application is not running, possibly crashed" userInfo:nil] raise];
  }
  return [FBApplication fb_activeApplication] ?: self.testedApplication;
}

- (FBApplication *)registerApplicationWithBundleId:(NSString *)bundleIdentifier
{
  FBApplication *app = [self.applications objectForKey:bundleIdentifier];
  if (!app) {
    app = [[FBApplication alloc] initPrivateWithPath:nil bundleID:bundleIdentifier];
    NSMutableDictionary *apps = self.applications.mutableCopy;
    [apps setObject:app forKey:bundleIdentifier];
    self.applications = apps.copy;
  }
  return app;
}

- (BOOL)unregisterApplicationWithBundleId:(NSString *)bundleIdentifier
{
  FBApplication *app = [self.applications objectForKey:bundleIdentifier];
  if (app) {
    NSMutableDictionary *apps = self.applications.mutableCopy;
    [apps removeObjectForKey:bundleIdentifier];
    self.applications = apps.copy;
    return YES;
  }
  return NO;
}

- (void)launchApplicationWithBundleId:(NSString *)bundleIdentifier
              shouldWaitForQuiescence:(nullable NSNumber *)shouldWaitForQuiescence
                            arguments:(nullable NSArray<NSString *> *)arguments
                          environment:(nullable NSDictionary <NSString *, NSString *> *)environment
{
  FBApplication *app = [self registerApplicationWithBundleId:bundleIdentifier];
  if ([[app valueForKey:@"state"] intValue] < 2) {
    if (nil != shouldWaitForQuiescence) {
      app.fb_shouldWaitForQuiescence = [shouldWaitForQuiescence boolValue];
    } else if ([bundleIdentifier isEqualToString:self.testedApplicationBundleId]) {
      app.fb_shouldWaitForQuiescence = NO;
    }
    app.launchArguments = arguments ?: @[];
    app.launchEnvironment = environment ?: @{};
    [app launch];
  }
  [app activate];
}

- (void)activateApplicationWithBundleId:(NSString *)bundleIdentifier
{
  FBApplication *app = [self registerApplicationWithBundleId:bundleIdentifier];
  [app activate];
}

- (BOOL)terminateApplicationWithBundleId:(NSString *)bundleIdentifier
{
  FBApplication *app = [self registerApplicationWithBundleId:bundleIdentifier];
  BOOL result = NO;
  if ([[app valueForKey:@"state"] intValue] >= 2) {
    [app terminate];
    result = YES;
  }
  [self unregisterApplicationWithBundleId:bundleIdentifier];
  return result;
}

@end
