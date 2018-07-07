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

import Firebase
import FBSDKCoreKit
import FBNotifications
import FirebaseMessaging
import Adjust

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		// This migration works because prior to promptedNotifications being introduced in 2.0.2, all users were prompted on the permissions page.
		if Achievements.shared.grantedPermissionsV1 {
			Achievements.shared.grantedPermissionsV2 = true
			Achievements.shared.promptedNotifications = true
		}
		
		if let options = launchOptions, let url = options[UIApplicationLaunchOptionsKey.url] as? URL{
			self.openWithDeeplinkURL(url: url.absoluteString)
		}
		application.applicationIconBadgeNumber = 0

		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		FirebaseApp.configure()
		Fabric.with([Crashlytics.self])
		RemoteConfigManager.shared.fetchLatestConfig()
		AnalyticsCenter.logLaunchApp()
		self.checkIfAppUpdated()

		return true
	}

	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
		self.openWithDeeplinkURL(url: userActivity.webpageURL?.absoluteString)
		return true
	}

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        self.openWithDeeplinkURL(url: url.absoluteString)
        return true
    }

	var userEnteredAt : Date?
	func applicationWillResignActive(_ application: UIApplication) {
		if let secondsInSession = userEnteredAt?.timeIntervalSinceNow {
			let lifetimeSeconds = APIController.shared.currentUser?.seconds_in_app ?? 0
			let newSecondsInApp = Int(-secondsInSession) + lifetimeSeconds
			
			APIController.shared.currentUser?.update(attributes: [.seconds_in_app(newSecondsInApp)], completion: { (_) in
				
			})
		}
		self.userEnteredAt = nil
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		FBSDKAppEvents.activateApp()

		self.userEnteredAt = Date()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		application.applicationIconBadgeNumber = 0
	}

	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		
		let currentDeviceTokenString = deviceToken.base64EncodedString()
		Messaging.messaging().apnsToken = deviceToken
		FBSDKAppEvents.setPushNotificationsDeviceToken(deviceToken)
		UserDefaults.standard.set(currentDeviceTokenString, forKey: "apns_token")
		Apns.update(token: currentDeviceTokenString, callback: nil)
	}

	// receive remote notification
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		self.logNotificationClick(userInfo: userInfo)
		FBSDKAppEvents.logPushNotificationOpen(userInfo)
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		self.logNotificationClick(userInfo: userInfo)
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
		self.logNotificationClick(userInfo: userInfo)
		FBSDKAppEvents.logPushNotificationOpen(userInfo, action: identifier)
		completionHandler()
	}

	// log notification click
	private func logNotificationClick(userInfo: [AnyHashable: Any]) {
		let notificationUserInfo = NotificationUserInfo(userInfo: userInfo)
		AnalyticsCenter.log(withEvent: .notifyClick, andParameter: ["source": notificationUserInfo.source])
		
		// banana
		if notificationUserInfo.link?.contains("banana_recap_popup") == true {
			UserDefaults.standard.setValue(link, forKey: KillAppBananaNotificationTag)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: RemoteNotificationTag), object:link)
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

