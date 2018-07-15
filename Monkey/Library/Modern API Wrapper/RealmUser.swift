//
//  RealmModels.swift
//  Monkey
//
//  Created by Jun Hong on 4/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift
import ObjectMapper
import ObjectMapperAdditions

class RealmUser: MonkeyModel {
	
	override class var type: String {
		return ApiType.Users.rawValue
	}
	override static func primaryKey() -> String {
		return "user_id"
	}
	// user id
	dynamic var user_id: String!
	
	// age
	dynamic var age: Int = 0
	// my bananas
	dynamic var bananas: Int = 0
	
	// delete_at
	dynamic var delete_at: Double = 0
	
	// is online
	dynamic var online: Bool = false
	// is enable twop mode
	dynamic var enabled_two_p: Bool = false
	dynamic var cached_enable_two_p: Bool = false
	
	// is unlocked twop mode
	dynamic var unlocked_two_p: Bool = false
	dynamic var cached_unlocked_two_p: Bool = false
	
	// twop a\b test plan. 1 for planA, 2 for planB
	dynamic var two_puser_group_type: Int = UnlockPlan.A.rawValue
	
	// how many contact should invite again
	dynamic var contact_invite_remain_times: Int = 0
	dynamic var cached_contact_invite_remain_times: Int = 0
	
	// current match type. 1 for 1p, 2 for 2p
	dynamic var match_type: Int = MatchType.Onep.rawValue
	dynamic var cached_match_type: Int = MatchType.Onep.rawValue
	
	// user seconds in app
	dynamic var seconds_in_app: Int = 0
	
	// the number of invited friends
	dynamic var facebook_friends_invited: Int = 0
	// dose user uploaded snapcode
	dynamic var is_snapcode_uploaded: Bool = false
	// is admin
	dynamic var is_admin: Bool = false
	// is_banned
	dynamic var is_banned: Bool = false
	
	// latitude and longitude
	dynamic var latitude: Double = 0
	dynamic var longitude: Double = 0
	
	// user location (country\state\address)
	dynamic var state: String?
	dynamic var address: String?
	dynamic var location: String?
	
	// user gender
	dynamic var gender: String?
	// match prefer gender
	dynamic var show_gender: String?
	
	// username unuse now
	dynamic var username: String?
	// first_name to show
	dynamic var first_name: String?
	// snapchat user name
	dynamic var snapchat_username: String?
	
	// my profile
	dynamic var profile_photo_url: String?
	// upload url
	dynamic var profile_photo_upload_url: String?
	
	// my birthday
	dynamic var birth_date: Date?
	// info updated_at
	dynamic var updated_at: Date?
	// user created_at
	dynamic var created_at: Date?
	// my last online at
	dynamic var last_online_at: Date?
	
	// my instagram account id
	dynamic var instagram_account_id: String?
	// instagram photos
	dynamic var instagram_account: RealmInstagramAccount?
	
	// my channels list
	var channels = List<RealmChannel>()
	
	// 默认头像
	var defaultAvatar: String {
		if self.isFemale() {
			return "ProfileImageDefaultFemale"
		}else {
			return "ProfileImageDefaultMale"
		}
	}
	
	required convenience init?(map: Map) {
		if map["id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
	}
}

extension RealmUser {
	// 用户资料是否完善
	func isCompleteProfile() -> Bool {
		var isCompleteProfile = true
		// birth_date 和 gender 没有视为资料不完善
		if self.birth_date == nil || self.hasGender() == false {
			isCompleteProfile = false
		}
		return isCompleteProfile
	}
	
	// is same gender
	func isSameGender(with other: RealmUser) -> Bool {
		if self.gender == other.gender {
			return true
		}
		return false
	}
	
	// is same country
	func isSameCountry(with other: RealmUser) -> Bool {
		if self.location == other.location {
			return true
		}
		return false
	}
	
	// 是否是女生
	func isFemale() -> Bool {
		if self.gender == Gender.female.rawValue {
			return true
		}
		return false
	}
	// 是否是男生
	func isMale() -> Bool {
		if self.gender == Gender.male.rawValue {
			return true
		}
		return false
	}
	// 是否有性别
	func hasGender() -> Bool {
		if let gender = self.gender, gender.isEmpty == false {
			return true
		}
		return false
	}
	// 是否有名字
	func hasName() -> Bool {
		if let first_name = self.first_name, first_name.isEmpty == false {
			return true
		}
		return false
	}
	// 是否美国用户
	func isAmerican() -> Bool {
		var isAmerican = false
		if self.location == "United States" {
			isAmerican = true
		}
		return isAmerican
	}
	// 是否 monkey king
	func isMonkeyKing() -> Bool {
		var isMonkeyKing = false
		if self.user_id == "2" {
			isMonkeyKing = true
		}
		return isMonkeyKing
	}
	
	func refreshCache() {
		if let realm = try? Realm() {
			do {
				try realm.write {
					self.cached_match_type = self.match_type
					self.cached_enable_two_p = self.enabled_two_p
					self.cached_unlocked_two_p = self.unlocked_two_p
					self.cached_contact_invite_remain_times = self.contact_invite_remain_times
				}
			} catch(let error) {
				print("Error: ", error)
			}
		}
	}
}

extension RealmUser {
	/// Each Attribute case corresponds to a User attribute that can be updated/modified.
	enum Attribute {
		case gender(String?)
		case show_gender(String?)
		
		case latitude(Double?)
		case longitude(Double?)
		case address(String?)
		
		case first_name(String?)
		case snapchat_username(String?)
		
		case birth_date(Date?)
		case seconds_in_app(Int?)
		
		case match_type(Int?)
		
		case channels(List<RealmChannel>)
	}
	
	/**
	Updates user information both backend and frontend
	
	- parameter attributes: An array of Attribute items to update.
	- parameter callback: Called whent the request completes.
	- parameter error: The error encountered.
	*/
	func update(attributes: [Attribute], completion: @escaping (_ error: APIError?) -> Void) {
		
		var relationshipsJSON = [String:Any]()
		var attributesJSON = [String:Any]()
		for attribute in attributes {
			switch attribute {
			case .latitude(let latitude):
				attributesJSON["latitude"] = latitude ?? NSNull()
			case .longitude(let longitude):
				attributesJSON["longitude"] = longitude ?? NSNull()
			case .address(let address):
				attributesJSON["address"] = address ?? NSNull()
				
			case .gender(let gender):
				attributesJSON["gender"] = gender ?? NSNull()
			case .show_gender(let show_gender):
				attributesJSON["show_gender"] = show_gender ?? NSNull()
				
			case .first_name(let first_name):
				attributesJSON["first_name"] = first_name ?? NSNull()
			case .snapchat_username(let snapchat_username):
				attributesJSON["snapchat_username"] = snapchat_username ?? NSNull()
				
			case .birth_date(let birth_date):
				attributesJSON["birth_date"] = birth_date?.iso8601 ?? NSNull()
			case .seconds_in_app(let seconds_in_app):
				attributesJSON["seconds_in_app"] = seconds_in_app ?? NSNull()
				
			case .match_type(let match_type):
				attributesJSON["match_type"] = match_type ?? NSNull()
				
			case .channels(let channels):
				relationshipsJSON["channels"] = [
					"data": Array(channels).map { (channel) in
						return [
							"type": "channels",
							"id": channel.channel_id!,
						]
					}
				]
			}
		}
		
		let user_id: String = self.user_id
		JSONAPIRequest(url: RealmUser.specific_request_path(specific_id: user_id), method: .patch, parameters: [
			"data": [
				"id": user_id,
				"type": RealmUser.type,
				"attributes": attributesJSON,
				"relationships": relationshipsJSON,
			],
			], options: [
				.header("Authorization", UserManager.authorization),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(let error):
						return completion(error)
					case .success(let jsonAPIDocument):
						RealmDataController.shared.apply(jsonAPIDocument) { result in
							switch result {
							case .error(let error):
								return completion(error)
							case .success(_):
								return completion(nil)
							}
						}
					}
		}
	}
}

extension RealmUser {
	// 上次截图时间
	static var lastScreenShotTime: TimeInterval = 0
	// 是否可以进行截图
	func shouldUploadScreenShot() -> Bool {
		if self.is_banned == true {
			return false
		}
		
		if (Date().timeIntervalSince1970 - RealmUser.lastScreenShotTime) < 30 {
			return false
		}
		
		if self.gender == Gender.female.rawValue {
			return false
		}
		
		let random = Int.arc4random() % 2
		if random == 0 {
			return false
		}
		
		let randomAgeReduce = Int.arc4random() % 100
		if self.age <= 17, randomAgeReduce > RemoteConfigManager.shared.moderation_age_reduce {
			return false
		}
		
		let randomHourReduce = Int.arc4random() % 100
		if let hour = Date.init().component(.hour), hour > 8 && hour < 20, randomHourReduce > RemoteConfigManager.shared.moderation_non_peak {
			return false
		}
		
		return true
	}
}

