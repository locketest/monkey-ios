//
//  NSObject+Runtime.m
//  Monkey
//
//  Created by 王广威 on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

#import "NSObject+Runtime.h"
#import <objc/objc.h>
#import <objc/runtime.h>

@implementation NSObject (Runtime)

+ (BOOL)swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel {
	Method originalMethod = class_getInstanceMethod(self, originalSel);
	Method newMethod = class_getInstanceMethod(self, newSel);
	if (!originalMethod || !newMethod) return NO;
	
	class_addMethod(self,
					originalSel,
					class_getMethodImplementation(self, originalSel),
					method_getTypeEncoding(originalMethod));
	class_addMethod(self,
					newSel,
					class_getMethodImplementation(self, newSel),
					method_getTypeEncoding(newMethod));
	
	method_exchangeImplementations(class_getInstanceMethod(self, originalSel),
								   class_getInstanceMethod(self, newSel));
	return YES;
}

+ (BOOL)swizzleClassMethod:(SEL)originalSel with:(SEL)newSel {
	Class class = object_getClass(self);
	Method originalMethod = class_getInstanceMethod(class, originalSel);
	Method newMethod = class_getInstanceMethod(class, newSel);
	if (!originalMethod || !newMethod) return NO;
	method_exchangeImplementations(originalMethod, newMethod);
	return YES;
}

@end
