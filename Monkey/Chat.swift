
//
//  Stats.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/23/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation
import Alamofire

class Chat {
    var chatId:String
    var wastedTime = 0
	
    var theirMinutesAdded = 0
    var minutesAdded = 0
	
    var theySharedSnapchat = false
    var sharedSnapchat = false
	
	var unMute = false
	var theyUnMute = false
	
	var reporting = false
	var reported = false
	
    var skipped = false
	
    var first_name: String?
    var profile_image_url: String?
    var user_id: String?
	var match_mode: MatchMode = MatchMode.VideoMode
	var match_with_mode: MatchMode {
		if let selectedMatchMode = Achievements.shared.selectMatchMode, selectedMatchMode == .TextMode, match_mode == .TextMode {
			return .TextMode
		}
		return .VideoMode
	}
	
	init(chat_id: String, first_name: String?, profile_image_url: String?, user_id: String?, match_mode: String? = MatchMode.VideoMode.rawValue) {
        self.chatId = chat_id
        self.first_name = first_name
        self.profile_image_url = profile_image_url
        self.user_id = user_id
		self.match_mode = MatchMode.init(string: match_mode ?? MatchMode.VideoMode.rawValue)
    }
    
    /**
        Represents who in the converstaion pressed the friend button. This proprety SHOULD be accurate except when there are networking issues.
     */
    enum SnapchatValue: String {
        /// You (the current user) and the person you matched with both pressed the Friend button.
        case both = "BOTH"
        /// The person you were talking to pressed friended you but you (the current user) didn't add them back.
        case them = "THEM"
        /// You (the current user) tried to friend the person you were talking to but they didn't friend you back.
        case me = "ME"
        /// Neither you (the current user) or the person you were talking to added each other as a friend.
        case neither = ""
    }
    
    func update(callback: ((_ error: String?) -> Void)?) {
        guard let authorization = APIController.authorization else {
            callback?("Missing authorization")
            return
        }
        var snapchatValue = SnapchatValue.neither
        if self.theySharedSnapchat && self.sharedSnapchat {
            snapchatValue = .both
        } else if self.theySharedSnapchat {
            snapchatValue = .them
        } else if self.sharedSnapchat {
            snapchatValue = .me
        }
        let paramaters:Parameters = [
            "data": [
                "type": "chats",
                "id": self.chatId,
                "attributes": [
                    "wasted_time": self.wastedTime,
                    "their_minutes_added": self.theirMinutesAdded,
                    "minutes_added": self.minutesAdded,
                    "snapchat": snapchatValue.rawValue,
                    "skipped": self.skipped
                ],
            ]
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": authorization,
            "Accept": "application/json"
        ]
        
        Alamofire.request("\(Environment.baseURL)/api/v1.0/chats/\(self.chatId)", method: .patch, parameters: paramaters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
//        Alamofire.request("\(Environment.baseURL)/api/v1.3/match_request", method: .patch, parameters: paramaters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            if let error = response.result.error {
                callback?(error.localizedDescription)
                return
            }
            if response.response!.statusCode >= 400  {
                if let reason = (response.result.value as? Dictionary<String, Array<Dictionary<String, Any>>>)?["errors"]?[0]["title"] as? String {
                    callback?(reason)
                } else {
                    callback?("Unknown error")
                }
                return
            }
            callback?(nil)
        }
    }
}
