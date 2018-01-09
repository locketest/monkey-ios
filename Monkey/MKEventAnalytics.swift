//
//  MKEventAnalytics.swift
//  Monkey
//
//  Created by 王广威 on 2018/1/2.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import Amplitude_iOS
import FBSDKCoreKit
import Crashlytics

/// Analytics Event Name
public enum AnalyticEvent: String {
	case openedAppViaPushNotification = "Opened App Via Push Notification" /// 点击notification bar 打开 app :
	case openedURLFromPushNotification     = "Opened URL From Push Notification" /// 通过点击 notification 打开了 URL
	case signUpLogin    = "SIGNUP_LOGIN" /// 登录或注册成功后打点
	case changedPhoneVerificationCountry    = "Changed Phone Verification Country" /// 输入手机号页面改变国家
	case requestedPhoneVerificationCode     = "Requested Phone Verification Code" /// 请求验证码
	case errorRequestingPhoneVerificationCode   = "Error Requesting Phone Verification Code" /// 请求验证码失败
	case validatedPhoneVerificationCode = "Validated Phone Verification Code" /// 验证验证码成功
	case errorResendingPhoneVerificationCode     = "Error Resending Phone Verification Code" /// 重新发送验证码失败
	case errorValidatingPhoneVerificationCode = "Error Validating Phone Verification Code" /// 验证码验证错误
	case resentPhoneVerificationCode    = "Resent Phone Verification Code" /// 重新发送验证码成功
	case permissionsGranted    = "Permissions Granted" /// 全部权限申请通过(不包含通知)
	case openedPhoneLoginPage     = "Opened Phone Login Page" /// 未登录用户点击 Get start 按钮展示手机登录页面
	case editProfileCompleted   = "Edit Profile Completed" /// 用户在完善资料页点击了next button
	case editProfileNameCompleted = "Edit Profile Name Completed" /// 用户已经看见了所有需要填写的项目（在小手机上可能显示不全，会在点击next button 的时候先滚动到生日选项，第二次才打这个点，大手机(6及以上)，则会在第一次点击next button 就打这个点，不会滚动到生日选项）
	case unfriendedUser     = "Unfriended User" /// 用户unfriend好友的时候（不论接口请求成功失败都会打）
	case blockedUser    = "Blocked User" /// 用block好友的时候（不论接口请求成功失败都会打）
	case ratedCall    = "Rated Call" /// 点击 match rate 选项到时候打点
	case openedInstagramAccount     = "Opened Instagram Account" /// 在好友列表长按好友cell弹出ins vc / friend聊天中中长按头像显示对方ins vc
	case sentMessage   = "Sent Message" /// 给好友发送文字消息
	case calledFriend = "Called Friend" /// Call 好友
	case readMessage     = "Read Message" /// 已读消息
	case friendAcceptedCall    = "Friend Accepted Call" /// 好友接收 call 邀请
	case acceptedFriendCall = "Accepted Friend’s Call" /// 接收好友的 call 邀请
	case joinedChannel    = "Joined Channel" /// 用户选择了一个tag
	case linkedInstagram     = "Linked Instagram" /// link ins
	case unlinkedInstagram   = "Unlinked Instagram" /// unlink ins
	case invitedFriendsManually    = "Invited Friends Manually" /// setting 页面点击Invited Friends
	case loggedInWithFacebook    = "Logged In With Facebook" /// link facebook
	case invitedFacebookFriends    = "Invited Facebook Friends" /// link facebook 成功后邀请好友
	case startedtruthordaregame    = "Started truth or dare game" /// 开始真心话大冒险游戏
	case receivedtruthordaregamerequest    = "Received truth or dare game request" /// 收到真心话大冒险游戏邀请
	case gotdare    = "Got dare" /// 选择大冒险
	case sentdare    = "Sent dare" /// 创建并发送大冒险选项
	case invitedFriendsSearchingScreen    = "Invited Friends Searching Screen" /// 在主页面点击了Bonus Bananas 按钮
	case acceptedCall    = "Accepted Call" /// Match accept
	case skippedCall    = "Skipped Call" /// Match skip
	case matchFirstRequest    = "MATCH_1ST_REQUEST" /// First match request
	case minuteAddedToCall    = "Minute Added To Call" /// add time 成功
	case requestedMinuteDuringCall    = "Requested Minute During Call" /// add time 请求
	case matchFirstSuccess    = "MATCH_1ST_SUCCESS" /// First match success
	case requestedSnapchatDuringCall    = "Requested Snapchat During Call" /// match 中请求添加好友
	case snapchatMatchedDuringCall    = "Snapchat Matched During Call" /// match到好友
}


/**
公共方法，提供给外部使用
*/
class AnaliticsCenter {
	
	class func logLaunchApp() {
		self.prepereAmplitude()
	}
	
	fileprivate class func prepereAmplitude() {
		let isAuth = (APIController.authorization != nil)
		let isLogin = (APIController.shared.currentUser?.user_id != nil)
		Amplitude.shared.trackingSessionEvents = true
		
		if (isAuth && isLogin) {
			Amplitude.shared.initializeApiKey(Environment.amplitudeKey, userId: APIController.shared.currentUser?.user_id)
		}else {
			Amplitude.shared.initializeApiKey(Environment.amplitudeKey)
		}
	}
	
	fileprivate class func setUserID() {
		let isAuth = (APIController.authorization != nil)
		let currentUser = APIController.shared.currentUser
		let userID = currentUser?.user_id
		if (isAuth && userID != nil) {
			runAsynchronouslyOnEventProcessingQueue {
				Amplitude.shared.setUserId(userID)
				Crashlytics.sharedInstance().setUserIdentifier(userID)
			}
		}
	}
	
	class func update(userProperty userProperties: [String: Any]) {
		runAsynchronouslyOnEventProcessingQueue {
			update(facebookUserProperty: userProperties)
			update(amplitudeUserProperty: userProperties)
			update(crashlyticsUserProperty: userProperties)
		}
	}
	
	class func loginAccount() {
		setUserID()
	}
	
	class func logoutAccount() {
		clearLoggedEvents()
	}
	
	class func log(event: AnalyticEvent) {
		log(withEvent: event, andParameter: nil)
	}
	
	class func log(withEvent event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		runAsynchronouslyOnEventProcessingQueue {
			// 如果是只打一次的点，且已经打过了
			if (self.oneTimeEvents.contains(event) && self.loggedEventsList.contains(event.rawValue)) {
				return
			}
			
			// 标记为打过的点
			self.markLogged(event: event);
			
			self.log(forAmpitude: event, andParameter: parameter)
			self.log(forFacebook: event, andParameter: parameter)
			self.log(forAnswers: event, andParameter: parameter)
		}
	}
}

/*
私有属性和方法
*/
extension AnaliticsCenter {
	fileprivate static let allEvents: Set<AnalyticEvent> = [
		AnalyticEvent.acceptedCall,
		AnalyticEvent.blockedUser,
		AnalyticEvent.calledFriend,
		AnalyticEvent.changedPhoneVerificationCountry,
		AnalyticEvent.editProfileCompleted,
		AnalyticEvent.editProfileNameCompleted,
		AnalyticEvent.errorRequestingPhoneVerificationCode,
		AnalyticEvent.errorRequestingPhoneVerificationCode,
		AnalyticEvent.friendAcceptedCall,
		AnalyticEvent.gotdare,
		AnalyticEvent.invitedFacebookFriends,
		AnalyticEvent.invitedFriendsManually,
		AnalyticEvent.invitedFriendsSearchingScreen,
		AnalyticEvent.joinedChannel,
		AnalyticEvent.linkedInstagram,
		AnalyticEvent.loggedInWithFacebook,
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstSuccess,
		AnalyticEvent.openedPhoneLoginPage,
		AnalyticEvent.openedInstagramAccount,
		AnalyticEvent.openedAppViaPushNotification,
		AnalyticEvent.openedURLFromPushNotification,
		AnalyticEvent.permissionsGranted,
		AnalyticEvent.ratedCall,
		AnalyticEvent.readMessage,
		AnalyticEvent.receivedtruthordaregamerequest,
		AnalyticEvent.requestedMinuteDuringCall,
		AnalyticEvent.requestedSnapchatDuringCall,
		AnalyticEvent.requestedPhoneVerificationCode,
		AnalyticEvent.resentPhoneVerificationCode,
		AnalyticEvent.sentdare,
		AnalyticEvent.sentMessage,
		AnalyticEvent.signUpLogin,
		AnalyticEvent.skippedCall,
		AnalyticEvent.snapchatMatchedDuringCall,
		AnalyticEvent.startedtruthordaregame,
		AnalyticEvent.unlinkedInstagram,
		AnalyticEvent.unfriendedUser,
		AnalyticEvent.validatedPhoneVerificationCode,
	]
	
	fileprivate static let newInstallEvents: Set<AnalyticEvent> = [
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstSuccess,
	]
	
	fileprivate static let oneTimeEvents: Set<AnalyticEvent> = [
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstSuccess,
	]
	
	fileprivate class func cachedEventsList() -> Set<String>? {
		if let cachedEventsList = UserDefaults.standard.object(forKey: "MKLoggedEventsTypeList") as? Array<String> {
			return Set(cachedEventsList)
		}else {
			return nil
		}
	}
	fileprivate static var loggedEventsList: Set<String> = AnaliticsCenter.cachedEventsList() ?? Set<String>() {
		didSet {
			UserDefaults.standard.set(Array(self.loggedEventsList), forKey: "MKLoggedEventsTypeList")
			UserDefaults.standard.synchronize()
		}
	}
	
	fileprivate class func markLogged(event: AnalyticEvent) {
		AnaliticsCenter.loggedEventsList.insert(event.rawValue)
	}
	
	fileprivate class func clearLoggedEvents() {
		AnaliticsCenter.loggedEventsList.removeAll()
	}
	
	fileprivate static let eventProcessingContext: DispatchQueue = DispatchQueue.init(label: "mk_queue_event_handle")
	
	fileprivate class func runAsynchronouslyOnEventProcessingQueue(execute work: @escaping @convention(block) () -> Swift.Void) {
		eventProcessingContext.async(execute: work)
	}
}

/*
Amplitude 操作
*/
extension AnaliticsCenter {
	fileprivate static let amplitudeEvents: Set<AnalyticEvent> = [
		AnalyticEvent.signUpLogin,
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstSuccess,
	]
	
	fileprivate class func log(forAmpitude event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		if self.amplitudeEvents.contains(event) {
			if (parameter != nil) {
				Amplitude.shared.logEvent(event.rawValue)
			}else {
				Amplitude.shared.logEvent(event.rawValue, withEventProperties: parameter!)
			}
		}
	}
	
	fileprivate class func set(amplitudeUserProperty userProperties: [String: Any], increse: Bool, update: Bool) {
		let identify = AMPIdentify.init()
		for (propertyKey, propertyValue) in userProperties {
			if (update) {
				identify.set(propertyKey, value: propertyValue as! NSObject)
			}else if (increse) {
				identify.add(propertyKey, value: propertyValue as! NSObject)
			}else {
				identify.setOnce(propertyKey, value: propertyValue as! NSObject)
			}
		}
		Amplitude.shared.identify(identify)
	}
	
	fileprivate class func update(amplitudeUserProperty userProperties: [String: Any]) {
		set(amplitudeUserProperty: userProperties, increse: false, update: true)
	}
	
	class func add(amplitudeUserProperty userProperties: [String: Any]) {
		set(amplitudeUserProperty: userProperties, increse: true, update: false)
	}
	
	class func set(amplitudeUserProperty userProperties: [String: Any]) {
		set(amplitudeUserProperty: userProperties, increse: false, update: false)
	}
}


/*
Answers 操作
*/
extension AnaliticsCenter {
	
	fileprivate static let answersEvents: Set<AnalyticEvent> = [
		AnalyticEvent.acceptedCall,
		AnalyticEvent.skippedCall,
	]
	
	fileprivate class func log(forAnswers event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		if self.answersEvents.contains(event) {
			Answers.logCustomEvent(withName: event.rawValue, customAttributes: parameter)
		}
	}
	
	fileprivate class func update(crashlyticsUserProperty userProperties: [String: Any]) {
		for (propertyKey, propertyValue) in userProperties {
			Crashlytics.sharedInstance().setObjectValue(propertyValue, forKey: propertyKey)
		}
	}
}

/*
Facebook 操作
*/
extension AnaliticsCenter {
	
	fileprivate static let facebookEvents: Set<AnalyticEvent> = AnaliticsCenter.allEvents
	
	fileprivate class func log(forFacebook event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		if self.facebookEvents.contains(event) {
			if (parameter != nil) {
				FBSDKAppEvents.logEvent(event.rawValue, parameters: parameter!)
			}else {
				FBSDKAppEvents.logEvent(event.rawValue)
			}
		}
	}
	
	fileprivate class func update(facebookUserProperty userProperties: [String: Any]) {
		FBSDKAppEvents.updateUserProperties(userProperties, handler: nil)
	}
}


