/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBSpringboardApplication.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const FBShowAlertButtonName;
extern NSString *const FBShowSheetAlertButtonName;
extern NSString *const FBShowAlertForceTouchButtonName;

/**
 XCTestCase helper class used for integration tests
 */
@interface FBTvIntegrationTestCase : XCTestCase
@property (nonatomic, strong, readonly) XCUIApplication *testedApplication;
@property (nonatomic, strong, readonly) FBSpringboardApplication *springboard;

/**
 Launches application and resets side effects of testing like orientation etc.
 */
- (void)launchApplication;

/**
 Navigates integration app to attributes page
 */
- (void)goToAttributesPage;

/**
 Navigates integration app to alerts page
 */
- (void)goToAlertsPage;

/**
 Navigates to SpringBoard first page
 */
- (void)goToSpringBoardFirstPage;

///**
// Navigates to SpringBoard path with Extras folder
// */
//- (void)goToSpringBoardExtras;
//
///**
// Navigates to SpringBoard's dashboard
// */
//- (void)goToSpringBoardDashboard;
@end

NS_ASSUME_NONNULL_END
