//
//  HWCameraManager.m
//  HOLLA
//
//  Created by 王广威 on 2017/8/25.
//  Copyright © 2017年 HOLLA. All rights reserved.
//

#import "HWCameraManager.h"
#import "GPUImageHelper.h"
#import <AVFoundation/AVFoundation.h>
#import "GPUImageFilterGroup+Handler.h"

#import <ImageIO/ImageIO.h>
#import "Monkey-Swift.h"

@interface HWCameraManager() <GPUImageVideoCameraDelegate, GPUImageFilterGroupDelgate>

// 举报和截图
@property (nonatomic, copy) void(^snapCallback)(NSData *_Nonnull);

// 滤镜以及预览
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImagePixellateFilter *pixellateFilter;
@property (nonatomic, strong) GPUImageFilterGroup *gpuImagefilter;
@property (nonatomic, strong) GPUImageVideoCamera *gpuImageCamera;

@property (nonatomic, assign) BOOL capturing;

@end

@implementation HWCameraManager {
	uint32_t _imageWidth;
	uint32_t _imageHeight;
	
	OTVideoFrame *_videoFrame;
	id<OTVideoCaptureConsumer> _videoCaptureConsumer;
}

#pragma mark -- initial method
+ (instancetype)sharedManager {
	static HWCameraManager *_sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedManager = [[HWCameraManager alloc] init];
	});
	return _sharedManager;
}

#pragma mark - camera control
- (void)addNotification {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseCamera) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeCamera) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseCamera) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)deleteNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)startCamera {
	[self startGpuImageCamera];
}

- (void)stopCamera {
	[self stopGpuImageCamera];
}

- (void)pauseCamera {
	runSynchronouslyOnVideoProcessingQueue(^{
		glFinish();
		[_gpuImageCamera pauseCameraCapture];
	});
}

- (void)resumeCamera {
	runSynchronouslyOnVideoProcessingQueue(^{
		[self.gpuImageCamera resumeCameraCapture];
	});
}

- (void)startGpuImageCamera {
	[self.gpuImageCamera startCameraCapture];
	[self setFilterType:self.filterType];
	[self addNotification];
}

- (void)stopGpuImageCamera {
	[self deleteNotification];
	[_gpuImageCamera stopCameraCapture];
}

#pragma mark - pixel
- (void)addPixellate {
	if (self.pixellated) {
		return;
	}
	
	self.pixellated = YES;
	[self clearFilter];
	_gpuImagefilter = [[GPUImageFilterGroup alloc] init];
	[_gpuImagefilter addFilter:self.pixellateFilter];
	[_gpuImagefilter setInitialFilters:@[self.pixellateFilter]];
	[_gpuImagefilter setTerminalFilter:self.pixellateFilter];
	[self addFilter];
}

- (void)removePixellate {
	if (self.pixellated == NO) {
		return;
	}
	
	self.pixellated = NO;
	
	[self clearFilter];
	self.filterType = self.filterType;
}

#pragma mark - 切换摄像头
- (AVCaptureDevicePosition)currentCameraPosition {
	return [self.gpuImageCamera cameraPosition];
}

- (void)changeCameraPositionTo:(AVCaptureDevicePosition)position {
	AVCaptureDevicePosition oldPosition = [self currentCameraPosition];
	if (oldPosition != AVCaptureDevicePositionUnspecified && position != oldPosition) {
		[self.gpuImageCamera rotateCamera];
	}
}

- (void)rotateCameraPosition {
	AVCaptureDevicePosition oldPosition = [self currentCameraPosition];
	if (oldPosition != AVCaptureDevicePositionUnspecified) {
		[self.gpuImageCamera rotateCamera];
	}
}

#pragma mark - getter && setter
- (void)setVideoCaptureConsumer:(id<OTVideoCaptureConsumer>)videoCaptureConsumer {
	if (_videoCaptureConsumer != videoCaptureConsumer) {
		_videoCaptureConsumer = videoCaptureConsumer;
	}
}

- (id<OTVideoCaptureConsumer>)videoCaptureConsumer {
	return _videoCaptureConsumer;
}

- (OTVideoFrame *)videoFrame {
	if (!_videoFrame) {
		OTVideoFormat *videoFormat = [[OTVideoFormat alloc] init];
		videoFormat.pixelFormat = OTPixelFormatARGB;
		videoFormat.imageWidth = _imageWidth;
		videoFormat.imageHeight = _imageHeight;
		videoFormat.bytesPerRow = @[@(_imageWidth * 4)].mutableCopy;
		_videoFrame = [[OTVideoFrame alloc] initWithFormat:videoFormat];
	}
	return _videoFrame;
}

- (GPUImagePixellateFilter *)pixellateFilter {
	if (!_pixellateFilter) {
		_pixellateFilter = [[GPUImagePixellateFilter alloc] init];
	}
	return _pixellateFilter;
}

- (GPUImageView *)gpuImageView {
	if (!_gpuImageView) {
		_gpuImageView = [[GPUImageView alloc] initWithFrame:UIScreen.mainScreen.bounds];
		_gpuImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
		_gpuImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_gpuImageView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
	}
	return _gpuImageView;
}

- (UIView *)localPreviewView {
	return self.gpuImageView;
}

- (GPUImageVideoCamera *)gpuImageCamera {
	if (!_gpuImageCamera) {
		NSString *captureSession = AVCaptureSessionPreset640x480;
		
		_gpuImageCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:captureSession cameraPosition:AVCaptureDevicePositionFront];
		_gpuImageCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
		_gpuImageCamera.delegate = self;
	}
	return _gpuImageCamera;
}

- (void)setFilterType:(NSString *)filterType {
	// 如果已经是此种类型的 filter
	if ([[self filterType] isEqualToString:filterType] && _gpuImagefilter) {
		return;
	}
	_filterType = filterType;
	
	[self clearFilter];
	_gpuImagefilter = [GPUImageHelper filterGroupWithType:filterType];
	[self addFilter];
}

#pragma mark - life cycle
- (void)clearFilter {
	// 释放旧的滤镜
	if (_gpuImagefilter) {
		[_gpuImagefilter removeTarget:_gpuImageView];
		[self.gpuImageCamera removeTarget:_gpuImagefilter];
		_gpuImagefilter = nil;
	}
}

- (void)addFilter {
	[self.gpuImageCamera addTarget:_gpuImagefilter];
	[_gpuImagefilter addTarget:self.gpuImageView];
	[self.gpuImageView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
	_gpuImagefilter.delegate = self;
}

- (void)prepareManager {
	_imageWidth = 480;
	_imageHeight = 640;
	[self videoFrame];
	
	self.filterType = [[NSUserDefaults standardUserDefaults] stringForKey:@"MonkeySelectFilter"];
	[self startCamera];
}

- (void)clearManager {
	[self clearFilter];
	
	if (_gpuImageView) {
		[self.gpuImageView removeFromSuperview];
		self.gpuImageView = nil;
	}
	
	[self stopCamera];
}

#pragma mark - snap stram
- (void)snapStream:(void (^)(NSData * _Nonnull))completed {
	runAsynchronouslyOnVideoProcessingQueue(^{
		self.snapCallback = completed;
	});
}


#pragma mark - handle report screenshot、system screenshot
#define clamp(a) (a > 255 ? 255 : (a < 0 ? 0 : a))
+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
	CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	
	size_t width = CVPixelBufferGetWidth(pixelBuffer);
	size_t height = CVPixelBufferGetHeight(pixelBuffer);
	uint8_t *yBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
	size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
	uint8_t *cbCrBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
	size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
	
	int bytesPerPixel = 4;
	uint8_t *rgbBuffer = (uint8_t *)malloc(width * height * bytesPerPixel);
	
	for(int y = 0; y < height; y++) {
		uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
		uint8_t *yBufferLine = &yBuffer[y * yPitch];
		uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
		
		for(int x = 0; x < width; x++) {
			int16_t y = yBufferLine[x];
			int16_t cb = cbCrBufferLine[x & ~1] - 128;
			int16_t cr = cbCrBufferLine[x | 1] - 128;
			
			uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
			
			int16_t r = (int16_t)roundf( y + cr *  1.4 );
			int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
			int16_t b = (int16_t)roundf( y + cb *  1.765);
			
			rgbOutput[0] = 0xff;
			rgbOutput[1] = clamp(b);
			rgbOutput[2] = clamp(g);
			rgbOutput[3] = clamp(r);
		}
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8, width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
	
	CGImageRef quartzImage = CGBitmapContextCreateImage(context);
	UIImage *cropImage = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationUp];
	UIImage *convertedImage = [cropImage croppedImageWithFrame:CGRectMake(0, 0, 480, 640) angle:90 circularClip:false];
	
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	CGImageRelease(quartzImage);
	free(rgbBuffer);
	CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	
	return convertedImage;
}

#pragma mark - GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	[self handleSampleBufferInBackground:sampleBuffer];
}

- (void)handleSampleBufferInBackground:(CMSampleBufferRef)sampleBuffer {
	if (self.snapCallback) {
		CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		UIImage *convertedImage = [HWCameraManager imageFromPixelBuffer:pixelBuffer];
		NSData *imageData = UIImageJPEGRepresentation(convertedImage, 0.1);
		self.snapCallback(imageData);
		self.snapCallback = nil;
	}
}

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer {
	[self upload:pixelBuffer];
}

#pragma mark - processing filter video complete
- (void)upload:(CVPixelBufferRef)pixelBuffer {
	if (self.agora_capture) {
		CVPixelBufferLockBaseAddress(pixelBuffer, 0);
		[self.streamHandler newFrameBufferAvailable:pixelBuffer];
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	}else if (self.isCaptureOpentok) {
		CVPixelBufferLockBaseAddress(pixelBuffer, 0);
		self.videoFrame.format.estimatedCaptureDelay = 100;
		[self.videoFrame clearPlanes];
		[self.videoFrame.planes addPointer:CVPixelBufferGetBaseAddress(pixelBuffer)];
		[self.videoCaptureConsumer consumeFrame:self.videoFrame];
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	}
}

- (void)frameProcessingComplete:(GPUImageOutput *)frameBufferOutput {
//	[self upload:frameBufferOutput.framebufferForOutput.pixelBuffer];
}
#pragma mark - OTVideoCapture

/**
 * Initializes the video capturer.
 */
- (void)initCapture {
	[self prepareManager];
}
/**
 * Releases the video capturer.
 */
- (void)releaseCapture {
	[self clearManager];
}
/**
 * Starts capturing video.
 */
- (int32_t)startCapture {
	runAsynchronouslyOnVideoProcessingQueue(^{
		self.capturing = YES;
	});
	return 0;
}
/**
 * Stops capturing video.
 */
- (int32_t)stopCapture {
	runAsynchronouslyOnVideoProcessingQueue(^{
		self.capturing = NO;
	});
	return 0;
}
/**
 * Whether video is being captured.
 */
- (BOOL)isCaptureStarted {
	return self.capturing && [self.gpuImageCamera isRunning] && _opentok_capture;
}

- (BOOL)isCaptureOpentok {
	return self.isCaptureStarted;
}

/**
 * The video format of the video capturer.
 * @param videoFormat The video format used.
 */
- (int32_t)captureSettings:(OTVideoFormat *)videoFormat {
	videoFormat.pixelFormat = OTPixelFormatARGB;
	videoFormat.imageWidth = _imageWidth;
	videoFormat.imageHeight = _imageHeight;
	return 0;
}

@end
