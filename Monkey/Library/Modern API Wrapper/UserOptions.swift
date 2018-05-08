//
//  UserOptions.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

class UserOptions: Mappable {
	static let type = "UserOption"
	static let api_version = "v1.3"
	static let requst_subfix = "me/options"
	
	lazy var update_birth_date = false
	lazy var update_username = Date.init()
	
	required init?(map: Map) {
		
	}
	
	func mapping(map: Map) {
		update_birth_date <- map["data.update_birth_date"]
		update_username <- (map["data.update_username"], DateTransform())
	}
}
