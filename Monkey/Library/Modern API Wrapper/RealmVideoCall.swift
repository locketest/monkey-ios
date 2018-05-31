//
//  RealmVideoCall.swift
//  Monkey
//
//  Created by YY on 2018/3/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

protocol VideoCallProtocol {
	
	var session_id: String? { get set }
	// token for opentok
	var token: String? { get set }
	// media_key for agora
	var media_key: String? { get set }
	
	var video_service: String? { get set }
	
	var created_at: NSDate? { get set }
	
	var bio: String? { get set }
	var status: String? { get set }
	
	var user: RealmUser? { get set }
	var initiator: RealmUser? { get set }
	var friendship: RealmFriendship? { get set }
	var matchedFriendship: RealmFriendship? { get }
	
	var channelToken: String { get }
	
	// 是否支持 agora
	func supportAgora() -> Bool
	
	func supportSocket() -> Bool
}

class RealmVideoCall: MonkeyModel, VideoCallProtocol {
	override class var api_version: ApiVersion {
		return ApiVersion.V13
	}
	override class var type: String {
		return ApiType.Videocall.rawValue
	}
	override static func primaryKey() -> String {
		return "chat_id"
	}
	
	dynamic var chat_id: String?
	
	dynamic var session_id: String?
	// token for opentok
	dynamic var token: String?
	// media_key for agora
	dynamic var media_key: String?
	
	dynamic var video_service: String?
	
	dynamic var created_at: NSDate?
	
	dynamic var bio: String?
	dynamic var status: String?
	dynamic var notify_accept: Bool = false
	
	dynamic var user: RealmUser?
	dynamic var initiator: RealmUser?
	dynamic var friendship: RealmFriendship?
	
	var matchedFriendship: RealmFriendship? {
		let realm = try? Realm()
		let user_id = user?.user_id ?? initiator?.user_id ?? ""
		let friend = realm?.objects(RealmFriendship.self).filter("user.user_id == \"\(user_id)\"").first
		return friend
	}
	
	var channelToken: String {
		if supportAgora() {
			return media_key ?? ""
		}else {
			return token ?? ""
		}
	}
	
	// 是否支持 agora
	func supportAgora() -> Bool {
		return video_service == "agora"
	}
	
	func supportSocket() -> Bool {
		return notify_accept == true
	}
	
	required convenience init?(map: Map) {
		self.init()
	}
}
