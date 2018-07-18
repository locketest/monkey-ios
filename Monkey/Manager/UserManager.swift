//
//  UserManager.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/28.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

@objc protocol UserObserver: class, NSObjectProtocol {
	@objc optional func currentUserDidLogin()
	@objc optional func currentUserDidLogout()
	
	@objc optional func currentUserInfomationChanged()
}

class UserManager: NSObject {
	
	static let shared = UserManager()
	override private init() {}
	
	static var authorization: String? {
		return shared.currentAuthorization?.auth_token
	}
	
	static var UserID: String? {
		return shared.currentAuthorization?.user_id
	}
	
	var currentAuthorization: Authorization? {
		let threadSafeRealm = try? Realm()
		return threadSafeRealm?.object(ofType: Authorization.self, forPrimaryKey: Environment.environment.rawValue)
	}
	
	/// Currently signed in user
	var currentUser: RealmUser? {
		guard let userId = UserManager.UserID else {
			return nil
		}
		let threadSafeRealm = try? Realm()
		return threadSafeRealm?.object(ofType: RealmUser.self, forPrimaryKey: userId)
	}
	
	var currentExperiment: RealmExperiment? {
		let threadSafeRealm = try? Realm()
		// Experiement IDs directly corolate to app versions
		return threadSafeRealm?.object(ofType: RealmExperiment.self, forPrimaryKey: Environment.appVersion)
	}
	
	var currentMatchInfo: RealmMatchInfo? {
		let threadSafeRealm = try? Realm()
		// Experiement IDs directly corolate to app versions
		return threadSafeRealm?.object(ofType: RealmMatchInfo.self, forPrimaryKey: RealmMatchInfo.type)
	}
	
	/// cached user
	static func cachedUser(with user_id: Int) -> RealmUser? {
		let threadSafeRealm = try? Realm()
		return threadSafeRealm?.object(ofType: RealmUser.self, forPrimaryKey: "\(user_id)")
	}
	
	// 消息回调处理
	private let safe_queue = DispatchQueue(label: "com.monkey.cool.SafeUserObserverQueue", attributes: .concurrent)
	private var observers: WeakSet<UserObserver> = WeakSet<UserObserver>()
	func addMessageObserver(observer: UserObserver) {
		safe_queue.async {
			self.observers.add(observer)
		}
	}
	
	func delMessageObserver(observer: UserObserver) {
		safe_queue.async {
			self.observers.remove(observer)
		}
	}
	
	private var InitialLogin: Bool? = nil
	// current login action
	var loginMethod: LoginMethod? = nil
	func isUserLogin() -> Bool {
		return InitialLogin ?? false
	}
	
	func login(completion: @escaping (_ error: APIError?) -> Void) {
		RealmDataController.shared.setupRealm { (setupError: APIError?) in
			// 如果初始化出错
			if let apiError = setupError {
				completion(apiError)
				return
			}
			
			// 如果是已登录状态
			guard self.InitialLogin != true else {
				completion(nil)
				return
			}
			
			// 设置用户登录状态
			if let authorization = self.currentAuthorization {
				// 自动登录
				self.loginMethod = self.InitialLogin == nil ? .autoLogin : LoginMethod(rawValue: authorization.action)
				self.InitialLogin = true
				self.saveToUserDefault(auth: authorization)
			}else {
				// 未登录
				self.loginMethod = nil
				self.InitialLogin = false
			}
			
			// callback first
			completion(nil)
			// do something after callback if user login success
			if self.isUserLogin() {
				self.notifyUserLogin()
			}
		}
	}
	
	func saveToUserDefault(auth: Authorization) {
		APIController.authorization = auth.auth_token
		APIController.user_id = auth.user_id
	}
	
	func clearData(completion: @escaping (_ error: APIError?) -> Void) {
		self.clearUserDefaultsData()
		RealmDataController.shared.deleteAllData(completion: completion)
	}
	
	func logout(completion: @escaping (_ error: APIError?) -> Void) {
		self.clearData { (error) in
			// 如果已经是登出状态
			if self.InitialLogin == false {
				completion(nil)
				return
			}
			
			// 如果数据删除失败
			if let apiError = error {
				completion(apiError)
				return
			}
			
			self.loginMethod = nil
			self.InitialLogin = false
			
			// do something first
			self.notifyUserLogout()
			
			// callback after notify
			completion(nil)
		}
	}
	
	func clearUserDefaultsData() {
		// remove old data
		Achievements.shared.apns_token = nil
		APIController.authorization = nil
		APIController.user_id = nil
	}
	
	// notify observer
	private func notifyObserver() {
		if self.isUserLogin() {
			self.notifyUserLogin()
		}else {
			self.notifyUserLogout()
		}
	}
	
	private func notifyUserLogin() {
		// some config
		Configs.signAsLogin()
		
		// enable socket
		Socket.shared.isEnabled = true
		
		// refresh friends
		FriendsViewModel.sharedFreindsViewModel.setup()
		
		// add observer
		MessageCenter.shared.addMessageObserver(observer: self)
		
		// dispatch
		self.dispatch(selector: #selector(UserObserver.currentUserDidLogin))
	}
	
	private func notifyUserLogout() {
		// clear user_id for some analytics
		AnalyticsCenter.logoutAccount()
		
		// disable socket
		Socket.shared.isEnabled = false
		
		// clear friends
		FriendsViewModel.sharedFreindsViewModel.reset()
		
		// del observer
		MessageCenter.shared.delMessageObserver(observer: self)
		
		// dispatch
		self.dispatch(selector: #selector(UserObserver.currentUserDidLogout))
	}
	
	func trackCodeVerify() {
		guard let loginMethod = loginMethod, loginMethod != .autoLogin else {
			return
		}
		// 如果是新登录或注册用户
		let isCompleteProfile = currentUser?.isCompleteProfile() ?? false
		let isNewUser = loginMethod == .register
		AnalyticsCenter.log(withEvent: .codeVerify, andParameter: [
			"is_account_new": isNewUser.toString,
			"is_profile_complete": isCompleteProfile.toString,
			])
	}
	
	func trackSignUpFinish() {
		guard let loginMethod = loginMethod, loginMethod != .autoLogin else {
			return
		}
		
		// 如果是新登录或注册用户
		let isNewUser = loginMethod == .register
		if isNewUser {
			Achievements.shared.registerTime = NSDate().timeIntervalSince1970
		}else {
			Achievements.shared.registerTime = 0
		}
		AnalyticsCenter.log(withEvent: .signUpFinish, andParameter: [
			"is_account_new": isNewUser.toString,
			])
	}
	
	fileprivate func dispatch(selector: Selector) {
		// always in main queue
		let observers = self.observers
		observers.forEach({ (observer) in
			if observer.responds(to: selector) {
				observer.perform(selector)
			}
		})
	}
}

extension UserManager: MessageObserver {
	func refreshUserData() {
		guard let currentUser = self.currentUser else { return }
		currentUser.refreshCache()
		self.dispatch(selector: #selector(UserObserver.currentUserInfomationChanged))
	}
	
	func didReceiveInfoChanged() {
		guard let currentUser = self.currentUser else { return }
		currentUser.reload { (error) in
			if error != nil {
				return
			}
			currentUser.refreshCache()
			self.dispatch(selector: #selector(UserObserver.currentUserInfomationChanged))
		}
	}
}

