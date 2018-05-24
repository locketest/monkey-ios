//
//  RealmCall.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/8/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

class RealmCall: MonkeyModel, VideoCallProtocol {
	override class var requst_subfix: String {
		return "match_request"
	}
	override class var api_version: ApiVersion {
		return ApiVersion.V13
	}
	override class var type: String {
		return ApiType.Chats.rawValue
	}
	override static func primaryKey() -> String {
		return "chat_id"
	}

    dynamic var chat_id: String?
	dynamic var request_id: String?

	dynamic var session_id: String?
	// token for opentok
	dynamic var token: String?
	// media_key for agora
	dynamic var media_key: String?

	dynamic var video_service: String?
	dynamic var event_mode: String?
	dynamic var match_mode: String?

	dynamic var created_at: NSDate?

	dynamic var bio: String?
	let match_distance = RealmOptional<Int>()
    dynamic var status: String?

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

	required convenience init?(map: Map) {
		self.init()
	}
}
