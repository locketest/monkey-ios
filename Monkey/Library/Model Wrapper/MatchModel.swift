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

class MatchUser: NSObject {
	/**
	*  当前用户
	*/
	var user: RealmUser
	
	/**
	*  与对方的距离
	*/
	var match_distance: Int = 0
	
	/**
	*  是否加入到 agora 房间(可以接收房间内消息)
	*/
	var joined = false
	/**
	*  是否成功连接 agora(收到对方视频流)
	*/
	var connected = false
	/**
	*  是否对此用户点击了举报按钮
	*/
	var showReport = false
	/**
	*  是否举报了对方
	*/
	var report = false
	/**
	*  举报原因
	*/
	var reportReason: ReportType?
	/**
	*  是否被对方举报
	*/
	var reported = false
	/**
	*  是否主动发送了加好友请求
	*/
	var friendRequest = false
	/**
	*  是否先收到了对方加好友请求
	*/
	var friendRequested = false
	/**
	*  是否接受了加好友请求
	*/
	var friendAccept = false
	/**
	*  对方是否接受了加好友请求
	*/
	var friendAccepted = false
	
	/**
	*  是否点了 skip 了
	*/
	var skip = false
	/**
	*  是否点了 accept 了
	*/
	var accept = false
	/**
	*  对方点击 accept 的时间
	*/
	var acceptTime: Date?
	
	/**
	*  发送的消息个数
	*/
	var sendedMessage = 0
	/**
	*  点击 add time 次数
	*/
	var addTimeCount = 0
	/**
	*  是否点击了 unmute
	*/
	var unMuteRequest = false
	
	// 是否与此人加成好友(当前 match 加成的好友)
	var friendAdded: Bool {
		return self.friendAccept || self.friendAccepted
	}
	
	// 是否是好友
	func friendMatched() -> Bool {
		guard friendAdded == false else {
			return true
		}
		
		guard let user_id = user.user_id else {
			return false
		}
		
		let isFriendMatched = NSPredicate(format: "user.user_id == \"\(user_id)\"")
		let friendsShips = FriendsViewModel.sharedFreindsViewModel.friendships
		let friendMatched = friendsShips?.filter(isFriendMatched).first
		return friendMatched != nil
	}

	init(with user: RealmUser) {
		self.user = user
	}
}

class ChannelModel: NSObject, Mappable {
	
	/**
	*  channel room id
	*/
	var channel_id: String!
	/**
	*  channel media_key
	*/
	var channel_key: String!
	/**
	*  channel service
	*/
	var video_service: String = "agora"
	/**
	*  是否支持前置 accept 消息
	*/
	var notify_accept: Bool = true
	
	// 是否支持 agora
	func supportAgora() -> Bool {
		return video_service == "agora"
	}
	// 是否支持前置 accept 消息
	func supportSocket() -> Bool {
		return notify_accept
	}
	
	required init?(map: Map) {
		
	}
	
	func mapping(map: Map) {
		channel_id			<- map["channel_id"]
		channel_key			<- map["channel_key"]
		video_service		<- map["video_service"]
	}
}

class VideoCallModel: ChannelModel {
	/**
	*  the other user
	*/
	var user: MatchUser?
	/**
	*  initiator user of this call
	*/
	var initiator: RealmUser?
	/**
	*  friendship for this call
	*/
	var friendship: RealmFriendship?
	
	// 是否是主动拨打出去的
	var call_out = true
	// chat_id 每个 match 的 chat_id
	var chat_id: String!
	// create at
	var created_at: Date?

	// status for match model
	var status: String?
	// biography to show
	var bio: String?
	
	// 连接成功的时间
	var connectTime: Date?
	
	required init?(map: Map) {
		super.init(map: map)
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
		chat_id			<- map["id"]
		created_at		<- map["created_at"]
		status			<- map["status"]
		bio				<- map["bio"]
	}
}

class MatchModel: ChannelModel {
	// chat_id 每个 match 的 chat_id
	var chat_id: String?
	// request id 每个 match message 的唯一标识符，用于鉴别是否是当前正在请求的 match
	var request_id: String?
	
	var user_count = 1
	func pair() -> Bool {
		return user_count == 2
	}
	func matched_pair() -> Bool {
		return user_count == 2
	}
	// matched user
	var left: MatchUser?
	var right: MatchUser?
	
	// 1 normal 2 text 3 event
	var match_mode: String = MatchMode.VideoMode.rawValue
	// event_mode_id
	var event_mode: String?
	
	// biography to show
	var bio: String?
	// biography to show for next match
	var next_fact: String?
	// status for match model
	var status: String?
	// create at
	var created_at: Date?
	
	// 自己是否 accept 过
	var accept = false
	// 收发消息的次数(文本消息)
	var sendedMessages = 0
	// 加成时间的次数
	var addTimeRequestCount = 0
	// 是否 unmute
	var unMuteRequest = false
	// create at
	var beginTime = Date.init()
	// 点击 accept 的时间
	var acceptTime: Date?
	// 开始连接的时间
	var connectTime: Date? {
		guard let myAcceptTime = acceptTime, let leftAcceptTime = left?.acceptTime else {
			return nil
		}
		
		var connectTime: Date? = nil
		if matched_pair() {
			if let rightAcceptTime = right?.acceptTime {
				connectTime = max(myAcceptTime, max(leftAcceptTime, rightAcceptTime))
			}
		}else {
			connectTime = max(myAcceptTime, leftAcceptTime)
		}
		return connectTime
	}
	//  connect 成功的时间
	var connectedTime: Date?
	
	// 是否开启了声音
	func isUnmuted() -> Bool {
		return (left?.unMuteRequest ?? false) && self.unMuteRequest
	}
	// 是否点击过举报
	func isShowReport() -> Bool {
		return left?.showReport ?? right?.showReport ?? false
	}
	// 是否举报了对方
	func isReportPeople() -> Bool {
		return left?.report ?? right?.report ?? false
	}
	// 是否被举报了
	func isReportedPeople() -> Bool {
		return left?.reported ?? right?.reported ?? false
	}
	// 收到其他所有人的推流
	func allUserConected() -> Bool {
		var connected = left?.connected ?? false
		if matched_pair() {
			connected = connected && (right?.connected ?? false)
		}
		
		return connected
	}
	
	// 其他所有人进入房间
	func allUserJoined() -> Bool {
		var joined = left?.joined ?? false
		if matched_pair() {
			joined = joined && (right?.joined ?? false)
		}
		
		return joined
	}
	//  其他所有用户全都 accept
	func allUserAccepted() -> Bool {
		var accepted = left?.accept ?? false
		if matched_pair() {
			accepted = accepted && (right?.accept ?? false)
		}
		
		return accepted
	}
	// 是否加成好友
	func friendAdded() -> Bool {
		return left?.friendAdded ?? right?.friendAdded ?? false
	}

	required init?(map: Map) {
		super.init(map: map)
	}

	override func mapping(map: Map) {
		super.mapping(map: map)
		chat_id			<- map["id"]
		request_id		<- map["request_id"]
		
		match_mode		<- map["match_mode"]
		event_mode		<- map["event_mode"]
		bio				<- map["bio"]
		status			<- map["status"]
		created_at		<- map["created_at"]
	}
}

class FriendPairModel: ChannelModel {
	var friendPair: MatchUser!
	
	// 我是否收到了 twop match
	var myConfirmMatch = false
	// 好友是否收到了 twop match
	var friendConfirmMatch = false
	func confirmMatch() -> Bool {
		return myConfirmMatch && friendConfirmMatch
	}
	
	// 向好友发送 确认离开 消息(先确认完毕的人发送完不能直接离开房间，要等对方发送或者收到对方离开的回调；后确认完毕的人收到此消息后向对方发送此消息，然后直接离开房间)
	var confirmLeave = false
	func shouldConnectPair() -> Bool {
		return shouldConnectPair() && (confirmLeave || friendPair.joined == false)
	}
}
