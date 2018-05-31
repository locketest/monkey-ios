//
//  HWCameraManager.h
//  HOLLA
//
//  Created by 王广威 on 2017/8/25.
//  Copyright © 2017年 HOLLA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <OpenTok/OpenTok.h>
#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@protocol StreamRawDataHandler

- (void)newFrameRawDataAvailable:(GLubyte *_Nonnull)rawData;

@end

@protocol StreamBufferHandler

- (void)newFrameBufferAvailable:(CVPixelBufferRef _Nonnull)frameBuffer;

@end

@interface HWCameraManager : NSObject <OTVideoCapture>

+ (instancetype _Nonnull)sharedManager;

/**
 *  输出流处理
 */
@property (nonatomic, weak, nullable) id <StreamBufferHandler> streamHandler;
/**
 *  当前滤镜类型
 */
@property (nonatomic, copy, nonnull) NSString *filterType;
/**
 *  当前滤镜类型
 */
@property (nonatomic, assign) BOOL agora_capture;
/**
 *  当前滤镜类型
 */
@property (nonatomic, assign) BOOL opentok_capture;
/**
 *  本地预览视图
 */
@property (nonatomic, strong, readonly, nonnull) UIView *localPreviewView;
/**
 *	是否有 pixellate 滤镜
 */
@property (nonatomic, assign) BOOL pixellated;
/**
 *	截取的流的宽高
 */
@property (nonatomic, assign, readonly) CGSize streamSize;

- (void)prepareManager;

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

/**
 *	截取当前帧画面
 */
- (void)snapStream:(nullable void (^)(NSData *_Nonnull))completed;

@end
