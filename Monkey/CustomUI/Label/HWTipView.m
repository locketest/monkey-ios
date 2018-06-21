//
//  HWTipView.m
//  HOLLA
//
//  Created by 王广威 on 2018/1/27.
//  Copyright © 2018年 HOLLA. All rights reserved.
//

#import "HWTipView.h"
#import "NSString+JKSize.h"

@interface HWTipView ()

@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation HWTipView

+ (instancetype)sharedTipView {
	static HWTipView *_sharedTipView = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedTipView = [[HWTipView alloc] init];
	});
	return _sharedTipView;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self configuration];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self configuration];
}

- (void)configuration {
	self.backgroundColor = [UIColor blackColor];
	self.layer.cornerRadius = 16;
	self.layer.masksToBounds = YES;
	self.layer.shadowColor = [UIColor colorWithWhite:0.000 alpha:0.2].CGColor;
	self.layer.shadowRadius = 3;
	self.layer.shadowOffset = CGSizeMake(0, 1);
	self.layer.shadowOpacity = 1;
	
	self.contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.contentLabel.textColor = [UIColor whiteColor];
	self.contentLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
	self.contentLabel.numberOfLines = 0;
	self.contentLabel.textAlignment = NSTextAlignmentCenter;
	self.contentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
	[self addSubview:self.contentLabel];
}

+ (void)showTip:(NSString *)tip {
	[self showTip:tip at:HWTipPositionCenter];
}

+ (void)showTip:(NSString *)tip at:(HWTipPosition)position {
	[self showTip:tip at:position complete:nil];
}

+ (void)showTip:(NSString *)tip at:(HWTipPosition)position complete:(HWAction)complete {
	HWTipView *sharedTipView = [self sharedTipView];
//	@weakify(sharedTipView);
	[sharedTipView showTip:nil at:HWTipPositionCenter complete:^{
//		@strongify(sharedTipView);
		[NSObject cancelPreviousPerformRequestsWithTarget:sharedTipView selector:@selector(showTip:) object:nil];
		[[UIApplication sharedApplication].keyWindow addSubview:sharedTipView];
		[sharedTipView showTip:tip at:position complete:complete];
		[sharedTipView performSelector:@selector(showTip:) withObject:nil afterDelay:2];
	}];
}

- (void)showTip:(NSString *)tip {
	[self showTip:tip at:HWTipPositionCenter];
}

- (void)showTip:(NSString *)tip at:(HWTipPosition)position {
	[self showTip:tip at:position complete:nil];
}

- (void)showTip:(NSString *)tip at:(HWTipPosition)position complete:(HWAction)complete {
	if ([tip length] == 0) {
		if ([self.contentLabel.text length]) {
			[UIView animateWithDuration:0.15 animations:^{
				self.alpha = 0;
			} completion:^(BOOL finished) {
				[self removeFromSuperview];
				if (complete) {
					complete();
				}
			}];
		}else if (complete) {
			complete();
		}
	}else {
		self.alpha = 1;
		self.contentLabel.text = tip;
		
		// show tip
		CGFloat kScreenWidth = [UIApplication sharedApplication].keyWindow.frame.size.width;
		CGFloat kScreenHeight = [UIApplication sharedApplication].keyWindow.frame.size.height;
		CGFloat contentX = 47;
		CGFloat labelX = 18;
		CGFloat contentWidth = kScreenWidth - contentX * 2;
		CGFloat labelWidth = contentWidth - labelX * 2;
		CGFloat labelHeight = ceil([tip jk_heightWithFont:self.contentLabel.font constrainedToWidth:labelWidth]);
		CGFloat contentHeight = MIN(labelHeight + labelX * 2, kScreenHeight - 120);
		CGFloat textWidth = ceil([tip jk_widthWithFont:self.contentLabel.font constrainedToHeight:labelHeight]);
		labelWidth = MIN(labelWidth, textWidth);
		contentWidth = MIN(labelWidth + labelX * 2, kScreenWidth - contentX * 2);
		labelWidth = contentWidth - labelX * 2;
		contentX = (kScreenWidth - contentWidth) / 2;
		CGFloat contentY = [HWTipView conetentYAtPosition:position withContentHeight:contentHeight];
		self.frame = CGRectMake(contentX, contentY, contentWidth, contentHeight);
		self.contentLabel.frame = CGRectMake(labelX, labelX, labelWidth, labelHeight);
	}
}

+ (CGFloat)conetentYAtPosition:(HWTipPosition)position withContentHeight:(CGFloat)contentHeight {
	CGFloat contentY = 0;
	CGFloat kScreenHeight = [UIApplication sharedApplication].keyWindow.frame.size.height;
	
	switch (position) {
		case HWTipPositionTop:
			contentY = 64;
			break;
		case HWTipPositionBottom:
			contentY = kScreenHeight - 64 - contentHeight;
			break;
		case HWTipPositionCenter:
		default:
			contentY = (kScreenHeight - contentHeight) / 2 - 30;
			break;
	}
	return contentY;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

