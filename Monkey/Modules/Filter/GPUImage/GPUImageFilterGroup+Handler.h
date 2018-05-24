//
//  GPUImageFilterGroup+Handler.h
//
//
//  Created by wei on 16/11/9.
//  Copyright © 2016年 HOLLA. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@protocol GPUImageFilterGroupDelgate <NSObject>

- (void)processPixelBuffer:(CVPixelBufferRef)buffer;

@end

@interface GPUImageFilterGroup (StreamHandler)

@property (nonatomic,assign) id<GPUImageFilterGroupDelgate> delegate;

@end
