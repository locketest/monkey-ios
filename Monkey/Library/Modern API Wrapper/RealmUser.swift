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
	
	var age = RealmOptional<Int>()
	var bananas = RealmOptional<Int>()
    
    var delete_at = RealmOptional<Double>()
	
//	var online = RealmOptional<Bool>()
//	var enabled_two_p = RealmOptional<Bool>()
//	var unlocked_two_p = RealmOptional<Bool>()
//	var two_p_user_group_type = RealmOptional<Int>() // 1 planA, 2planB
//	var match_type = RealmOptional<Int>() // 1 1p, 2 2p
	
	var seconds_in_app = RealmOptional<Int>()
	
	var facebook_friends_invited = RealmOptional<Int>()
	var is_snapcode_uploaded = RealmOptional<Bool>()
	var is_admin = RealmOptional<Bool>()
	var is_banned = RealmOptional<Bool>()
	
	var latitude = RealmOptional<Double>()
	var longitude = RealmOptional<Double>()
	dynamic var state: String?
	dynamic var address: String?
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
	
	dynamic var instagram_account_id: String?
	dynamic var instagram_account: RealmInstagramAccount?
	
	var channels = List<RealmChannel>()
	let friendships = LinkingObjects(fromType: RealmFriendship.self, property: "user")
	
	func isCompleteProfile() -> Bool {
		var isCompleteProfile = true
		// birth_date 和 gender 没有视为资料不完善
		if self.birth_date == nil || self.gender == nil {
			isCompleteProfile = false
		}
		return isCompleteProfile
	}
	
	func isAmerican() -> Bool {
		var isAmerican = false
		if self.location == "United States" {
			isAmerican = true
		}
		return isAmerican
	}
	
	func isMonkeyKing() -> Bool {
		var isMonkeyKing = false
		if self.user_id == "2" {
			isMonkeyKing = true
		}
		return isMonkeyKing
	}
	
	static var lastScreenShotTime: TimeInterval = 0
	func shouldUploadScreenShot() -> Bool {
		if is_banned.value == true {
			return false
		}
		
		if (Date().timeIntervalSince1970 - RealmUser.lastScreenShotTime) < 30 {
			return false
		}
		
		if gender == Gender.female.rawValue {
			return false
		}
		
		let random = Int.arc4random() % 2
		if random == 0 {
			return false
		}
		
		let randomAgeReduce = Int.arc4random() % 100
		if let age = age.value, age <= 17, randomAgeReduce > RemoteConfigManager.shared.moderation_age_reduce {
			return false
		}
		
		let randomHourReduce = Int.arc4random() % 100
		if let hour = Date.init().component(.hour), hour > 8 && hour < 20, randomHourReduce > RemoteConfigManager.shared.moderation_non_peak {
			return false
		}
		
		return true
	}
	
	/// Each Attribute case corresponds to a User attribute that can be updated/modified.
	enum Attribute {
		case gender(String?)
		case show_gender(String?)
		
		case latitude(Double?)
		case longitude(Double?)
		case address(String?)
		
		case first_name(String?)
		case snapchat_username(String?)
		
		case birth_date(NSDate?)
		case seconds_in_app(Int?)
		
		case channels(List<RealmChannel>)
	}
	
	/**
	Updates user information both backend and frontend
	
	- parameter attributes: An array of Attribute items to update.
	- parameter callback: Called whent the request completes.
	- parameter error: The error encountered.
	*/
	func update(attributes: [Attribute], completion: @escaping (_ error: APIError?) -> Void) {
		guard let user_id = self.user_id else {
			completion(APIError(code: "-1", status: nil, message: "User ID must exist for updates."))
			return
		}
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
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/\(RealmUser.api_version.rawValue)/\(RealmUser.requst_subfix)/\(user_id)", method: .patch, parameters: [
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
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
	}
}
