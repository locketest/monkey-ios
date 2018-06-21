//
//  NSObject+Runtime.h
//  Monkey
//
//  Created by 王广威 on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Runtime)

#pragma mark - Swap method (Swizzling)
///=============================================================================
/// @name Swap method (Swizzling)
///=============================================================================

/**
 Swap two instance method's implementation in one class. Dangerous, be careful.
 
 @param originalSel   Selector 1.
 @param newSel        Selector 2.
 @return              YES if swizzling succeed; otherwise, NO.
 */
+ (BOOL)swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel;

/**
 Swap two class method's implementation in one class. Dangerous, be careful.
 
 @param originalSel   Selector 1.
 @param newSel        Selector 2.
 @return              YES if swizzling succeed; otherwise, NO.
 */
+ (BOOL)swizzleClassMethod:(SEL)originalSel with:(SEL)newSel;

@end
