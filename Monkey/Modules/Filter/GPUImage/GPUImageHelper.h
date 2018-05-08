//
//  GPUImageHelper.h
//  Monkey
//
//  Created by 王广威 on 2018/3/20.
//  Copyright © 2018年 Monkey. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
#import <GPUImage/GPUImage.h>
#ifdef __cplusplus
}
#endif

@interface GPUImageHelper : NSObject

+ (GPUImageFilterGroup *)filterGroupWithType:(NSString *)filterType;

@end
