//
//  PairGroup.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/18.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

@objcMembers class PairGroup: MonkeyModel {
	
	override static func primaryKey() -> String {
		return "pair_id"
	}
	
	// channel name
	dynamic var channel_name: String = ""
	// channel key
	dynamic var channel_key: String = ""
	
	// user id of pair
	dynamic var friend_id: Int = 0
	dynamic var pair_id: String = ""
	
	// some time
	dynamic var expire_time: TimeInterval = 0
	
	required convenience init?(map: Map) {
		if map["channel_key"].currentValue == nil || map["channel_name"].currentValue == nil || map["pair_id"].currentValue == nil || map["friend_id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		channel_name <- map["channel_name"]
		channel_key <- map["channel_key"]
		
		friend_id <- map["friend_id"]
		pair_id <- map["pair_id"]
		
		expire_time <- map["expire_time"]
	}
}
