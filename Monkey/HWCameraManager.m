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

@interface HWCameraManager() <GPUImageVideoCameraDelegate>

// 滤镜以及预览
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImagePixellateFilter *pixellateFilter;
@property (nonatomic, strong) GPUImageFilterGroup *gpuImagefilter;
@property (nonatomic, strong) GPUImageVideoCamera *gpuImageCamera;
@property (nonatomic, strong) GPUImageRawDataOutput *rawOut;

@end

@implementation HWCameraManager {
	BOOL _capturing;
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
	[self clearFilter];
	
	self.pixellated = YES;
	_gpuImagefilter = [[GPUImageFilterGroup alloc] init];
	[_gpuImagefilter addFilter:self.pixellateFilter];
	[_gpuImagefilter setInitialFilters:@[self.pixellateFilter]];
	[_gpuImagefilter setTerminalFilter:self.pixellateFilter];
	
	[self addFilter];
}

- (void)removePixellate {
	self.pixellated = NO;
	[self clearFilter];
	self.filterType = self.filterType;
	[self addFilter];
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
		_gpuImageView = [[GPUImageView alloc] init];
		_gpuImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
		_gpuImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_gpuImageView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
	}
	return _gpuImageView;
}

- (UIView *)localPreviewView {
	return self.gpuImageView;
}

- (GPUImageRawDataOutput *)rawOut {
	if (!_rawOut) {
		_rawOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(_imageWidth, _imageHeight) resultsInBGRAFormat:YES];
	}
	return _rawOut;
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
	
	__weak typeof(self) weakSelf = self;
	_gpuImagefilter.frameProcessingCompletionBlock = ^(GPUImageOutput *frameBufferOutput, CMTime timeShot) {
		[weakSelf frameProcessingComplete:frameBufferOutput];
	};
}

#pragma mark - life cycle
- (void)clearFilter {
	// 释放旧的滤镜
	if (_gpuImagefilter) {
		[_gpuImagefilter removeTarget:_gpuImageView];
		[_gpuImagefilter removeTarget:_rawOut];
		[self.gpuImageCamera removeTarget:_gpuImagefilter];
		_gpuImagefilter = nil;
	}
}

- (void)addFilter {
	[self.gpuImageCamera addTarget:_gpuImagefilter];
	[_gpuImagefilter addTarget:self.gpuImageView];
	[_gpuImagefilter addTarget:self.rawOut];
	[self.gpuImageView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
}

- (void)prepareManager {
	_imageWidth = 480;
	_imageHeight = 640;
	[self videoFrame];
	
	__weak typeof(self) weakSelf = self;
	[self.rawOut setNewFrameAvailableBlock:^{
		if ([weakSelf isCaptureStarted]) {
			[weakSelf.rawOut lockFramebufferForReading];
			GLubyte *rawData = weakSelf.rawOut.rawBytesForImage;
			[weakSelf.videoFrame clearPlanes];
			[weakSelf.videoFrame.planes addPointer:rawData];
			[weakSelf.videoCaptureConsumer consumeFrame:weakSelf.videoFrame];
			[weakSelf.rawOut unlockFramebufferAfterReading];
		}
	}];
	self.filterType = [[NSUserDefaults standardUserDefaults] stringForKey:@"MonkeySelectFilter"];
	[self startCamera];
}

- (void)clearManager {
	if (_gpuImagefilter) {
		[self.gpuImagefilter removeTarget:_gpuImageView];
		[self.gpuImageCamera removeTarget:_gpuImagefilter];
		_gpuImagefilter = nil;
	}
	if (_gpuImageView) {
		[self.gpuImageView removeFromSuperview];
		self.gpuImageView = nil;
	}
	
	[self stopCamera];
}

#pragma mark - GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	
}

#pragma mark - processing filter video complete
- (void)pixelBufferProcessing:(CVPixelBufferRef)pixelBuffer {
	// push video buffer
//	if (!(_capturing && _videoCaptureConsumer)) {
//		return;
//	}
}

- (void)frameProcessingComplete:(GPUImageOutput *)frameBufferOutput {
	[self pixelBufferProcessing:frameBufferOutput.framebufferForOutput.pixelBuffer];
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
		_capturing = YES;
	});
	return 0;
}
/**
 * Stops capturing video.
 */
- (int32_t)stopCapture {
	runAsynchronouslyOnVideoProcessingQueue(^{
		_capturing = NO;
	});
	return 0;
}
/**
 * Whether video is being captured.
 */
- (BOOL)isCaptureStarted {
	return _capturing && [self.gpuImageCamera isRunning];
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
