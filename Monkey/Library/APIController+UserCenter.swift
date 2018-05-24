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
	static let kSignAsLogin = "kSignAsLogin"
	static let kNewAccountSignUpFinish = "kNewAccountSignUpFinish"
	
    private static let userDef = UserDefaults.standard
    
    private class func signAsNewUser() {
        userDef.set(true, forKey: kNewAccountCodeVerify)
        userDef.set(true, forKey: kNewAccountSignUpFinish)
    }
    
    class func signCodeSended(isNewUser: Bool) {
        userDef.set(true, forKey: kCodeVerifyJustNow)
        
        if isNewUser {
            self.signAsNewUser()
        }
    }
    
    class func trackCodeVerifyIfNeed(result: Bool, isProfileComp: Bool) {
        if !userDef.bool(forKey: kCodeVerifyJustNow) {
            return
        }
        userDef.set(false, forKey: kCodeVerifyJustNow)
        
        let isAccountNew = userDef.bool(forKey: kNewAccountCodeVerify)
        userDef.set(false, forKey: kNewAccountCodeVerify)
        
        //  code verify success ,sign as login
		userDef.set(result, forKey: kSignAsLogin)
        
        AnaliticsCenter.log(withEvent: .codeVerify, andParameter: [
            "is_account_new" : isAccountNew ? "true" : "false",
            "is_profile_complete" : isProfileComp ? "true" : "false"
            ])
    }
    
    class func trackSignUpFinish() {
        if !userDef.bool(forKey: kSignAsLogin) {
            return;
        }
        
        userDef.set(false, forKey: kSignAsLogin)
        
        let isAccountNew = userDef.bool(forKey: kNewAccountSignUpFinish)
        
        AnaliticsCenter.log(withEvent: .signUpFinish, andParameter: [
            "is_account_new": "\(isAccountNew)"
            ])
		
		if isAccountNew {
			Achievements.shared.registerTime = NSDate().timeIntervalSince1970
		}else {
			Achievements.shared.registerTime = 0
		}
        
        userDef.set(false, forKey: kNewAccountSignUpFinish)
    }
}
