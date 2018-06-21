//
//  HWTipView.h
//  HOLLA
//
//  Created by 王广威 on 2018/1/27.
//  Copyright © 2018年 HOLLA. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^HWAction)(void);

typedef enum : NSUInteger {
	HWTipPositionCenter = 0,
	HWTipPositionTop = 1,
	HWTipPositionBottom = 2,
} HWTipPosition;

@interface HWTipView : UIView

+ (void)showTip:(NSString * _Nullable)tip at:(HWTipPosition)position complete:(_Nullable HWAction)complete;

@end

