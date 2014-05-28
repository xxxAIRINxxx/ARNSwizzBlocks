//
//  ARNSwizzBlocksTests.m
//  ARNSwizzBlocksTests
//
//  Created by Airin on 2014/05/26.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "NSObject+ARNSwizzBlocks.h"
#import "ARNSwizzBlockTestObject.h"

@interface ARNSwizzBlocksTests : XCTestCase

@end

@implementation ARNSwizzBlocksTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    ARNSwizzBlockTestObject *testObj = ARNSwizzBlockTestObject.new;
    
    [testObj arn_swizzRespondsToSelector:@selector(testingWithString:number:) fromProtocol:nil usingBlock:^(id obj, NSString *aString, NSNumber *number) {
        NSLog(@"Call Block Method");
        NSLog(@"aString : %@", aString);
        NSLog(@"number : %@", number);
    }];
    
    [testObj testingWithString:@"testOK" number:@111];
    
    [testObj arn_swizzRespondsToSelector:@selector(testingWithString:number:) fromProtocol:nil usingBlock:^(id obj, NSString *aString, NSNumber *number) {
        NSLog(@"Call Block Method");
        NSLog(@"aString : %@", aString);
        NSLog(@"number : %@", number);
    }];
    
    [testObj testingWithString:@"testOK" number:@111];
}

- (void)testOtherObj
{
    ARNSwizzBlockTestObject *testObj = ARNSwizzBlockTestObject.new;
    [testObj testingWithString:@"otherObjOK" number:@222];
}
@end
