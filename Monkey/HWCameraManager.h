//
//  HWCameraManager.h
//  HOLLA
//
//  Created by 王广威 on 2017/8/25.
//  Copyright © 2017年 HOLLA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenTok/OpenTok.h>

@interface HWCameraManager : NSObject <OTVideoCapture>

+ (instancetype)sharedManager;

/**
 *  滤镜类型
 */
@property (nonatomic, copy) NSString *filterType;
/**
 *  本地预览视图
 */
@property (nonatomic, strong) UIView *localPreviewView;

// 添加 pixel
- (void)addPixellate;
// 移除 pixel
- (void)removePixellate;

/**
 *  切换前后相机
 */
- (void)rotateCameraPosition;
/**
 *	设置前后相机
 */
- (void)changeCameraPositionTo:(AVCaptureDevicePosition)position;

@end
