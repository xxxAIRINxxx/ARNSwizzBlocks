//
//  NSObject+ARNSwizzBlocks.h
//  NSObject+ARNSwizzBlocks
//
//  Created by Airin on 2014/05/26.
//  Copyright (c) 2014 Airin. All rights reserved.
//

// @see https://github.com/ReactiveCocoa/ReactiveCocoa#
// @see http://qiita.com/ikesyo/items/9c6b00e2b00d8f5e3e11

#import <Foundation/Foundation.h>

@interface NSObject (ARNSwizzBlocks)

- (void)arn_swizzRemoveBlockForSelector:(SEL)selector;

- (void)arn_swizzRespondsToSelector:(SEL)selector fromProtocol:(Protocol *)protocol usingBlock:(id)block;

@end
