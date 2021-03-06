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
		remoteConfig.fetch(withExpirationDuration: 60 * 15) { (status, maybeError) in
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
	var event_mode_next_show: Float {
		if let event_mode_next_show = remoteConfig.configValue(forKey: "event_mode_next_show").numberValue?.floatValue {
			return (event_mode_next_show == 0) ? 3 : event_mode_next_show;
		}else {
			return 3; // default value
		}
	}
	var next_show_time: Int {
		if let next_show_time = remoteConfig.configValue(forKey: "next_show").numberValue?.intValue {
			return (next_show_time == 0) ? 6 : next_show_time;
		}else {
			return 6; // default value
		}
	}
	var app_in_review: Bool {
		if let app_review_version = remoteConfig.configValue(forKey: "app_review_version").stringValue {
			return app_review_version == Environment.appVersion
		}else {
			return false
		}
	}
    
    var moderation_age_reduce: Int {
        if let value = remoteConfig.configValue(forKey: "moderation_age_reduce").numberValue?.intValue {
            return value
        }else {
            return 50
        }
    }
    
    var moderation_non_peak: Int {
        if let value = remoteConfig.configValue(forKey: "moderation_non_peak").numberValue?.intValue {
            return value
        }else {
            return 50
        }
    }
    
    var moderation_gender_match: Int {
        if let value = remoteConfig.configValue(forKey: "moderation_gender_match").numberValue?.intValue {
            return value
        }else {
            return 50
        }
    }
	
	var text_chat_mode: Bool {
		let text_chat_mode = remoteConfig.configValue(forKey: "text_chat_mode").boolValue
		return text_chat_mode;
	}
}
