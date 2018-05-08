//
//  RealmMatchInfo.swift
//  Monkey
//
//  Created by 王广威 on 2018/4/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import ObjectMapperAdditions
//import ObjectMapper_Realm

class RealmMatchEvent: JSONAPIObject, RealmObjectProtocol, Mappable {
//	"created_at": "2018-04-27T11:16:59.879Z",
//	"description": "description for event DB",
//	"emoji": "😀",
//	"end_time": 1522892445,
//	"event_bio": "test bio",
//	"icon": "http://data.monkey.cool/icons/Food.png",
//	"id": 1,
//	"is_active": true,
//	"name": "EVENT_NAME3d",
//	"start_time": 1515112533
	
	static let type = "MatchEvent"
	
	dynamic var created_at: Date?
	dynamic var start_time: Double = 0
	dynamic var end_time: Double = 0
	
	dynamic var description_title: String?
	dynamic var event_bio: String?
	dynamic var emoji: String?
	dynamic var name: String?
	dynamic var icon: String?
	
	dynamic var id: Int = 0
	
	func isAvailable() -> Bool {
		let current_time = Date().timeIntervalSince1970
		return !(current_time < start_time || current_time > end_time)
	}
	
	override static func primaryKey() -> String {
		return "id"
	}
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	func mapping(map: Map) {
		created_at <- (map["created_at"], DateTransform())
		start_time <- (map["start_time"], DoubleTransform())
		end_time <- (map["end_time"], DoubleTransform())
		
		description_title <- map["description"]
		event_bio <- map["event_bio"]
		emoji <- map["emoji"]
		name <- map["name"]
		icon <- map["icon"]
		
		id <- (map["id"], IntTransform())
	}
}

class RealmMatchInfo: JSONAPIObject, Mappable, RealmObjectProtocol {
	static let type = "MatchInfo"
	
	var id = RealmMatchInfo.type
	var convo_tips = List<String>()
	var match_tips = List<String>()
	dynamic var events: RealmMatchEvent?
	
	override static func primaryKey() -> String {
		return "id"
	}
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	func mapping(map: Map) {
		convo_tips <- (map["convo_tips"], RealmTypeCastTransform())
		match_tips <- (map["match_tips"], RealmTypeCastTransform())
		events <- map["events"]
	}
}

