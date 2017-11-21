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
import Amplitude_iOS
import Branch
import RealmSwift
import Realm
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let secretMessage = StopReverseEngineeringMonkeyAndAskForAJob()
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // This migration works because prior to promptedNotifications being introduced in 2.0.2, all users were prompted on the permissions page.
        if Achievements.shared.grantedPermissionsV1 {
            Achievements.shared.grantedPermissionsV2 = true
            Achievements.shared.promptedNotifications = true
        }

        BuddyBuildSDK.setup()

        Amplitude.shared.initializeApiKey("a5d6376e08ee446e548b9616aec5d9e0")
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        Fabric.with([Answers.self, Branch.self, Crashlytics.self])
        Branch.getInstance().initSession(launchOptions: launchOptions)

        window?.layer.cornerRadius = 4
        window?.layer.masksToBounds = true
        OTAudioDeviceManager.setAudioDevice(OTDefaultAudioDevice.shared())

        if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            handleNotification(application: application, userInfo: userInfo)
        }

        if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? [AnyHashable : Any] {
            handleNotification(application: application, userInfo: userInfo)
        }
        if window?.rootViewController == nil {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let mainVC = mainStoryboard.instantiateInitialViewController()

            window?.rootViewController = mainVC
        }

        // Reset achievements for bonus bananas on launch, uses `facebook_friends_invited` and whether or not its enabled by the server upon reset
        Achievements.shared.authorizedFacebookForBonusBananas = false

        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return Branch.getInstance().continue(userActivity)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleOpen(url: url, options:options)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

        if let secondsInSession = userEnteredAt?.timeIntervalSinceNow {
            let lifetimeSeconds = APIController.shared.currentUser?.seconds_in_app.value ?? 0
            let newSecondsInApp = Int(-secondsInSession) + lifetimeSeconds
            APIController.shared.currentUser?.update(attributes: [.seconds_in_app(newSecondsInApp)], completion: { (error: APIError?) in
                print("Updated seconds in app: \(-secondsInSession) + \(lifetimeSeconds) = \(newSecondsInApp)")
            })
        }
        userEnteredAt = nil
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

    }
    /// The `Date` at which the user began their current session, used to later caculate their session length
    var userEnteredAt : Date?

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        userEnteredAt = Date()
        APIController.shared.currentUser?.reload(completion: { (error: APIError?) in
             guard error == nil else {
                // we are doing nothing w error currently, yolo
                return
            }
            print("Reloaded current user from applicationDidBecomeActive")
        })
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
        UserDefaults.standard.set(deviceToken.base64EncodedString(), forKey: "apns_token")
        Apns.update(callback: nil)
    }
    /*func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     completionHandler(.noData)
     }
     func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
     completionHandler()
     }*/
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {

    }
    // e: emoji for in app notification
    // t: text for in app emoji notifcation (optional - alert used by default)
    // a: weather the url provided should be opened even if the app is already open
    // u: the url to open
    // i: how many seconds the notification should be shown for
    // n: notification type
    // s: Sound (raw value)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        handleNotification(application: application, userInfo: userInfo)
    }
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

        if application.applicationState != UIApplicationState.active {
            Amplitude.shared.logEvent("Opened App Via Push Notification", withEventProperties: [
                "info": userInfo,
                "state": UIApplication.shared.applicationState.rawValue,
                ])
        }
        if let text = userInfo["t"] as? String ?? notificationUserInfo.aps?["alert"] as? String, let emoji = notificationUserInfo.emoji {
            var emojiNotificationUserInfo:[String:Any] = [
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
                    Amplitude.shared.logEvent("Opened URL From Push Notification", withEventProperties: [
                        "url": urlString,
                        "state": UIApplication.shared.applicationState.rawValue
                        ])
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

        mainVC.present(toPresent, animated: true)
    }
 }

 class NotificationUserInfo {
    private let userInfo: [AnyHashable : Any]
    init(userInfo: [AnyHashable : Any]) {
        self.userInfo = userInfo
    }
    var aps: [AnyHashable: Any]? {
        return userInfo["aps"] as? [AnyHashable: Any]
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
 }

 /// Enumeration for string representation of possible view controllers to present from an APNS notification
 enum LinkDestination: String
 {
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
