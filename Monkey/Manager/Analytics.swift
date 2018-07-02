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
import Adjust

/// Analytics Event Name
public enum AnalyticEvent: String {
	//  ----------------------------  welcome  ------------------------------
	case landingPageShow = "landingpage_show"
	case landingPageClick = "landingpage_loginbtn_click"
	
    //  ----------------------------  login  ------------------------------
    case codeVerify = "CODE_VERIFY"
	case loginCompletion = "Login_Completion"
    case signUpFinish = "SIGNUP_FINISH"
	case signOut = "SIGN_OUT"
	
	//  ----------------------------  launch  ------------------------------
	case notifyClick = "NOTIFY_CLICK"
	
	//  ----------------------------  user interaction  ------------------------------
	case videoFilterClick = "stage2_video_filter_click"
	case videoFilterSelect = "stage2_video_filter_select"
	case textModeClick = "text_mode_btn_click"
	case eventModeClick = "event_mode_btn_click"
	case treeClick = "tree_click"
	case friendListClick = "friend_list_click"
	case friendChatClick = "friend_convopage_click"
	case insgramClick = "friend_ins_profile"
	case monkeyKingEnter = "friend_monkeyking_click"
	case monkeyKingClick = "monkeybtn_click"
	case snapchatClick = "monkey_snapchat_btn_click"
	case settingClick = "setting_click"
	case settingEditProfileClick = "editprofile_click"
	case settingAvatarClick = "setting_avatar_click"
	case settingTalkToClick = "setting_talkto_click"
	case settingSignOutClick = "setting_signout_click"
	case settingLinkInsClick = "setting_linkIns_click"
	case settingLinkInsComplete = "setting_linkIns_complete"
	case settingInviteClick = "setting_invitefriends_click"
	
	case ratePopClick = "rate_pop_show_click"
	case clickMatchSelect = "select_btn"
    
    //  ----------------------------  Match  ------------------------------
	case matchingSession = "matching_session"
    case matchFirstRequest = "MATCH_1ST_REQUEST"
    case matchFirstRecieved = "MATCH_1ST_RECEIVED"
    case matchFirstSuccess = "MATCH_1ST_SUCCESS" /// First match success
    case matchFirstAddTime = "MATCH_1ST_ADDTIME"
    case matchFirstAddFriend = "MATCH_1ST_ADDFRIEND"
	
	case matchCancel = "match_cancel"
	case matchRequestTotal = "MATCH_REQUEST_TOTAL"
	case matchRequest = "MATCH_REQUEST"
	case matchReceivedTotal = "match_receive_total"
    case matchReceived = "MATCH_RECEIVED"
	case matchSendSkip = "skip_request_sent"
	case matchWaitTimeout = "auto_skip_timeout"
	case matchSendAccept = "accept_request_sent"
    case matchConnect = "MATCH_CONNECT"
	case matchConnectingFailed = "connecting_timeout"
    case matchConnectTimeOut = "MATCH_CONNECT_TIME_OUT"
    case matchSuccess = "MATCH_SUCCESS"
	case matchInfo = "MATCH_INFO"
	
	case inviteFriendClick = "INVITE_FRIEND_CLICK"
	case inviteFriendSuccess = "INVITE_FRIEND_SUCCESS"
	
	case bananaPopupEnter = "BANANA_POPUP_ENTER"
	
	case sentMessageConvo = "SENT_MESSAGE_CONVO"
	case snapchatClickConvo = "SNAPCHAT_CLICK_CONVO"
    
    //  ----------------------------  delete account  ------------------------------
    case deleteAccount = "REMOVE_ACCOUNT_REQUEST"
    case resumeAccount = "REMOVE_ACCOUNT_CANCEL"
}

/**
公共方法，提供给外部使用
*/
class AnalyticsCenter {
	
	class func logLaunchApp() {
		self.prepereAmplitude()
        self.prepareAdjust()
	}
	
	fileprivate class func prepereAmplitude() {
		let isAuth = (APIController.authorization != nil)
		let userId = UserDefaults.standard.string(forKey: "user_id")
		Amplitude.shared.trackingSessionEvents = true
		
		if (isAuth && userId != nil) {
			Amplitude.shared.initializeApiKey(Environment.amplitudeKey, userId: userId)
		}else {
			Amplitude.shared.initializeApiKey(Environment.amplitudeKey)
		}
	}
    
    fileprivate class func prepareAdjust() {
        let environment = (Environment.environment == .sandbox) ? ADJEnvironmentSandbox : ADJEnvironmentProduction
        let adjConf = ADJConfig.init(appToken: Environment.adjustToken, environment: environment)
        adjConf?.logLevel = ADJLogLevelError
        Adjust.appDidLaunch(adjConf)
    }
	
	fileprivate class func setUserID() {
		let isAuth = (APIController.authorization != nil)
		
		if isAuth == true, let currentUser = APIController.shared.currentUser, let userID = currentUser.user_id {
			runAsynchronouslyOnEventProcessingQueue {
				FBSDKAppEvents.setUserID(userID)
				Amplitude.shared.setUserId(userID)
				Crashlytics.sharedInstance().setUserIdentifier(userID)
                Adjust.addSessionCallbackParameter("user_id", value: userID)
			}
			var userInfo: [String: Any] = [
				"Monkey_gender": currentUser.gender ?? "male",
				"Monkey_age": currentUser.age.value ?? 0,
				"Monkey_ban": currentUser.is_banned.value ?? false,
				]
			if let create_at = currentUser.created_at?.timeIntervalSince1970 {
				let Monkey_signup_date = Date.init(timeIntervalSince1970: create_at)
				userInfo["Monkey_signup_date"] = Monkey_signup_date.toString(format: DateFormatType.custom("yyyyMMddHHmmss"))
			}
			AnalyticsCenter.update(userProperty: userInfo)
		}
	}
	
	class func update(userProperty userProperties: [String: Any]) {
		runAsynchronouslyOnEventProcessingQueue {
			update(facebookUserProperty: userProperties)
			update(amplitudeUserProperty: userProperties)
		}
	}
	
	class func loginAccount() {
		setUserID()
	}
	
	class func logoutAccount() {
		// clear user id
		clearLoggedEvents()
	}
	
	class func log(event: AnalyticEvent) {
		log(withEvent: event, andParameter: nil)
	}
	
	class func log(withEvent event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		runAsynchronouslyOnEventProcessingQueue {
			// 如果是只打一次的点，且已经打过了，不再重复打
			if (self.oneTimeEvents.contains(event) && self.loggedEventsList.contains(event.rawValue)) {
				return
			}
			
			if (self.firstDayEvents.contains(event) && Date.init(timeIntervalSince1970: Achievements.shared.registerTime).compare(.isToday) == false) {
				return
			}
			
			// 标记为打过的点
			self.markLogged(event: event);
			
			self.log(forAmpitude: event, andParameter: parameter)
			self.log(forFacebook: event, andParameter: parameter)
		}
	}
}

/*
私有属性和方法
*/
extension AnalyticsCenter {
	fileprivate static let allEvents: Set<AnalyticEvent> = [
		AnalyticEvent.landingPageShow,
		AnalyticEvent.landingPageClick,
		
		AnalyticEvent.codeVerify,
		AnalyticEvent.loginCompletion,
		AnalyticEvent.signUpFinish,
		AnalyticEvent.signOut,
		
		AnalyticEvent.notifyClick,
		
		AnalyticEvent.videoFilterClick,
		AnalyticEvent.videoFilterSelect,
		AnalyticEvent.textModeClick,
		AnalyticEvent.eventModeClick,
		AnalyticEvent.treeClick,
		AnalyticEvent.friendListClick,
		AnalyticEvent.friendChatClick,
		AnalyticEvent.insgramClick,
		AnalyticEvent.monkeyKingEnter,
		AnalyticEvent.monkeyKingClick,
		AnalyticEvent.snapchatClick,
		AnalyticEvent.settingClick,
		AnalyticEvent.settingEditProfileClick,
		AnalyticEvent.settingAvatarClick,
		AnalyticEvent.settingTalkToClick,
		AnalyticEvent.settingSignOutClick,
		AnalyticEvent.settingLinkInsClick,
		AnalyticEvent.settingLinkInsComplete,
		AnalyticEvent.settingInviteClick,
		
		AnalyticEvent.ratePopClick,
		AnalyticEvent.clickMatchSelect,
		
		AnalyticEvent.matchingSession,
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstRecieved,
		AnalyticEvent.matchFirstSuccess,
		AnalyticEvent.matchFirstAddTime,
		AnalyticEvent.matchFirstAddFriend,
		
		AnalyticEvent.matchRequestTotal,
		AnalyticEvent.matchRequest,
		AnalyticEvent.matchReceivedTotal,
		AnalyticEvent.matchReceived,
		AnalyticEvent.matchConnect,
		AnalyticEvent.matchConnectTimeOut,
		AnalyticEvent.matchSuccess,
		AnalyticEvent.matchInfo,
		
		AnalyticEvent.inviteFriendClick,
		AnalyticEvent.inviteFriendSuccess,
		
		AnalyticEvent.bananaPopupEnter,
		
		AnalyticEvent.sentMessageConvo,
		AnalyticEvent.snapchatClickConvo,
		
		AnalyticEvent.deleteAccount,
		AnalyticEvent.resumeAccount,
	]
	
	fileprivate static let oneTimeEvents: Set<AnalyticEvent> = [
		AnalyticEvent.landingPageShow,
		
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstRecieved,
		AnalyticEvent.matchFirstSuccess,
		AnalyticEvent.matchFirstAddTime,
		AnalyticEvent.matchFirstAddFriend,
	]
	
	fileprivate static let firstDayEvents: Set<AnalyticEvent> = [
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstRecieved,
		AnalyticEvent.matchFirstSuccess,
		AnalyticEvent.matchFirstAddTime,
		AnalyticEvent.matchFirstAddFriend,
	]
	
	fileprivate class func cachedEventsList() -> Set<String>? {
		if let cachedEventsList = UserDefaults.standard.object(forKey: "MKLoggedEventsTypeList") as? Array<String> {
			return Set(cachedEventsList)
		}else {
			return nil
		}
	}
	fileprivate static var loggedEventsList: Set<String> = AnalyticsCenter.cachedEventsList() ?? Set<String>() {
		didSet {
			UserDefaults.standard.set(Array(self.loggedEventsList), forKey: "MKLoggedEventsTypeList")
			UserDefaults.standard.synchronize()
		}
	}
	
	fileprivate class func markLogged(event: AnalyticEvent) {
		AnalyticsCenter.loggedEventsList.insert(event.rawValue)
	}
	
	fileprivate class func clearLoggedEvents() {
		AnalyticsCenter.loggedEventsList.removeAll()
	}
	
	fileprivate static let eventProcessingContext: DispatchQueue = DispatchQueue.init(label: "mk_queue_event_handle")
	
	fileprivate class func runAsynchronouslyOnEventProcessingQueue(execute work: @escaping @convention(block) () -> Swift.Void) {
		eventProcessingContext.async(execute: work)
	}
}

/*
Amplitude 操作
*/
extension AnalyticsCenter {
	fileprivate static let amplitudeEvents: Set<AnalyticEvent> = [
		AnalyticEvent.landingPageShow,
		AnalyticEvent.landingPageClick,
		
		AnalyticEvent.codeVerify,
		AnalyticEvent.loginCompletion,
		AnalyticEvent.signUpFinish,
		
		AnalyticEvent.notifyClick,
		AnalyticEvent.ratePopClick,
		
		AnalyticEvent.videoFilterClick,
		AnalyticEvent.videoFilterSelect,
		AnalyticEvent.textModeClick,
		AnalyticEvent.eventModeClick,
		
		AnalyticEvent.treeClick,
		AnalyticEvent.friendListClick,
		AnalyticEvent.friendChatClick,
		AnalyticEvent.insgramClick,
		AnalyticEvent.monkeyKingEnter,
		AnalyticEvent.monkeyKingClick,
		AnalyticEvent.snapchatClick,
		AnalyticEvent.settingClick,
		AnalyticEvent.settingEditProfileClick,
		AnalyticEvent.settingAvatarClick,
		AnalyticEvent.settingTalkToClick,
		AnalyticEvent.settingSignOutClick,
		AnalyticEvent.settingLinkInsClick,
		AnalyticEvent.settingLinkInsComplete,
		AnalyticEvent.settingInviteClick,
		
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstRecieved,
		AnalyticEvent.matchFirstSuccess,
		AnalyticEvent.matchFirstAddTime,
		AnalyticEvent.matchFirstAddFriend,
	]
	
	fileprivate class func log(forAmpitude event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		
		if self.amplitudeEvents.contains(event) == true {
			if (parameter != nil) {
				Amplitude.shared.logEvent(event.rawValue, withEventProperties: parameter!)
			}else {
				Amplitude.shared.logEvent(event.rawValue)
			}
		}
	}
    
    fileprivate class func log(forAdjust event: AnalyticEvent, andParameter param: [String: Any]?) {
        let adjEvt = ADJEvent.init(eventToken: event.rawValue)
        param?.forEach({ (key,value) in
            adjEvt?.addCallbackParameter(key, value: "\(value)")
        })
        
        Adjust.trackEvent(adjEvt)
        print("adjust event log \(event) , param : \(param ?? [:])")
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
	
	fileprivate class func update(firstdayAmplitudeUserProperty userProperties: [String: Any]) {
		let create_at = Date.init(timeIntervalSince1970: APIController.shared.currentUser?.created_at?.timeIntervalSince1970 ?? 0)
		guard create_at.compare(.isToday) == true else {
			return
		}
		
		var firstdayProperty = [String: Any]()
		for (property, value) in userProperties {
			firstdayProperty["day1_\(property)"] = value
		}
		
		set(amplitudeUserProperty: firstdayProperty, increse: false, update: true)
	}
	
	class func add(firstdayAmplitudeUserProperty userProperties: [String: Any]) {
		let create_at = Date.init(timeIntervalSince1970: APIController.shared.currentUser?.created_at?.timeIntervalSince1970 ?? 0)
		guard create_at.compare(.isToday) == true else {
			return
		}
		
		var firstdayProperty = [String: Any]()
		for (property, value) in userProperties {
			firstdayProperty["day1_\(property)"] = value
		}
		
		set(amplitudeUserProperty: firstdayProperty, increse: true, update: false)
	}
	
	class func set(firstdayAmplitudeUserProperty userProperties: [String: Any]) {
		let create_at = Date.init(timeIntervalSince1970: APIController.shared.currentUser?.created_at?.timeIntervalSince1970 ?? 0)
		guard create_at.compare(.isToday) == true else {
			return
		}
		
		var firstdayProperty = [String: Any]()
		for (property, value) in userProperties {
			firstdayProperty["day1_\(property)"] = value
		}
		
		set(amplitudeUserProperty: firstdayProperty, increse: false, update: false)
	}
}

/*
Facebook 操作
*/
extension AnalyticsCenter {
	
	fileprivate static let facebookEvents: Set<AnalyticEvent> = [
		AnalyticEvent.codeVerify,
		AnalyticEvent.signUpFinish,
		AnalyticEvent.notifyClick,
		AnalyticEvent.signOut,
		
		AnalyticEvent.clickMatchSelect,
		AnalyticEvent.matchingSession,
	
		AnalyticEvent.matchFirstRequest,
		AnalyticEvent.matchFirstRecieved,
		AnalyticEvent.matchFirstSuccess,
		AnalyticEvent.matchFirstAddTime,
		AnalyticEvent.matchFirstAddFriend,
		
		AnalyticEvent.matchRequest,
		AnalyticEvent.matchCancel,
		AnalyticEvent.matchReceived,
		AnalyticEvent.matchReceivedTotal,
		AnalyticEvent.matchSendSkip,
		AnalyticEvent.matchSendAccept,
		AnalyticEvent.matchWaitTimeout,
		AnalyticEvent.matchConnect,
		AnalyticEvent.matchConnectingFailed,
		AnalyticEvent.matchConnectTimeOut,
		AnalyticEvent.matchSuccess,
		AnalyticEvent.matchInfo,
		
		AnalyticEvent.inviteFriendClick,
		AnalyticEvent.inviteFriendSuccess,
		
		AnalyticEvent.bananaPopupEnter,
		
		AnalyticEvent.sentMessageConvo,
		AnalyticEvent.snapchatClickConvo,
		
		AnalyticEvent.deleteAccount,
		AnalyticEvent.resumeAccount,
	]
	
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


