//
//  NotificationMessage.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper


class NotificationMessage: MonkeyModel {
	
	static let SystemID = 0
	
	override static func primaryKey() -> String {
		return "msg_id"
	}
	
	override static func ignoredProperties() -> [String] {
		return ["ext"]
	}
	
	dynamic var msg_id: String!
	dynamic var sender_id: Int = SystemID
	dynamic var content: String = ""
	
	dynamic var msg_type: Int = SocketMessageType.unKnown.rawValue
	var socketType: SocketMessageType {
		return SocketMessageType.init(type: msg_type)
	}
	
	var ext: [String: Any] = [String: Any]()
	func receivedCall() -> VideoCallModel? {
		var videoCall: VideoCallModel?
		
		var callDic: [String: Any] = ext
		let friend_id = callDic["friend_id"] as? Int
		let friend: [String: Any] = [
			"id": friend_id as Any
		]
		callDic["friend"] = friend
		callDic["match_id"] = friend_id
		
		if let parsedCall = Mapper<VideoCallModel>().map(JSON: callDic) {
			videoCall = parsedCall
			videoCall?.call_out = false
		}
		return videoCall
	}
	
	func cancelCallID() -> String {
		let friend_id = ext["friend_id"] as? Int
		
		return String.init(friend_id ?? sender_id)
	}
	
	required convenience init?(map: Map) {
		if map["msg_id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		msg_id			<- map["msg_id"]
		sender_id		<- map["sender_id"]
		content			<- map["content"]
		msg_type		<- map["msg_type"]
		ext				<- map["ext"]
	}
}
