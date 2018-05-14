//
//  RealmVideoCall.swift
//  Monkey
//
//  Created by YY on 2018/3/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

class RealmVideoCall: MonkeyModel {
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
    dynamic var status: String?
    dynamic var token: String?
    dynamic var bio: String?
    dynamic var created_at: NSDate?
    
    dynamic var match_mode: String?
    dynamic var user: RealmUser?
    dynamic var friendship: RealmFriendship?
    dynamic var initiator: RealmUser?
	
	required convenience init?(map: Map) {
		self.init()
	}
}
