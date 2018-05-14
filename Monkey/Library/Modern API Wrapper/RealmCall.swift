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

class RealmCall: MonkeyModel {
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
	
	dynamic var bio: String?
	dynamic var created_at: NSDate?
	dynamic var match_mode: String?
	dynamic var request_id: String?
    dynamic var session_id: String?
	dynamic var token: String?
	let match_distance = RealmOptional<Int>()
	
    dynamic var status: String?
    dynamic var user: RealmUser?
    dynamic var friendship: RealmFriendship?
    dynamic var initiator: RealmUser?
	
	required convenience init?(map: Map) {
		self.init()
	}
}
