//
//  Configs.swift
//  Monkey
//
//  Created by YY on 2018/2/28.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class Configs {
    static let kContiLoginTimes = "kContiLogTimes"
    static let kLastLoginTime = "kLastLoginTime"
    
    class func signAsLogin(){
        let lastLoginDay = UserDefaults.standard.integer(forKey: kLastLoginTime)
        let curDay = Date.init().timeIntervalSince1970
        UserDefaults.standard.set(curDay, forKey: kLastLoginTime)
        
        if Date.init(timeIntervalSince1970: TimeInterval(lastLoginDay)).compare(.isYesterday) {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey:kContiLoginTimes) + 1, forKey: kContiLoginTimes)
        }else {
            UserDefaults.standard.set(0, forKey: kContiLoginTimes)
        }
    }
    
    class func contiLogTimes() -> Int{
        return UserDefaults.standard.integer(forKey:kContiLoginTimes)
    }
    
    class func hadShowRateAlertToday() -> Bool{
        let lastShowRateTime = UserDefaults.standard.integer(forKey: "rateAlertLastShowTime")
        let calendar = Calendar.init(identifier: .gregorian)
        var comps = DateComponents()
        comps = calendar.dateComponents([.year,.month,.day, .weekday, .hour, .minute,.second], from: Date.init(timeIntervalSince1970: TimeInterval(lastShowRateTime)))
        let todayComps = calendar.dateComponents([.year,.month,.day, .weekday, .hour, .minute,.second], from: Date())
        guard let lastDay = comps.day, let todayDay = todayComps.day , (todayDay - lastDay) != 0  else {
            return true
        }
        
        UserDefaults.standard.set(Date.init().timeIntervalSince1970, forKey:"rateAlertLastShowTime" )
        return false
    }
}
