//
//  MKRemoteConfigHelper.swift
//  Monkey
//
//  Created by YY on 2018/1/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

enum MKRemoteConfigKeys : String {
    case MatchMaxAcceptTime = "match_accept"
    case MatchMaxWaitingTime = "match_waiting"
    case MatchAutoSkipTimesOut = "match_auto_skip"
    case MatchRoomMaxConnectTime = "room_max_connect_time"
}


class MKRemoteConfigHelper: NSObject {
    static let shareHelper = MKRemoteConfigHelper()
    var configValues:[String:RemoteConfigValue] = NSMutableDictionary() as! [String : RemoteConfigValue]
    
    override init() {
        super.init()        
    }
    
    class func setupRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()
        
        remoteConfig.setDefaults([
            MKRemoteConfigKeys.MatchMaxAcceptTime.rawValue : NSNumber.init(value:5),
            MKRemoteConfigKeys.MatchMaxWaitingTime.rawValue : NSNumber.init(value:5),
            MKRemoteConfigKeys.MatchAutoSkipTimesOut.rawValue : NSNumber.init(value:5),
            MKRemoteConfigKeys.MatchRoomMaxConnectTime.rawValue : NSNumber.init(value: 15)
            ])
        
        remoteConfig.fetch(withExpirationDuration: 60*60) { (status, error) in
            if status == .success {
                remoteConfig.activateFetched()
            }else{
                
            }
            
            self.shareHelper.updateConfigs()
        }
    }
    
    func updateConfigs(){
        let remoteConfig = RemoteConfig.remoteConfig()
        self.configValues[MKRemoteConfigKeys.MatchMaxAcceptTime.rawValue] =
            remoteConfig.configValue(forKey: MKRemoteConfigKeys.MatchMaxAcceptTime.rawValue)
        self.configValues[MKRemoteConfigKeys.MatchMaxWaitingTime.rawValue] =
            remoteConfig.configValue(forKey: MKRemoteConfigKeys.MatchMaxWaitingTime.rawValue)
        self.configValues[MKRemoteConfigKeys.MatchAutoSkipTimesOut.rawValue] =
            remoteConfig.configValue(forKey: MKRemoteConfigKeys.MatchAutoSkipTimesOut.rawValue)
        self.configValues[MKRemoteConfigKeys.MatchRoomMaxConnectTime.rawValue] =
            remoteConfig.configValue(forKey: MKRemoteConfigKeys.MatchRoomMaxConnectTime.rawValue)

    }
}
