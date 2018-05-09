//
//  KeyboardManager.m
//  Monkey
//
//  Created by 王广威 on 2017/5/26.
//  Copyright © 2017年 EXUTECH. All rights reserved.
//

#import "KeyboardManager.h"
#import <pthread.h>

/**
 Submits a block for asynchronous execution on a main queue and returns immediately.
 */
static inline void dispatch_async_on_main_queue(void (^block)(void)) {
	if (pthread_main_np()) {
		block();
	} else {
		dispatch_async(dispatch_get_main_queue(), block);
	}
}

@interface KeyboardObserverContainer : NSObject

@property(nonatomic, copy) KeyboardActionBlock keyboardShowActionBlock;
@property(nonatomic, copy) KeyboardActionBlock keyboardDismissActionBlock;
@property(nonatomic, copy) KeyboardActionBlock keyboardFrameChangeActionBlock;

@property(nonatomic, weak) id keyboardObserver;

@end

@implementation KeyboardObserverContainer

@end

@interface KeyboardManager ()

@property (nonatomic, strong) NSMutableSet<KeyboardObserverContainer *> *keyboardObservers;

@end

@implementation KeyboardManager

+ (instancetype)defaultManager {
	static KeyboardManager *_defaultManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_defaultManager = [[self alloc] init];
	});
	
	
	return _defaultManager;
}

- (NSMutableSet<KeyboardObserverContainer *> *)keyboardObservers {
	if (!_keyboardObservers) {
		_keyboardObservers = [NSMutableSet setWithCapacity:1];
	}
	return _keyboardObservers;
}

- (void)addSystemKeyboardObserver {
	if (self.keyboardObservers.count == 0) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	}
}

- (void)removeSystemKeyboardObserver {
	if (self.keyboardObservers.count == 0) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	}
}


- (void)addKeyboardWillShowObserver:(id)observer Action:(KeyboardActionBlock)action {
	[self addSystemKeyboardObserver];
	
	__block KeyboardObserverContainer *observerContainer = nil;
	[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
		if (obj.keyboardObserver == observer) {
			observerContainer = obj;
			*stop = YES;
		}
	}];
	
	if (!observerContainer) {
		observerContainer = [[KeyboardObserverContainer alloc] init];
		observerContainer.keyboardObserver = observer;
	}
	observerContainer.keyboardShowActionBlock = action;
	
	[self.keyboardObservers addObject:observerContainer];
}
- (void)addKeyboardWillDismissObserver:(id)observer Action:(KeyboardActionBlock)action {
	[self addSystemKeyboardObserver];
	
	__block KeyboardObserverContainer *observerContainer = nil;
	[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
		if (obj.keyboardObserver == observer) {
			observerContainer = obj;
			*stop = YES;
		}
	}];
	
	if (!observerContainer) {
		observerContainer = [[KeyboardObserverContainer alloc] init];
		observerContainer.keyboardObserver = observer;
	}
	observerContainer.keyboardDismissActionBlock = action;
	
	[self.keyboardObservers addObject:observerContainer];
}
- (void)addKeyboardWillChangeFrameObserver:(id)observer Action:(KeyboardActionBlock)action {
	[self addSystemKeyboardObserver];
	
	__block KeyboardObserverContainer *observerContainer = nil;
	[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
		if (obj.keyboardObserver == observer) {
			observerContainer = obj;
			*stop = YES;
		}
	}];
	
	if (!observerContainer) {
		observerContainer = [[KeyboardObserverContainer alloc] init];
		observerContainer.keyboardObserver = observer;
	}
	observerContainer.keyboardFrameChangeActionBlock = action;
	
	[self.keyboardObservers addObject:observerContainer];
}
- (void)removeKeyboardObserver:(id)observer {
	__block KeyboardObserverContainer *observerContainer = nil;
	[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
		if (obj.keyboardObserver == observer) {
			observerContainer = obj;
			*stop = YES;
		}
	}];
	if (observerContainer) {
		observerContainer.keyboardShowActionBlock = nil;
		observerContainer.keyboardDismissActionBlock = nil;
		observerContainer.keyboardFrameChangeActionBlock = nil;
		[self.keyboardObservers removeObject:observerContainer];
	}
	
	[self removeSystemKeyboardObserver];
}


+ (KeyboardTransition)transitionFromKeyboardNoti:(NSNotification *)keyboardNoti {
	
	KeyboardTransition trans = {0};
	
	NSDictionary *info = keyboardNoti.userInfo;
	if (!info) return trans;
	
	NSValue *beforeValue = info[UIKeyboardFrameBeginUserInfoKey];
	NSValue *afterValue = info[UIKeyboardFrameEndUserInfoKey];
	NSNumber *curveNumber = info[UIKeyboardAnimationCurveUserInfoKey];
	NSNumber *durationNumber = info[UIKeyboardAnimationDurationUserInfoKey];
	
	CGRect before = beforeValue.CGRectValue;
	CGRect after = afterValue.CGRectValue;
	UIViewAnimationCurve curve = curveNumber.integerValue;
	NSTimeInterval duration = durationNumber.doubleValue;
	
	// ignore zero end frame
	if (after.size.width <= 0 && after.size.height <= 0) return trans;
	
	// from
	trans.fromFrame = before;
	
	// to
	trans.toFrame = after;
	trans.animationDuration = duration;
	trans.animationCurve = curve;
	trans.animationOption = curve << 16;
	
	return trans;
}

- (void)keyboardWillShow:(NSNotification *)keyboardWillShowNoti {
	if (self.keyboardObservers.count == 0) {
		return;
	}
	
	KeyboardTransition transition = [KeyboardManager transitionFromKeyboardNoti:keyboardWillShowNoti];
	
	dispatch_async_on_main_queue(^{
		[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
			if (obj.keyboardShowActionBlock) {
				obj.keyboardShowActionBlock(transition);
			}
		}];
	});
}

- (void)keyboardWillDismiss:(NSNotification *)keyboardWillDismissNoti {
	if (self.keyboardObservers.count == 0) {
		return;
	}
	
	KeyboardTransition transition = [KeyboardManager transitionFromKeyboardNoti:keyboardWillDismissNoti];
	
	dispatch_async_on_main_queue(^{
		[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
			if (obj.keyboardDismissActionBlock) {
				obj.keyboardDismissActionBlock(transition);
			}
		}];
	});
}

- (void)keyboardWillChangeFrame:(NSNotification *)keyboardWillChangeFrameNoti {
	if (self.keyboardObservers.count == 0) {
		return;
	}
	
	KeyboardTransition transition = [KeyboardManager transitionFromKeyboardNoti:keyboardWillChangeFrameNoti];
	
	dispatch_async_on_main_queue(^{
		[self.keyboardObservers enumerateObjectsUsingBlock:^(KeyboardObserverContainer * _Nonnull obj, BOOL * _Nonnull stop) {
			if (obj.keyboardFrameChangeActionBlock) {
				obj.keyboardFrameChangeActionBlock(transition);
			}
		}];
	});
}

@end

