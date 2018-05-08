//
//  MonkeyVideoRender.h
//
//  Copyright (c) 2014 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenTok/OpenTok.h>

@protocol MonkeyRendererDelegate;

@interface MonkeyVideoRender : UIView <GLKViewDelegate, OTVideoRender>

@property (nonatomic, assign) BOOL mirroring;
@property (nonatomic, assign) BOOL renderingEnabled;
@property (nonatomic, assign) BOOL effectsEnabled;
@property (nonatomic, retain) NSArray* effects;
@property (nonatomic, weak) id<MonkeyRendererDelegate> delegate;

/*
 * Clears the render buffer to a black frame
 */
- (void)clearRenderBuffer;

@end

/**
 * Used to notify the owner of this renderer that frames are being received.
 * For our example, we'll use this to wire a notification to the subscriber's
 * delegate that video has arrived.
 */
@protocol MonkeyRendererDelegate <NSObject>

- (void)renderer:(MonkeyVideoRender*)renderer
 didReceiveFrame:(OTVideoFrame*)frame;

@end
