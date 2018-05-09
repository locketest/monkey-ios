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
import RealmSwift
import Realm
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
        
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		FirebaseApp.configure()
		Fabric.with([Crashlytics.self])
		Messaging.messaging().delegate = self
		RemoteConfigManager.shared.fetchLatestConfig()
		AnaliticsCenter.logLaunchApp()
		
		window?.layer.cornerRadius = 4
		window?.layer.masksToBounds = true
		
		if window?.rootViewController == nil {
			let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let mainVC = mainStoryboard.instantiateInitialViewController()
			
			window?.rootViewController = mainVC
		}
		
		if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
			handleNotification(application: application, userInfo: userInfo)
		}
		
		if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? [AnyHashable : Any] {
			handleNotification(application: application, userInfo: userInfo)
		}
        
        if  let options = launchOptions,
            let url = options[UIApplicationLaunchOptionsKey.url] as? URL{
            self.openWithDeeplinkURL(url: url.absoluteString)
        }
		
		application.applicationIconBadgeNumber = 0
		self.checkIfAppUpdated()
		self.initUserDefaultsValueFunc()
		
		return true
	}
	
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            self.openWithDeeplinkURL(url: userActivity.webpageURL?.absoluteString)
        }
		return true
	}
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        self.openWithDeeplinkURL(url: url.absoluteString)
        return true
    }
    
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		return handleOpen(url: url, options:options)
	}
	
	var userEnteredAt : Date?
	
	func applicationWillResignActive(_ application: UIApplication) {
		if let secondsInSession = userEnteredAt?.timeIntervalSinceNow {
			let lifetimeSeconds = APIController.shared.currentUser?.seconds_in_app.value ?? 0
			let newSecondsInApp = Int(-secondsInSession) + lifetimeSeconds
			APIController.shared.currentUser?.update(attributes: [.seconds_in_app(newSecondsInApp)], completion: { (error: APIError?) in
				print("Updated seconds in app: \(-secondsInSession) + \(lifetimeSeconds) = \(newSecondsInApp)")
			})
		}
		userEnteredAt = nil
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		FBSDKAppEvents.activateApp()
		
		userEnteredAt = Date()
		APIController.shared.currentUser?.reload(completion: { (error: APIError?) in
			guard error == nil else {
				// we are doing nothing w error currently, yolo
				return
			}
		})
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		application.applicationIconBadgeNumber = 0
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		
	}
	
	func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
		UserDefaults.standard.set(notificationSettings.types.contains(.alert), forKey: "apns_alert")
		UserDefaults.standard.set(notificationSettings.types.contains(.badge), forKey: "apns_badge")
		UserDefaults.standard.set(notificationSettings.types.contains(.sound), forKey: "apns_sound")
		Apns.update(callback: nil)
	}
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error.localizedDescription)
	}
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		Messaging.messaging().apnsToken = deviceToken
		FBSDKAppEvents.setPushNotificationsDeviceToken(deviceToken)
		UserDefaults.standard.set(deviceToken.base64EncodedString(), forKey: "apns_token")
		
		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		print("device token:\(token)")
		Apns.update(callback: nil)
	}
	
	// receive remote notification
	// e: emoji for in app notification
	// t: text for in app emoji notifcation (optional - alert used by default)
	// a: weather the url provided should be opened even if the app is already open
	// u: the url to open
	// i: how many seconds the notification should be shown for
	// n: notification type
	// s: Sound (raw value)
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		self.logNotificationClick(userInfo: userInfo)
		FBSDKAppEvents.logPushNotificationOpen(userInfo)
        self.handleNotification(application: application, userInfo: userInfo)
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
        
        self.handleRemoteNotificationFunc(userInfo: userInfo, application: application)
    }
    
    func handleRemoteNotificationFunc(userInfo: [AnyHashable : Any], application: UIApplication) {
		if let notiInfoData = userInfo["data"] as? [String: Any], let link = notiInfoData["link"] as? String {
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: RemoteNotificationTag), object:link)
			UserDefaults.standard.setValue(link, forKey: KillAppBananaNotificationTag)
		}
    }
    
	func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
		self.logNotificationClick(userInfo: userInfo)
		FBSDKAppEvents.logPushNotificationOpen(userInfo, action: identifier)
		completionHandler()
	}
    
	// local notification
	func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
		handleNotification(application: application, userInfo: notification.userInfo ?? [:])
	}
	func handleNotification(application: UIApplication, userInfo:[AnyHashable : Any]) {
		let notificationUserInfo = NotificationUserInfo(userInfo: userInfo)
		
		if let badgeNumber = notificationUserInfo.aps?["badge"] as? Int {
			application.applicationIconBadgeNumber = badgeNumber
		}
		
		guard application.applicationState != .active else {
			NotificationManager.shared.handleNotification(userInfo)
			return
		}
		
		// 如果是 emoji
		if let text = userInfo["t"] as? String ?? notificationUserInfo.aps?["alert"] as? String, let emoji = notificationUserInfo.emoji {
			var emojiNotificationUserInfo: [String:Any] = [
				"text": text,
				"emoji": emoji,
				"type": NotificationType(rawValue: notificationUserInfo.notificationType ?? 0) ?? NotificationType.default,
				"urls": notificationUserInfo.urls ?? [String]()
			]
			if let soundRawValue = notificationUserInfo.sound {
				if let sound = Sound(rawValue: soundRawValue) {
					emojiNotificationUserInfo["sound"] = sound
				}
			}
			if let timeout = notificationUserInfo.displayTimeout?.doubleValue {
				emojiNotificationUserInfo["timeout"] = timeout
			}
			
			NotificationCenter.default.post(name: .emojiNotification, object: nil, userInfo: emojiNotificationUserInfo)
		}
		
		if (notificationUserInfo.alwaysOpenURL == 1 || application.applicationState != UIApplicationState.active), let urls = notificationUserInfo.urls {
			self.openNotificationURLs(urls: urls)
		}
	}
	
	//
	func logNotificationClick(userInfo: [AnyHashable: Any]) {
		let notificationUserInfo = NotificationUserInfo(userInfo: userInfo)
		AnaliticsCenter.log(withEvent: .notifyClick, andParameter: ["source": notificationUserInfo.source])
	}
    /**
     初始化相关标记
     */
    func initUserDefaultsValueFunc() {
        UserDefaults.standard.setValue("", forKey: KillAppBananaNotificationTag)
    }
	
	// will open first URL possible
	func openNotificationURLs(urls: [String]) {
		for urlString in urls {
			if let url = URL(string: urlString) {
				if UIApplication.shared.canOpenURL(url) {
					DispatchQueue.main.async() {
						if url.scheme == "monkey" {
							let _ = self.handleOpen(url: url)
							return
						}
						UIApplication.shared.openURL(url)
					}
					return
				}
			}
		}
	}
	
	@discardableResult func handleOpen(url: URL, options:[UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		if var topController = UIApplication.shared.keyWindow?.rootViewController {
			let components = url.pathComponents
			let destination = LinkDestination(rawValue: url.host ?? "") ?? .home
			let specifier:String? = components.count > 1 ? components[1] : nil
			var parameters:[AnyHashable:Any] = [:]
			let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL:false)
			
			if let items = urlComponents?.queryItems {
				for item in items {
					guard let value:String = item.value else {
						continue
					}
					
					parameters[item.name] = value
				}
			}
			
			let deepLink = DeepLink(destination: destination, specifier: specifier, parameters: parameters)
			
			if deepLink.destination == .authorize {
				FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
				return true
			}
			
			if let callId = parameters["chat_id"] as? String  {
				IncomingCallManager.shared.skipCallIds.append(callId)
			}
			
			
			while let presentedViewController = topController.presentedViewController {
				topController = presentedViewController
			}
			
			if let authVC = topController as? AuthViewController { // triggered on cold launch
				authVC.linkOnCompletion = deepLink
				return true
			}
			
			// for consistent navigations we're going to dismiss VC's above mainVC (for handling backgrounded); cold launch will already be handled above
			while let presentingViewController = topController.presentingViewController { // finds the mainVC on the stack and dismisses all VC's above it
				if presentingViewController is AuthViewController { // corner case, backgrounded on mainVC so nothing to dismiss
					self.handleNavigationFrom(topController: topController, withDeepLink: deepLink)
					return true
				}
				
				if presentingViewController is MainViewController {
					
					// according to (https://stackoverflow.com/questions/2944191/iphone-dismiss-multiple-viewcontrollers) dismissing a VC also dismisses all of its children so this should always work no matter how deep we get in future
					topController.dismiss(animated: true, completion: {
						DispatchQueue.main.async {
							self.handleNavigationFrom(topController: presentingViewController, withDeepLink: deepLink)
						}
					})
					return true
				}
				topController = presentingViewController
			}
			return false
		}
		return false
	}
	
	func handleNavigationFrom(topController:UIViewController, withDeepLink:DeepLink) {
		let destination = withDeepLink.destination
		let specifier = withDeepLink.specifier
		let options = withDeepLink.parameters
		
		// no navigation, post instagram login
		guard destination != .instagram else {
			NotificationCenter.default.post(name: .instagramLoginNotification, object: options)
			return
		}
		
		guard let mainVC = topController as? MainViewController else {
			print("handleOpen method in AppDelegate does not work as expected. Plz debug")
			return
		}
		
		var viewControllerToPresent = mainVC.swipableViewControllerToPresentOnLeft
		
		switch destination {
		case .messages, .chat:
			viewControllerToPresent = mainVC.swipableViewControllerToPresentOnLeft
			
			if let friendsViewController = viewControllerToPresent as? FriendsViewController {
				friendsViewController.initialConversation = specifier
				friendsViewController.initialConversationOptions = options
			}
		case .trees:
			viewControllerToPresent = mainVC.swipableViewControllerToPresentOnRight
		case .settings:
			viewControllerToPresent = mainVC.swipableViewControllerToPresentOnBottom
		case .login:
			// pass login to authvc so that we can use code on view controller
			NotificationCenter.default.post(name: .loginNotification, object: withDeepLink.parameters)
			return
		default:
			break
		}
		
		guard let toPresent = viewControllerToPresent else {
			return
		}
		
        mainVC.present(toPresent, animated: true, completion: nil)
	}
	
	func checkIfAppUpdated() {
		let lasVer = UserDefaults.standard.string(forKey: "kLastAppVersion")
		let newVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
		if lasVer != newVer {
			UserDefaults.standard.set(false, forKey: showRateAlertReason.addFriendJust.rawValue)
			UserDefaults.standard.set(false,forKey: showRateAlertReason.contiLoginThreeDay.rawValue)
			UserDefaults.standard.set(false,forKey: "kHadRateBefore")
		}
	}
    
    func openWithDeeplinkURL(url:String?) {
        if let urlStr = url,
            let urlCom = NSURLComponents.init(string: urlStr){
            let queryDict = urlCom.queryDict()
            
            if let urlobj = URL.init(string: urlStr) {
                Adjust.appWillOpen(urlobj)
            }
            
            if (urlCom.scheme == "monkey" || urlCom.host == "join.monkey.cool"),
                let sourceStr = queryDict["source"] ,
                sourceStr.count != 0{
                Environment.deeplink_source = sourceStr
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

class NotificationUserInfo {
	private let userInfo: [AnyHashable: Any]
	init(userInfo: [AnyHashable: Any]) {
		self.userInfo = userInfo
	}
	var aps: [AnyHashable: Any]? {
		return userInfo["aps"] as? [AnyHashable: Any]
	}
	var attachData: [AnyHashable: Any]? {
		var attachInfo = userInfo["data"] ?? aps?["data"]
		
		if attachInfo != nil, let attachString: String = attachInfo as? String, let attachData = attachString.data(using: .utf8) {
			
			let convertInfo = try? JSONSerialization.jsonObject(with: attachData, options: JSONSerialization.ReadingOptions.mutableContainers)
			if let convertDic = convertInfo, convertDic is [String: String] {
				attachInfo = convertDic
			}
		}
		return attachInfo as? [AnyHashable: Any]
	}
	var emoji: String? {
		return userInfo["e"] as? String
	}
	var inAppText: String? {
		return userInfo["t"] as? String
	}
	var alwaysOpenURL: Int? {
		return userInfo["a"] as? Int
	}
	var urls: [String]? {
		return userInfo["u"] as? [String]
	}
	var displayTimeout: NSNumber? {
		return userInfo["i"] as? NSNumber
	}
	var notificationType: Int? {
		return userInfo["n"] as? Int
	}
	var sound: Int? {
		return userInfo["s"] as? Int
	}
	var source: String {
		return userInfo["src"] as? String ?? attachData?["source"] as? String ?? "other"
	}
}

/// Enumeration for string representation of possible view controllers to present from an APNS notification
enum LinkDestination: String {
	case messages = "messages"
	case home = "home"
	case chat = "chat"
	case settings = "settings"
	case trees = "trees"
	case instagram = "instagram-login"
	case login = "login"
	case authorize = "authorize"
}

/// Structure for deep link. Destination = navigation, specifier = secondary (relationship etc), parameters = additional components that are not necessarily navigation (incoming call, etc)
struct DeepLink {
	var destination:LinkDestination
	var specifier:String?
	var parameters:[AnyHashable:Any]?
	
	init(destination:LinkDestination, specifier:String?, parameters:[AnyHashable:Any]?) {
		self.destination = destination
		self.specifier = specifier
		self.parameters = parameters
	}
}

enum NotificationType: Int {
	case `default` = 0
	case onboardingAcceptReminder = 1
	case onboardingSkippedReminder = 2
	case onboardingAddMinuteReminder = 3
	case onboardingMinuteMatchReminder = 4
	// case onboardingAddSnapchatReminder = 5
	case onboardingSnapchatMatchReminder = 6
	case inCall = 7 // this type is only show in calls and dismissed at the end of a call
	case newMessage = 8 // this type is only show in calls and dismissed at the end of a call
}
