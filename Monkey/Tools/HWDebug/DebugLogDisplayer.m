//
//  DebugLogDisplayer.m
//  Monkey
//
//  Created by wei on 2018/06/14.
//  Copyright © 2018年 Monkey. All rights reserved.
//

#import "DebugLogDisplayer.h"
#import "Monkey-Swift.h"
#import "NSObject+Runtime.h"

@class DebugLogDisplayer;

@interface UIWindow (DebugMode)

@property (nonatomic, strong, readonly) UIButton *debugSwitch;

- (void)debugMode_setRootViewController:(UIViewController *)rootViewController;

- (void)debugMode_makeKeyAndVisible;

- (void)debugMode_layoutSubviews;

@end

@implementation UIWindow (DebugMode)

+ (void)load {
//	[self swizzleInstanceMethod:@selector(setRootViewController:) with:@selector(debugMode_setRootViewController:)];
//	[self swizzleInstanceMethod:@selector(makeKeyAndVisible) with:@selector(debugMode_makeKeyAndVisible)];
//	[self swizzleInstanceMethod:@selector(layoutSubviews) with:@selector(debugMode_layoutSubviews)];
}

- (void)debugMode_setRootViewController:(UIViewController *)rootViewController {
	[self debugMode_setRootViewController:rootViewController];
	if (self.isKeyWindow) {
		[self bringSubviewToFront:[self debugSwitch]];
	}
}

- (void)debugMode_makeKeyAndVisible {
	[self debugMode_makeKeyAndVisible];
	[self addSubview:[self debugSwitch]];
}

- (void)debugMode_layoutSubviews {
	[self debugMode_layoutSubviews];
	if (self.isKeyWindow) {
		[self bringSubviewToFront:[self debugSwitch]];
	}
}

- (UIButton *)debugSwitch {
	UIButton *debugSwitch = objc_getAssociatedObject(self, _cmd);
	if (!debugSwitch) {
		debugSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
		debugSwitch.frame = CGRectMake(0, self.frame.size.height - 200, 51, 42);
		debugSwitch.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
		[debugSwitch setImage:[UIImage imageNamed:@"logo"] forState:UIControlStateNormal];
		[debugSwitch addTarget:self action:@selector(showDebugCollection) forControlEvents:UIControlEventTouchUpInside];
		objc_setAssociatedObject(self, _cmd, debugSwitch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return debugSwitch;
}

- (void)showDebugCollection {
	DebugLogDisplayer *debugDisplayer = [[DebugLogDisplayer alloc] initWithFrame:self.bounds];
	debugDisplayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:debugDisplayer];
}

@end

static NSString *kHWDebugLogDisplayerTableViewCellID = @"kHWDebugLogDisplayerTableViewCellID";

@interface DebugLogDisplayer () <UITableViewDelegate, UITableViewDataSource, LogObserver>

@property (nonatomic, strong) UITableView *logView;

@property (nonatomic, strong) UITextView *detailView;
@property (nonatomic, strong) UIControl *detailCover;
@property (nonatomic, strong) UIButton *detailCopyBtn;

@end

@implementation DebugLogDisplayer

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		LogManager.shared.logObserver = self;
		[self configureApperance];
	}
	return self;
}

- (void)configureApperance {
	self.backgroundColor = [UIColor whiteColor];
	CGFloat topMargin = 64;
	CGFloat topInsert = 0;
	if (@available(iOS 11.0, *)) {
		UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
		topInsert = mainWindow.safeAreaLayoutGuide.layoutFrame.origin.y;
		topMargin += topInsert;
	}
	
	self.logView = [[UITableView alloc] initWithFrame:CGRectMake(0, topMargin, self.frame.size.width, self.frame.size.height - topMargin)];
	self.logView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.logView.backgroundColor = [UIColor whiteColor];
	self.logView.delegate = self;
	self.logView.dataSource = self;
	self.logView.tableFooterView = [UIView new];
	[self addSubview:self.logView];
	
	UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[closeBtn setTitle:@"Close" forState:UIControlStateNormal];
	[closeBtn sizeToFit];
	[closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
	closeBtn.x = 10;
	closeBtn.y = 10 + topInsert;
	[self addSubview:closeBtn];
	[closeBtn addTarget:self action:@selector(hideself) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
	[clearBtn sizeToFit];
	[clearBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
	clearBtn.x = closeBtn.width + 20;
	clearBtn.y = 10 + topInsert;
	[self addSubview:clearBtn];
	[clearBtn addTarget:self action:@selector(clearBtnClicked) forControlEvents:UIControlEventTouchUpInside];
	
	UILabel *titleLabel = [[UILabel alloc] init];
	titleLabel.text = @"Logs";
	titleLabel.font = [UIFont systemFontOfSize:18];
	[titleLabel sizeToFit];
	titleLabel.centerX = self.width * .5;
	titleLabel.y = 10 + topInsert;
	[self addSubview:titleLabel];
	
	self.detailView = [[UITextView alloc] initWithFrame:CGRectMake(36, topMargin, self.frame.size.width - 72, self.frame.size.height - topMargin * 2)];
	self.detailView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.detailCover = [[UIControl alloc] initWithFrame:self.bounds];
	self.detailCover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.detailCover.backgroundColor = [UIColor blackColor];
	self.detailCover.alpha = .5;
	[self.detailCover addTarget:self action:@selector(detailCoverClicked) forControlEvents:UIControlEventTouchUpInside];
	
	self.detailCopyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.detailCopyBtn setTitle:@"  Copy  " forState:UIControlStateNormal];
	[self.detailCopyBtn sizeToFit];
	[self.detailCopyBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
	[self.detailCopyBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
	self.detailCopyBtn.centerX = self.width *.5;
	self.detailCopyBtn.y = self.detailView.y + self.detailView.height + 10;
	[self.detailCopyBtn addTarget:self action:@selector(detailCopyBtnClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)hideself {
	LogManager.shared.logObserver = nil;
	[self removeFromSuperview];
}

#pragma mark - recognize func
- (void)detailCoverClicked {
	[self.detailCover removeFromSuperview];
	[self.detailView removeFromSuperview];
	[self.detailCopyBtn removeFromSuperview];
}

- (void)clearBtnClicked {
	// clear log
	[LogManager.shared clearLog];
}

- (void)detailCopyBtnClicked {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = self.detailView.text;
	self.detailCopyBtn.enabled = false;
}

#pragma mark - tv datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return LogManager.shared.logCollection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kHWDebugLogDisplayerTableViewCellID];
	if (!cell) {
		cell = [tableView dequeueReusableCellWithIdentifier:kHWDebugLogDisplayerTableViewCellID];
	}
	
	MonkeyLog *thisLog = LogManager.shared.logCollection[indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"%ld - %@", (long)indexPath.row + 1, thisLog.type];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm:ss"];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", [formatter stringFromDate:thisLog.time], thisLog.subTitle];
	return cell;
}

#pragma mark - tv delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:false];
	[self addSubview:self.detailCover];
	[self addSubview:self.detailView];
	[self addSubview:self.detailCopyBtn];
	self.detailCopyBtn.enabled = true;
	
	MonkeyLog *thisLog = LogManager.shared.logCollection[indexPath.row];
	NSString *tmpStr = [[[[thisLog.info description] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"] stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""] stringByReplacingOccurrencesOfString:@"\\\\U" withString:@"\\U"];
	if (tmpStr.length) {
		self.detailView.text = [DebugLogDisplayer replaceUnicode:tmpStr];
	}else {
		self.detailView.text = nil;
	}
}

#pragma mark - private func
+ (NSString *)replaceUnicode:(NSString *)unicodeStr {
	NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
	NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
	NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
	NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
	NSString *returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:NULL];
	
	return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}

- (void)LogCollectionChanged {
	[self.logView reloadData];
}

@end
