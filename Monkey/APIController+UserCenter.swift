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
    private static let userDef = UserDefaults.standard
    
    private class func signAsNewUser(){
        userDef.set(true, forKey: kNewAccountCodeVerify)
        userDef.set(true, forKey: kNewAccountSignUpFinish)
        userDef.set(true, forKey: kNewAccountMatch1stAddTime)
        userDef.set(true, forKey: kNewAccountMatch1stRecieve)
        userDef.set(true, forKey: kNewAccountMatch1stAddFriend)
        userDef.set(true, forKey: "MonkeyLogEventFirstMatchRequest")
        userDef.set(true, forKey: "MonkeyLogEventFirstMatchSuccess")
    }
    
    class func signCodeSended(isNewUser:Bool){
        userDef.set(true, forKey: kCodeVerifyJustNow)
        
        if isNewUser {
            self.signAsNewUser()
        }
    }
    
    class func trackCodeVerifyIfNeed(result:Bool,isProfileComp:Bool) {
        if !userDef.bool(forKey: kCodeVerifyJustNow) {
            return
        }
        userDef.set(false, forKey: kCodeVerifyJustNow)
        
        let isAccountNew = userDef.bool(forKey: kNewAccountCodeVerify)
        userDef.set(false, forKey: kNewAccountCodeVerify)
        
        //  code verify success ,sign as login
        if result {
            userDef.set(true, forKey: kSignAsLogin)
        }
        
        AnaliticsCenter.log(withEvent: .codeVerify, andParameter: [
            "result" : result ? "succeed" : "failed",
            "is_account_new" : isAccountNew ? "true" : "false",
            "is_profile_complete" : isProfileComp ? "true" : "false"
            ])
    }
    
    class func trackSignUpFinish() {
        if !userDef.bool(forKey: kSignAsLogin) {
            return;
        }
        
        userDef.set(false, forKey: kSignAsLogin)
        
        let isAccountNew = userDef.bool(forKey: kNewAccountSignUpFinish) ? "true" : "false"
        
        AnaliticsCenter.log(withEvent: .signUpFinish, andParameter: [
            "is_account_new":isAccountNew
            ])
        
        userDef.set(false, forKey: kNewAccountSignUpFinish)
    }
    
    class func trackFirstAddTimeIfNeed() {
        if userDef.bool(forKey: kNewAccountMatch1stAddTime) {
            userDef.set(false, forKey: kNewAccountMatch1stAddTime)
            AnaliticsCenter.log(event: .matchFirstAddTime)
        }
    }
    
    class func trackChatAddTimeSuccess() {
        if userDef.bool(forKey: kNewAccountMatch1stAddTime) {
            userDef.set(false, forKey: kNewAccountMatch1stAddTime)
            AnaliticsCenter.log(event: .matchFirstAddTime)
        }
//        AnaliticsCenter.log(event: .minuteAddedToCall)
    }
    
    class func trackChatAddFriendSuccess() {
        if userDef.bool(forKey: kNewAccountMatch1stAddFriend) {
            userDef.set(false, forKey: kNewAccountMatch1stAddFriend)
            AnaliticsCenter.log(event: .matchFirstAddFriend)
        }
        
//        AnaliticsCenter.log(event: .chatAddFriendSuccess)
    }
    
    class func trackMatchRecieve(){
        if userDef.bool(forKey: kNewAccountMatch1stRecieve) {
            AnaliticsCenter.log(event: .matchFirstRecieve)
            print("trackFristMatchRecieve")
            userDef.set(false, forKey: kNewAccountMatch1stRecieve)
        }
        
        AnaliticsCenter.log(event:.matchReveived)
    }
}
