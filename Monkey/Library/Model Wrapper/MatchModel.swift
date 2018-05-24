//
//  MatchModel.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import ObjectMapperAdditions

class MatchUser: RealmUser {
	var match_user: RealmUser?
	
	var joined = false
	var connected = false
	var report = false
	var reported = false
	var friendRequest = false
	var friendRequested = false
	var friendAccept = false
	var friendAccepted = false
	var skip = false
	var accept = false
	
	var sendedMessage = 0
	var addTimeRequest = false
	var unMuteRequest = false
	
	// 是否与此人加成好友
	func friendAdded() -> Bool {
		return self.friendAccept || self.friendAccepted
	}
	
	// 是否是好友
	func friendMatched() -> Bool {
		guard let user_id = match_user?.user_id else {
			return friendAdded()
		}
		let isFriendMatched = NSPredicate(format: "user.user_id == \"\(user_id)\"")
		let friendsShips = FriendsViewModel.sharedFreindsViewModel.friendships
		let friendMatched = friendsShips?.filter(isFriendMatched).first
		return friendMatched != nil || friendAdded()
	}

	required convenience init?(map: Map) {
		self.init()
	}

	override func mapping(map: Map) {
		super.mapping(map: map)
	}
}

class MatchModel: MonkeyModel {
	// chat_id(save to realm)
	var chat_id: String?
	// request
	var request_id: String?

	// agora or opentok
	var video_service: String = "opentok"
	// session(channel)
	var session_id: String = ""
	// media_key for agora
	var media_key: String?
	// token for opentok
	var token: String?
	
	var channelToken: String {
		if supportAgora() {
			return media_key ?? ""
		}else {
			return token ?? ""
		}
	}
	
	// 1 normal 2 text 3 event
	var match_mode: String = MatchMode.VideoMode.rawValue
	// event_mode_id
	var event_mode: String?
	
	// biography to show
	var bio: String?

	// create at
	var created_at: Date?

	// if match with near by
	var match_distance: Int = 0

	// status for match model
	var status: String?

	// matched user
	var user: MatchUser?
	
	// user defined property
	var showReport = false
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
	
	// 是否开启了声音
	func isUnmuted() -> Bool {
		return (user?.unMuteRequest ?? false) && self.unMuteRequest
	}
	// 是否举报了对方
	func isReportPeople() -> Bool {
		return user?.reported ?? false
	}
	// 是否被举报了
	func isReportedPeople() -> Bool {
		return user?.report ?? false
	}
	// 收到其他所有人的推流
	func allUserConected() -> Bool {
		return user?.connected ?? false
	}
	// 其他所有人进入房间
	func allUserJoined() -> Bool {
		return user?.joined ?? false
	}
	//  其他所有用户全都 accept
	func allUserAccepted() -> Bool {
		return user?.accept ?? false
	}
	// 是否加成好友
	func friendAdded() -> Bool {
		return user?.friendAdded() ?? false
	}
	
	// 是否支持 agora
	func supportAgora() -> Bool {
		return video_service == "agora"
	}

	required convenience init?(map: Map) {
		self.init()
	}

	override func mapping(map: Map) {
		super.mapping(map: map)
		chat_id <- map["id"]
		if chat_id == nil {
			chat_id <- map["chat_id"]
		}
		request_id <- map["request_id"]
		if request_id == nil {
			request_id <- map["attributes.request_id"]
		}
		
		video_service <- map["video_service"]
		if video_service.count == 0 {
			video_service <- map["attributes.video_service"]
		}
		session_id <- map["session_id"]
		if session_id.count == 0 {
			session_id <- map["attributes.session_id"]
		}
		media_key <- map["media_key"]
		if media_key == nil {
			media_key <- map["attributes.media_key"]
		}
		token <- map["token"]
		if token == nil {
			token <- map["attributes.token"]
		}
		
		match_mode <- map["match_mode"]
		if match_mode == MatchMode.VideoMode.rawValue {
			match_mode <- map["attributes.match_mode"]
		}
		event_mode <- map["event_mode"]
		if event_mode == nil {
			event_mode <- map["attributes.event_mode"]
		}
		bio <- map["bio"]
		if bio == nil {
			bio <- map["attributes.bio"]
		}
		
		created_at <- (map["created_at"], DateTransform())
		if created_at == nil {
			created_at <- map["attributes.created_at"]
		}
		
		match_distance <- map["match_distance"]
		if match_distance == 0 {
			match_distance <- map["attributes.match_distance"]
		}
		status <- map["status"]
		if status == nil {
			status <- map["attributes.status"]
		}
		
		user <- map["relationships.user.data"]
	}
}
