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
#import "FBTestMacros.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@interface TVXCElementSnapshotHelperTests : FBTVIntegrationTestCase
@property (nonatomic, strong) XCUIElement *testedView;
@end

@implementation TVXCElementSnapshotHelperTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
  self.testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(self.testedView.exists);
  [self.testedView resolve];
}

- (void)testDescendantsMatchingType
{
  NSSet<NSString *> *expectedLabels = [NSSet setWithArray:@[
                                                            @"Alerts",
                                                            @"Attributes",
                                                            @"Navigation",
                                                            @"Scrolling",
                                                            ]];
  NSArray<XCElementSnapshot *> *matchingSnapshots = [self.testedView.fb_lastSnapshot fb_descendantsMatchingType:XCUIElementTypeButton];
  XCTAssertEqual(matchingSnapshots.count, expectedLabels.count);
  NSArray<NSString *> *labels = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.label"];
  XCTAssertEqualObjects([NSSet setWithArray:labels], expectedLabels);
  
  NSArray<NSNumber *> *types = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.elementType"];
  XCTAssertEqual(types.count, 1, @"matchingSnapshots should contain only one type");
  XCTAssertEqualObjects(types.lastObject, @(XCUIElementTypeButton), @"matchingSnapshots should contain only one type");
}

- (void)testDescendantsMatchingXPath
{
  NSArray<XCElementSnapshot *> *matchingSnapshots = [self.testedView.fb_lastSnapshot fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton[@label='Alerts']"];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testParentMatchingType
{
  XCUIElement *button = self.testedApplication.buttons[@"Alerts"];
  XCTAssertTrue(button.exists);
  [button resolve];
  XCElementSnapshot *windowSnapshot = [button.fb_lastSnapshot fb_parentMatchingType:XCUIElementTypeWindow];
  XCTAssertNotNil(windowSnapshot);
  XCTAssertEqual(windowSnapshot.elementType, XCUIElementTypeWindow);
}

@end

@interface TVXCElementSnapshotHelperTests_AttributePage : FBTVIntegrationTestCase
@end

@implementation TVXCElementSnapshotHelperTests_AttributePage

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToAttributesPage];
  });
}

- (void)testParentMatchingOneOfTypes
{
  XCUIElement *todayPickerWheel = self.testedApplication.staticTexts[@"Text view"];
  XCTAssertTrue(todayPickerWheel.exists);
  [todayPickerWheel resolve];
  XCElementSnapshot *window = [todayPickerWheel.fb_lastSnapshot fb_parentMatchingOneOfTypes:@[@(XCUIElementTypeApplication), @(XCUIElementTypeWindow)]];
  XCTAssertNotNil(window);
  XCTAssertEqual(window.elementType, XCUIElementTypeWindow);
}

- (void)testParentMatchingOneOfTypesWithXCUIElementTypeAny
{
  XCUIElement *todayPickerWheel = self.testedApplication.staticTexts[@"Text view"];
  XCTAssertTrue(todayPickerWheel.exists);
  [todayPickerWheel resolve];
  XCElementSnapshot *otherSnapshot = [todayPickerWheel.fb_lastSnapshot fb_parentMatchingOneOfTypes:@[@(XCUIElementTypeAny), @(XCUIElementTypeWindow)]];
  XCTAssertNotNil(otherSnapshot);
  XCTAssertEqual(otherSnapshot.elementType, XCUIElementTypeOther);
}

- (void)testParentMatchingOneOfTypesWithAbsentParents
{
  XCUIElement *todayPickerWheel = self.testedApplication.staticTexts[@"Text view"];
  XCTAssertTrue(todayPickerWheel.exists);
  [todayPickerWheel resolve];
  XCElementSnapshot *otherSnapshot = [todayPickerWheel.fb_lastSnapshot fb_parentMatchingOneOfTypes:@[@(XCUIElementTypeTab), @(XCUIElementTypeLink)]];
  XCTAssertNil(otherSnapshot);
}

@end

@interface TVXCElementSnapshotHelperTests_ScrollView : FBTVIntegrationTestCase
@end

@implementation TVXCElementSnapshotHelperTests_ScrollView

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToScrollPageWithCells:false];
  });
}

- (void)testParentMatchingOneOfTypesWithFilter
{
  XCUIElement *threeStaticText = self.testedApplication.staticTexts[@"3"];
  [threeStaticText resolve];
  NSArray *acceptedParents = @[
                               @(XCUIElementTypeScrollView),
                               @(XCUIElementTypeCollectionView),
                               @(XCUIElementTypeTable),
                               ];
  XCElementSnapshot *scrollView = [threeStaticText.fb_lastSnapshot fb_parentMatchingOneOfTypes:acceptedParents
                                                                                        filter:^(XCElementSnapshot *snapshot) {
                                                                                          return [snapshot isWDVisible];
                                                                                        }];
  XCTAssertEqualObjects(scrollView.identifier, @"scrollView");
}

- (void)testParentMatchingOneOfTypesWithFilterRetruningNo
{
  XCUIElement *threeStaticText = self.testedApplication.staticTexts[@"3"];
  [threeStaticText resolve];
  NSArray *acceptedParents = @[
                               @(XCUIElementTypeScrollView),
                               @(XCUIElementTypeCollectionView),
                               @(XCUIElementTypeTable),
                               ];
  XCElementSnapshot *scrollView = [threeStaticText.fb_lastSnapshot fb_parentMatchingOneOfTypes:acceptedParents
                                                                                        filter:^(XCElementSnapshot *snapshot) {
                                                                                          return NO;
                                                                                        }];
  XCTAssertNil(scrollView);
}

- (void)testDescendantsCellSnapshots
{
  XCUIElement *scrollView = self.testedApplication.scrollViews[@"scrollView"];
  [scrollView resolve];
  FBAssertWaitTillBecomesTrue(self.testedApplication.staticTexts[@"3"].fb_isVisible);
  NSArray *cells = [scrollView.fb_lastSnapshot fb_descendantsCellSnapshots];
  XCTAssertGreaterThanOrEqual(cells.count, 10);
  XCElementSnapshot *element = cells.firstObject;
  XCTAssertEqualObjects(element.label, @"0");
}

@end

@interface TVXCElementSnapshotHelperTests_ScrollViewCells : FBTVIntegrationTestCase
@end

@implementation TVXCElementSnapshotHelperTests_ScrollViewCells

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToScrollPageWithCells:YES];
  });
}

- (void)testParentCellSnapshot
{
  FBAssertWaitTillBecomesTrue(self.testedApplication.staticTexts[@"3"].fb_isVisible);
  XCUIElement *threeStaticText = self.testedApplication.staticTexts[@"3"];
  [threeStaticText resolve];
  XCElementSnapshot *xcuiElementCell = [threeStaticText.fb_lastSnapshot fb_parentCellSnapshot];
  XCTAssertEqual(xcuiElementCell.elementType, 75);
}

@end
