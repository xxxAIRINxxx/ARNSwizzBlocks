//
//  ARNSwizzBlockTestObject.m
//  ARNSwizzBlocks
//
//  Created by Airin on 2014/05/27.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ARNSwizzBlockTestObject.h"

@implementation ARNSwizzBlockTestObject

- (void)dealloc
{
    NSLog(@"dealloc : %@ ////////////////////////", NSStringFromClass([self class]));
}

- (void)testingWithString:(NSString *)aString number:(NSNumber *)number
{
    NSLog(@"Call Original Method");
}

@end
