//
//  GPUImageFilterGroup+Handler.m
//
//
//  Created by wei on 16/11/9.
//  Copyright © 2016年 HOLLA. All rights reserved.
//

#import "GPUImageFilterGroup+Handler.h"
#import <objc/runtime.h>

@implementation GPUImageFilterGroup (StreamHandler)
@dynamic delegate;

- (void)setDelegate:(id<GPUImageFilterGroupDelgate>)delegate {
    [self willChangeValueForKey:@"delegate"];
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"delegate"];
}

- (id<GPUImageFilterGroupDelgate>)delegate {
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)load {
    Method origMethod = class_getInstanceMethod([self class],@selector(setInputFramebuffer:atIndex:));
    Method swizMethod = class_getInstanceMethod([self class],@selector(handler_setInputFramebuffer:atIndex:));
    method_exchangeImplementations(origMethod, swizMethod);
}

- (void)handler_setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    [self handler_setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    CVPixelBufferRef videoFrame = newInputFramebuffer.pixelBuffer;
    if ([self.delegate respondsToSelector:@selector(processPixelBuffer:)]) {
        [self.delegate processPixelBuffer:videoFrame];
    }
}

@end
