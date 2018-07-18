//
//  UserOptions.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

class UserOptions: NSObject, MonkeyApiObject, Mappable {
	class var requst_subfix: String {
		return "me/options"
	}
	class var api_version: ApiVersion {
		return ApiVersion.V13
	}
	class var type: String {
		return ApiType.UserOptions.rawValue
	}
	static func primaryKey() -> String {
		return "user_id"
	}
	
	var user_id = UserManager.shared.currentUser?.user_id
	var update_birth_date = false
	var update_username = Date.init()
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	func mapping(map: Map) {
		update_birth_date <- map["data.update_birth_date"]
		update_username <- (map["data.update_username"], DateTransform())
	}
}
