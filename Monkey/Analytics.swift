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
    //  ----------------------------  login  ------------------------------
    case codeVerify = "CODE_VERIFY"
    case signUpFinish = "SIGNUP_FINISH"
	
	//  ----------------------------  launch  ------------------------------
	case notifyClick = "NOTIFY_CLICK"
    
    //  ----------------------------  Match  ------------------------------
    case matchFirstRequest = "MATCH_1ST_REQUEST"
    case matchFirstRecieved = "MATCH_1ST_RECEIVED"
    case matchFirstSuccess = "MATCH_1ST_SUCCESS" /// First match success
    case matchFirstAddTime = "MATCH_1ST_ADDTIME"
    case matchFirstAddFriend = "MATCH_1ST_ADDFRIEND"
	
	case matchRequestTotal = "MATCH_REQUEST_TOTAL"
	case matchRequest = "MATCH_REQUEST"
	case matchReceivedTotal = "MATCH_RECEIVED_TOTAL"
    case matchReceived = "MATCH_RECEIVED"
    case matchConnect = "MATCH_CONNECT"
    case matchConnectTimeOut = "MATCH_CONNECT_TIME_OUT"
    case matchSuccess = "MATCH_SUCCESS"
	case matchInfo = "MATCH_INFO"
	
	case opentokError = "OPENTOK_ERROR"
	case opentokConnected = "OPENTOK_CONNECTED"
}

public enum AdjustEvent: String {
    case none = ""
}

/**
公共方法，提供给外部使用
*/
class AnaliticsCenter {
	
	class func logLaunchApp() {
		self.prepereAmplitude()
        self.prepareAdjust()
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
    
    fileprivate class func prepareAdjust() {
        let envir = (Environment.environment == .sandbox) ? ADJEnvironmentSandbox : ADJEnvironmentProduction
        let adjConf = ADJConfig.init(appToken: Environment.adjustToken, environment: envir)
        adjConf?.logLevel = ADJLogLevelError
        Adjust.appDidLaunch(adjConf)
        
        let isAuth = (APIController.authorization != nil)
        let isLogin = (APIController.shared.currentUser?.user_id != nil)
        if (isAuth && isLogin) {
            //
        }
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
			AnaliticsCenter.update(userProperty: userInfo)
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
extension AnaliticsCenter {
	fileprivate static let allEvents: Set<AnalyticEvent> = [
		AnalyticEvent.codeVerify,
		AnalyticEvent.signUpFinish,
		
		AnalyticEvent.notifyClick,
		
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
		
		AnalyticEvent.opentokError,
		AnalyticEvent.opentokConnected,
	]
	
	fileprivate static let oneTimeEvents: Set<AnalyticEvent> = [
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
	fileprivate static let exceptAmplitudeEvents: Set<AnalyticEvent> = [
		AnalyticEvent.notifyClick,
		
		AnalyticEvent.matchRequestTotal,
		AnalyticEvent.matchRequest,
		AnalyticEvent.matchReceivedTotal,
		AnalyticEvent.matchReceived,
		AnalyticEvent.matchConnect,
		AnalyticEvent.matchConnectTimeOut,
		AnalyticEvent.matchSuccess,
		AnalyticEvent.matchInfo,
	]
	
	fileprivate class func log(forAmpitude event: AnalyticEvent, andParameter parameter: [String: Any]?) {
		if event == .opentokConnected || event == .opentokError {
			if let currentUser = APIController.shared.currentUser, let user_id = currentUser.user_id, user_id.hasSuffix("0") == false, user_id.hasSuffix("5") == false {
				return
			}
		}
		
		if self.exceptAmplitudeEvents.contains(event) == false || Environment.environment == .sandbox {
			if (parameter != nil) {
				Amplitude.shared.logEvent(event.rawValue, withEventProperties: parameter!)
			}else {
				Amplitude.shared.logEvent(event.rawValue)
			}
		}
	}
    
    fileprivate class func log(forAdjust event: AdjustEvent, andParameter param: [String: Any]?) {
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


