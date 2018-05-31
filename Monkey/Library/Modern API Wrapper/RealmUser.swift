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
				.header("Authorization", APIController.authorization),
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

		age <- (map["age"], RealmOptionalTypeCastTransform())
		if age.value == nil || age.value == 0 {
			age <- (map["attributes.age"], RealmOptionalTypeCastTransform())
		}
		bananas <- (map["bananas"], RealmOptionalTypeCastTransform())
		if bananas.value == nil || bananas.value == 0 {
			bananas <- (map["attributes.bananas"], RealmOptionalTypeCastTransform())
		}

		seconds_in_app <- (map["seconds_in_app"], RealmOptionalTypeCastTransform())
		if seconds_in_app.value == nil || seconds_in_app.value == 0 {
			seconds_in_app <- (map["attributes.seconds_in_app"], RealmOptionalTypeCastTransform())
		}

		facebook_friends_invited <- (map["facebook_friends_invited"], RealmOptionalTypeCastTransform())
		is_snapcode_uploaded <- (map["is_snapcode_uploaded"], RealmOptionalTypeCastTransform())
		is_admin <- (map["is_admin"], RealmOptionalTypeCastTransform())
		is_banned <- (map["is_banned"], RealmOptionalTypeCastTransform())

		latitude <- (map["latitude"], RealmOptionalTypeCastTransform())
		longitude <- (map["longitude"], RealmOptionalTypeCastTransform())
		address <- map["address"]
		if seconds_in_app.value == nil || seconds_in_app.value == 0 {
			seconds_in_app <- (map["attributes.seconds_in_app"], RealmOptionalTypeCastTransform())
		}
		location <- map["location"]
		if location == nil {
			location <- map["attributes.location"]
		}

		gender <- map["gender"]
		if gender == nil {
			gender <- map["attributes.gender"]
		}
		show_gender <- map["show_gender"]
		if show_gender == nil {
			show_gender <- map["attributes.show_gender"]
		}

		first_name <- map["first_name"]
		if first_name == nil {
			first_name <- map["attributes.first_name"]
		}
		username <- map["username"]
		if username == nil {
			username <- map["attributes.username"]
		}
		snapchat_username <- map["snapchat_username"]
		if snapchat_username == nil {
			snapchat_username <- map["attributes.snapchat_username"]
		}

		profile_photo_url <- map["profile_photo_url"]
		if profile_photo_url == nil {
			profile_photo_url <- map["attributes.profile_photo_url"]
		}
		profile_photo_upload_url <- map["profile_photo_upload_url"]

		user_id <- map["id"]
		if user_id == nil {
			user_id <- map["user_id"]
		}
		birth_date <- (map["birth_date"], DateTransform())
		if birth_date == nil {
			birth_date <- (map["attributes.birth_date"], DateTransform())
		}
		updated_at <- (map["updated_at"], DateTransform())
		created_at <- (map["created_at"], DateTransform())
		last_online_at <- (map["last_online_at"], DateTransform())

		channels <- (map["channels"], RealmTypeCastTransform())
		if channels.count == 0 {
			channels <- (map["attributes.channels"], RealmTypeCastTransform())
		}
		instagram_account <- map["instagram_account"]
		if instagram_account == nil {
			instagram_account <- map["attributes.instagram_account"]
		}
	}
}
