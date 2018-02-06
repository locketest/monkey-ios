//
//  RemoteConfig.swift
//  Monkey
//
//  Created by 王广威 on 2018/1/18.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

class RemoteConfigManager {
	static let shared = RemoteConfigManager()
	private init() {}
	
	let remoteConfig = RemoteConfig.remoteConfig()
	func fetchLatestConfig() {
		remoteConfig.fetch(withExpirationDuration: 60 * 60) { (status, maybeError) in
			if maybeError == nil, status == .success {
				self.remoteConfig.activateFetched()
			}
		}
	}
	
	// example
	// RemoteConfigManager.shared.match_accept_time
    var match_accept_time: Int {
        if let match_wait_accept_time = remoteConfig.configValue(forKey: "match_accept").numberValue?.intValue {
            return (match_wait_accept_time == 0) ? 5 : match_wait_accept_time;
        }else {
            return 5; // default value
        }
    }
    
    var match_waiting_time: Int {
        if let match_waiting_time = remoteConfig.configValue(forKey: "match_waiting").numberValue?.intValue {
            return (match_waiting_time == 0) ? 5 : match_waiting_time;
        }else {
            return 5; // default value
        }
    }
    var match_autoskip_warncount: Int {
        if let match_autoskip_warncount = remoteConfig.configValue(forKey: "match_auto_skip").numberValue?.intValue {
            return (match_autoskip_warncount == 0) ? 5 : match_autoskip_warncount;
        }else {
            return 5; // default value
        }
    }
    var match_connect_time: Int {
        if let match_connect_time = remoteConfig.configValue(forKey: "room_max_connect_time").numberValue?.intValue {
            return (match_connect_time == 0) ? 8 : match_connect_time;
        }else {
            return 8; // default value
        }
    }
}