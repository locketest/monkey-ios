
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
    var chatId: String
//	
//	// 是否开启了声音
//	func isUnmuted() -> Bool {
//		return user.unMuteRequest && self.unMuteRequest
//	}
//	// 是否举报了对方
//	func isReportPeople() -> Bool {
//		return user.reported
//	}
//	// 是否被举报了
//	func isReportedPeople() -> Bool {
//		return user.report
//	}
//	// 收到其他所有人的推流
//	func allUserConected() -> Bool {
//		return user.connected
//	}
//	// 其他所有人进入房间
//	func allUserJoined() -> Bool {
//		return user.joined
//	}
//	//  其他所有用户全都 accept
//	func allUserAccepted() -> Bool {
//		return user.accept
//	}
//	// 是否加成好友
//	func friendAdded() -> Bool {
//		return user.friendAdded()
//	}
	
	// 对方请求 add time 次数
    var theirMinutesAdded = 0
	// 主动请求 add time 次数
    var minutesAdded = 0
	
	// 对方请求加好友
    var theySharedSnapchat = false
	// 主动请求加好友
    var sharedSnapchat = false
	// 是否更新刷新好友状态
	var hasRefreshFriendships = false
	
	// 对方是否请求解除静音
	var theyUnMute = false
	// 主动请求解除静音
	var unMute = false
	
	// 是否举报了对方
	var reporting = false
	// 是否被对方举报
	var reported = false
	
	// 是否被过
    var skipped = false
	
	var age: Int?
	var location: String?
	var gender: String?
    var first_name: String?
    var user_id: String?
	// 是否点击过举报按钮
	var showReport = false
	// 是否已经 accpet
	var accept = false
	
	// create at
	var beginTime = Date.init()
	var acceptTime: Date?
	var connectTime: Date?
	
	// 收发消息的次数
	var sendedMessage = 0
	var receivedMessage = 0
	// 加成时间的次数
	var addTimeCount = 0
	var addTimeRequest = false
	var unMuteRequest = false
	
	var match_mode: MatchMode = MatchMode.VideoMode
	var match_room_mode: MatchMode {
		if let selectedMatchMode = Achievements.shared.selectMatchMode, selectedMatchMode == match_mode {
			return match_mode
		}
		return .VideoMode
	}
	
	init(chat_id: String, first_name: String?, gender: String? = Gender.male.rawValue, age: Int? = 0, location: String? = "", profile_image_url: String?, user_id: String?, match_mode: String? = MatchMode.VideoMode.rawValue) {
        self.chatId = chat_id
        self.first_name = first_name
		self.gender = gender
		self.age = age
		self.location = location
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
        let paramaters: Parameters = [
            "data": [
                "type": "chats",
                "id": self.chatId,
                "attributes": [
                    "wasted_time": 0,
                    "their_minutes_added": self.theirMinutesAdded,
                    "minutes_added": self.minutesAdded,
                    "snapchat": snapchatValue.rawValue,
                    "skipped": self.skipped
                ],
            ]
        ]
		
		JSONAPIRequest.init(url: "\(Environment.baseURL)/api/v1.0/chats/\(self.chatId)", method: .patch, parameters: paramaters, options: [
			.header("Authorization", authorization)
			]).addCompletionHandler {[weak self] (result) in
			switch result {
			case .error(let error):
				callback?(error.localizedDescription)
			case .success( _):
				if snapchatValue == .both && (self?.hasRefreshFriendships == false || self == nil) {
					self?.hasRefreshFriendships = true
					RealmFriendship.fetchAll(completion: { (result:JSONAPIResult<[RealmFriendship]>) in
						callback?(nil)
					})
				}else {
					callback?(nil)
				}
			}
		}
    }
}
