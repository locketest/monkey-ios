//
//  KeyboardManager.h
//  Monkey
//
//  Created by 王广威 on 2017/5/26.
//  Copyright © 2017年 EXUTECH. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 System keyboard transition information.
 */
typedef struct {
	BOOL fromVisible; ///< Keyboard visible before transition.
	BOOL toVisible;   ///< Keyboard visible after transition.
	CGRect fromFrame; ///< Keyboard frame before transition.
	CGRect toFrame;   ///< Keyboard frame after transition.
	NSTimeInterval animationDuration;       ///< Keyboard transition animation duration.
	UIViewAnimationCurve animationCurve;    ///< Keyboard transition animation curve.
	UIViewAnimationOptions animationOption; ///< Keybaord transition animation option.
} KeyboardTransition;

typedef void (^KeyboardActionBlock)(KeyboardTransition keyboardTransition);

@interface KeyboardManager : NSObject

+ (instancetype)defaultManager;

- (void)addKeyboardWillShowObserver:(id)observer Action:(KeyboardActionBlock)action;
- (void)addKeyboardWillDismissObserver:(id)observer Action:(KeyboardActionBlock)action;
- (void)addKeyboardWillChangeFrameObserver:(id)observer Action:(KeyboardActionBlock)action;

- (void)removeKeyboardObserver:(id)observer;

@end

