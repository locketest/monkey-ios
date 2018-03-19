//
//  NotificationService.m
//  PushService
//
//  Created by 王广威 on 2018/3/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

#import "NotificationService.h"
#import <CommonCrypto/CommonCrypto.h>

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)downloadImage:(NSString *)imageUrl handler:(void (^)(NSURL *localSourceUrl))handler {
	NSURL *webImage = [NSURL URLWithString:imageUrl];
	NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:webImage completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		NSURL *localSourceUrl = nil;
		if (location != nil && error == nil) {
			localSourceUrl = location;
			NSError *fileManagerError = nil;
			NSString *targetUrlPath = [location.path stringByAppendingFormat:@".%@", webImage.pathExtension];
			NSURL *targetUrl = [NSURL fileURLWithPath:targetUrlPath];
			[[NSFileManager defaultManager] moveItemAtURL:location toURL:targetUrl error:&fileManagerError];
			if (!fileManagerError) {
				localSourceUrl = targetUrl;
			}
		}
		handler(localSourceUrl);
	}];
	
	[downloadTask resume];
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
	self.contentHandler = contentHandler;
	self.bestAttemptContent = [request.content mutableCopy];
	
	NSDictionary *userInfo = request.content.userInfo;
	id userInfoData = userInfo[@"data"];
	if (!userInfoData) {
		NSDictionary *aps = userInfo[@"aps"];
		if ([aps isKindOfClass:[NSDictionary class]]) {
			userInfoData = aps[@"data"];
		}
	}
	
	if ([userInfoData isKindOfClass:[NSString class]]) {
		NSData *data = [userInfoData dataUsingEncoding:NSUTF8StringEncoding];
		NSError *convertError = nil;
		NSDictionary *convertParameter = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&convertError];
		if ([convertParameter isKindOfClass:[NSDictionary class]] && [[convertParameter allKeys] count]) {
			userInfoData = convertParameter;
		}
	}
	
	if (userInfoData && [userInfoData isKindOfClass:[NSDictionary class]]) {
		NSString *imageURLString = userInfoData[@"image"];
		if ([imageURLString length]) {
			[self downloadImage:imageURLString handler:^(NSURL *localSourceUrl) {
				NSError *attachmentCreateError = nil;
				UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"image_downloaded" URL:localSourceUrl options:nil error:&attachmentCreateError];
				if (!attachmentCreateError) {
					self.bestAttemptContent.attachments = @[attachment];
				}
				contentHandler(self.bestAttemptContent);
			}];
		}else {
			contentHandler(self.bestAttemptContent);
		}
	}else {
		contentHandler(self.bestAttemptContent);
	}
}

- (void)serviceExtensionTimeWillExpire {
	// Called just before the extension will be terminated by the system.
	// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
	self.contentHandler(self.bestAttemptContent);
}

- (NSString *)md5StringWith:(NSString *)originString {
	NSData *decodeData = [originString dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(decodeData.bytes, (CC_LONG)decodeData.length, result);
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

@end


