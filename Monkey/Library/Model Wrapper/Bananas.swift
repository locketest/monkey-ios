//
//  Bananas.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/18.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

@objcMembers class Bananas: MonkeyModel {
	override static func primaryKey() -> String {
		return "user_id"
	}
	
	override static var api_version: ApiVersion {
		return ApiVersion.V13
	}
	
	override static var type: String {
		return ApiType.Bananas.rawValue
	}
	
	var user_id = UserManager.shared.currentUser?.user_id
	
	dynamic var promotion = "1000 🍌 = Soon 😏"
	dynamic var add_friend = 5
	dynamic var add_time = 2
	dynamic var yesterday = 0
	
	dynamic var updated_at = Date.init()
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		promotion <- map["data.promotion"]
		
		add_friend <- map["data.redeem.add_friend"]
		add_time <- map["data.redeem.add_time"]
		
		yesterday <- map["data.me.yesterday"]
	}
}
