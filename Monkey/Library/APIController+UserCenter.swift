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
	static let kNewAccountCodeVerify = "kNewAccountCodeVerify"
	
	static let userDef = UserDefaults.standard
	
	class func signCodeSended(isNewUser: Bool) {
		userDef.set(true, forKey: kCodeVerifyJustNow)
		userDef.set(isNewUser, forKey: kNewAccountCodeVerify)
		AnalyticsCenter.loginAccount()
		trackSignUpFinish(isNewUser: isNewUser)
	}
	
	class func trackCodeVerifyIfNeed(isProfileComplete: Bool) {
		if userDef.bool(forKey: kCodeVerifyJustNow) == false {
			return
		}
		userDef.set(false, forKey: kCodeVerifyJustNow)
		
		let isAccountNew = userDef.bool(forKey: kNewAccountCodeVerify)
		AnalyticsCenter.log(withEvent: .codeVerify, andParameter: [
			"is_account_new" : isAccountNew,
			"is_profile_complete" : isProfileComplete,
			])
	}
	
	class func trackSignUpFinish(isNewUser: Bool) {
		var signUpParameter = [
			"is_account_new": "\(isNewUser)",
		]
		if isNewUser {
			Achievements.shared.registerTime = NSDate().timeIntervalSince1970
			
			// 如果是新用户，保存分配到的实验
			let text_chat_test_plan = RemoteConfigManager.shared.text_chat_test
			// 打点参数
			signUpParameter["experiment"] = text_chat_test_plan.rawValue
			Achievements.shared.textModeTestPlan = text_chat_test_plan
			// 如果是实验 B，默认打开 text mode
			if text_chat_test_plan == .text_chat_test_B {
				Achievements.shared.selectMatchMode = .TextMode
			}
		}else {
			Achievements.shared.registerTime = 0
		}
		AnalyticsCenter.log(withEvent: .signUpFinish, andParameter: signUpParameter)
	}
}
