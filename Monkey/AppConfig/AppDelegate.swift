//
//  AppDelegate.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/13/16.
//  Made with love by Kylie, Gabe, Isaiah, Harrison, Jun, Ben, Philip, and Ethan.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit

import Fabric
import Crashlytics

import Adjust
import Firebase
import FirebaseMessaging
import FBSDKCoreKit
import FBNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		FirebaseApp.configure()
		Messaging.messaging().delegate = self
		Fabric.with([Crashlytics.self])
		RemoteConfigManager.shared.fetchLatestConfig()
		AnalyticsCenter.logLaunchApp()
		
		// open from deep link
		if let options = launchOptions, let url = options[UIApplicationLaunchOptionsKey.url] as? URL {
			self.openWithDeeplinkURL(url: url.absoluteString)
		}
		self.checkIfAppUpdated()

		return true
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		FBSDKAppEvents.activateApp()
		application.applicationIconBadgeNumber = 0
	}

	// refresh device token
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let thisToken = deviceToken.base64EncodedString()
		let prevToken = Achievements.shared.apns_token
		if prevToken != thisToken {
			Messaging.messaging().apnsToken = deviceToken
			FBSDKAppEvents.setPushNotificationsDeviceToken(deviceToken)
			Achievements.shared.apns_token = thisToken
			Apns.update(token: thisToken)
		}
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		self.handleRemoteNotification(userInfo: userInfo, application: application)
		
		FBSDKAppEvents.logPushNotificationOpen(userInfo)
	}

	// app 在运行的时候收到推送通知
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		self.handleRemoteNotification(userInfo: userInfo, application: application)
		
		FBSDKAppEvents.logPushNotificationOpen(userInfo)
		FBNotificationsManager.shared().presentPushCard(forRemoteNotificationPayload: userInfo, from: nil) { (viewController, error) in
			if error != nil {
				completionHandler(.failed)
			} else {
				completionHandler(.newData)
			}
        }
    }

	func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
		self.handleRemoteNotification(userInfo: userInfo, application: application)
		
		FBSDKAppEvents.logPushNotificationOpen(userInfo, action: identifier)
		completionHandler()
	}
	
	// handle notification click and receive
	func handleRemoteNotification(userInfo: [AnyHashable : Any], application: UIApplication) {
		let notificationUserInfo = NotificationUserInfo(userInfo: userInfo)
		AnalyticsCenter.log(withEvent: .notifyClick, andParameter: [
			"source": notificationUserInfo.source,
			])
		
		if application.applicationState == .inactive {
			MessageCenter.shared.click(from: notificationUserInfo)
		}else {
			MessageCenter.shared.receive(push: notificationUserInfo)
		}
	}

	private func checkIfAppUpdated() {
		let lasVer = UserDefaults.standard.string(forKey: "kLastAppVersion")
		let newVer = Environment.appVersion
		if lasVer != newVer {
			UserDefaults.standard.set(false, forKey: showRateAlertReason.addFriendJust.rawValue)
			UserDefaults.standard.set(false, forKey: showRateAlertReason.contiLoginThreeDay.rawValue)
			UserDefaults.standard.set(false, forKey: "kHadRateBefore")
		}
	}
	
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
		self.openWithDeeplinkURL(url: userActivity.webpageURL?.absoluteString)
		return true
	}
	
	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
		self.openWithDeeplinkURL(url: url.absoluteString)
		return true
	}
	
	private func openWithDeeplinkURL(url: String?) {
		if let urlStr = url, let urlCom = NSURLComponents.init(string: urlStr) {
			let queryDict = urlCom.queryDict()

			if let urlobj = URL.init(string: urlStr) {
				Adjust.appWillOpen(urlobj)
			}

			if (urlCom.scheme == "monkey" || urlCom.host?.contains("monkey.cool") == true), let sourceStr = queryDict["source"], sourceStr.isEmpty == false {
				Achievements.shared.deeplink_source = sourceStr
			}
		}
	}
}

extension AppDelegate: MessagingDelegate {
	func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
		
	}
	
	func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
		
	}
}

extension NSNotification.Name {
	public static let MonkeyMatchDidReady: NSNotification.Name = NSNotification.Name(rawValue: "MonkeyMatchDidReady")
}

