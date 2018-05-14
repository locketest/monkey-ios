//
//  MonkeyUser.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/10.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class MonkeyUser: MonkeyModel {
	override class var type: String {
		return ApiType.Users.rawValue
	}
	
	override static func primaryKey() -> String {
		return "user_id"
	}
	
	let age = RealmOptional<Int>()
	let bananas = RealmOptional<Int>()

	let seconds_in_app = RealmOptional<Int>()

	let facebook_friends_invited = RealmOptional<Int>()
	let is_snapcode_uploaded = RealmOptional<Bool>()
	let is_admin = RealmOptional<Bool>()
	let is_banned = RealmOptional<Bool>()

	let channels = List<RealmChannel>()

	let latitude = RealmOptional<Double>()
	let longitude = RealmOptional<Double>()
	dynamic var address: String?
	dynamic var state: String?
	dynamic var location: String?

	dynamic var gender: String?
	dynamic var show_gender: String?

	dynamic var first_name: String?
	dynamic var username: String?
	dynamic var snapchat_username: String?

	dynamic var profile_photo_url: String?
	dynamic var profile_photo_upload_url: String?

	dynamic var user_id: String?
	dynamic var birth_date: Date?
	dynamic var updated_at: Date?
	dynamic var created_at: Date?
	dynamic var last_online_at: Date?

	dynamic var instagram_account: RealmInstagramAccount?
	let friendships = LinkingObjects(fromType: RealmFriendship.self, property: "user")

	func isCompleteProfile() -> Bool {
		var isCompleteProfile = true
		if self.birth_date == nil || self.first_name == nil || self.gender == nil {
			isCompleteProfile = false
		}
		return isCompleteProfile
	}

	required convenience init?(map: Map) {
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
	}
}
