//
//  UserOptions.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

class UserOptions: MonkeyModel {
	override class var requst_subfix: String {
		return "me/options"
	}
	override class var api_version: ApiVersion {
		return ApiVersion.V13
	}
	override class var type: String {
		return ApiType.UserOptions.rawValue
	}
	override static func primaryKey() -> String {
		return "user_id"
	}
	
	var user_id = APIController.shared.currentUser?.user_id
	var update_birth_date = false
	var update_username = Date.init()
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		update_birth_date <- map["data.update_birth_date"]
		update_username <- (map["data.update_username"], DateTransform())
	}
}
