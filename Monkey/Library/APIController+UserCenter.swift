//
//  APIController+UserCenter.swift
//  Monkey
//
//  Created by YY on 2018/1/24.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

//  user action track
extension APIController {
	
	static let kCodeVerifyJustNow = "kCodeVerifyJustNow"
	static let kSignUpFinishJustNow = "kSignUpFinishJustNow"
	static let kNewAccountCodeVerify = "kNewAccountCodeVerify"
	
	static let userDef = UserDefaults.standard
	
	
	class func signCodeSended(isNewUser: Bool) {
		userDef.set(true, forKey: kCodeVerifyJustNow)
		userDef.set(true, forKey: kSignUpFinishJustNow)
		userDef.set(isNewUser, forKey: kNewAccountCodeVerify)
		userDef.synchronize()
		AnalyticsCenter.loginAccount()
	}
	
	class func trackCodeVerifyIfNeed(isProfileComplete: Bool) {
		if userDef.bool(forKey: kCodeVerifyJustNow) == false {
			return
		}
		userDef.set(false, forKey: kCodeVerifyJustNow)
		
		let isAccountNew = userDef.bool(forKey: kNewAccountCodeVerify)
		AnalyticsCenter.log(withEvent: .codeVerify, andParameter: [
			"is_account_new" : "\(isAccountNew)",
			"is_profile_complete" : "\(isProfileComplete)",
			])
	}
	
	class func trackSignUpFinish() {
		if userDef.bool(forKey: kSignUpFinishJustNow) == false {
			return
		}
		userDef.set(false, forKey: kSignUpFinishJustNow)
		
		let isNewUser = userDef.bool(forKey: kNewAccountCodeVerify)
		let signUpParameter = [
			"is_account_new": "\(isNewUser)",
		]
		if isNewUser {
			Achievements.shared.registerTime = NSDate().timeIntervalSince1970
		}else {
			Achievements.shared.registerTime = 0
		}
		AnalyticsCenter.log(withEvent: .signUpFinish, andParameter: signUpParameter)
	}
}
