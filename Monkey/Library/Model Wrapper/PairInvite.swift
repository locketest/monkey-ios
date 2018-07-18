//
//  PairInvite.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/18.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

@objcMembers class InvitedPair: MonkeyModel {
	
	override static func primaryKey() -> String {
		return "friend_id"
	}
	
	dynamic var friend_id: Int = 0
	
	// expire_time time
	dynamic var expire_time: TimeInterval = 0
	
	required convenience init?(map: Map) {
		if map["friend_id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		friend_id <- map["friend_id"]
		expire_time <- map["expire_time"]
	}
}

@objcMembers class PairInvite: MonkeyModel {
	
	override static func primaryKey() -> String {
		return "pair_id"
	}
	
	// channel name
	dynamic var channel_name: String?
	// channel key
	dynamic var channel_key: String?
	
	// invite status
	dynamic var status: Int = TwopPairManager.Status.UnResponse.rawValue
	
	// user id of pair
	dynamic var user_id: Int = 0
	dynamic var invitee_id: Int = 0
	dynamic var pair_id: String = ""
	
	// some time
	dynamic var invite_at: TimeInterval = 0
	dynamic var updated_at: TimeInterval = 0
	dynamic var created_at: TimeInterval = 0
	dynamic var next_invite_at: TimeInterval = 0
	
	required convenience init?(map: Map) {
		if map["channel_key"].currentValue == nil || map["channel_name"].currentValue == nil || map["pair_id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		channel_name <- map["channel_name"]
		channel_key <- map["channel_key"]
		
		status <- map["status"]
		
		user_id <- map["user_id"]
		invitee_id <- map["invitee_id"]
		pair_id <- map["pair_id"]
		
		invite_at <- map["invite_at"]
		updated_at <- map["updated_at"]
		created_at <- map["created_at"]
		next_invite_at <- map["next_invite_at"]
	}
}
