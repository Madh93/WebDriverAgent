/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBTVIntegrationTestCase.h"
#import "XCUIDevice+FBHealthCheck.h"
#import "XCUIElement.h"

@interface TVXCUIDeviceHealthCheckTests : FBTVIntegrationTestCase
@end

@implementation TVXCUIDeviceHealthCheckTests

- (void)testHealthCheck
{
  [self launchApplication];
  XCTAssertTrue(self.testedApplication.exists);
  XCTAssertTrue([[XCUIDevice sharedDevice] fb_healthCheckWithApplication:self.testedApplication]);
}

@end
