//
//  OnlineStatus.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class OnlineStatus: MonkeyModel {
	
	override static func primaryKey() -> String {
		return "friend_id"
	}
	
	dynamic var friend_id: Int = 0
	
	// expire_time time
	dynamic var online: Bool = true
	
	required convenience init?(map: Map) {
		if map["friend_id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		friend_id <- map["friend_id"]
		online <- map["online"]
	}
}

