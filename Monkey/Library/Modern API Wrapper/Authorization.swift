//
//  Authorization.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/25.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

@objcMembers class DeepLinkInfo: MonkeyModel {
	override static func primaryKey() -> String {
		return "deep_link"
	}
	
	dynamic var deep_link = type
	dynamic var banana = 0
	dynamic var is_used = false
	dynamic var text: String?
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
		banana <- map["banana"]
		is_used <- map["is_used"]
		text <- map["text"]
	}
}

class Authorization: MonkeyModel {
	
	override static func primaryKey() -> String {
		return "environment"
	}
	
	override class var type: String {
		return "phone_auths"
	}
	
	override class var requst_subfix: String {
		return "auth/\(ApiType.Auth.rawValue)"
	}
	
	required convenience init?(map: Map) {
		if map["data.id"].currentValue == nil || map["data.attributes.token"].currentValue == nil || map["data.relationships.user.data.id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	dynamic var authorization_id: String!
	dynamic var action: String = "login"
	
	dynamic var country_code: String?
	dynamic var phone_number: String?
	dynamic var token: String!
	static let token_prefix: String = "Bearer "
	var auth_token: String {
		return Authorization.token_prefix + token
	}
	
	override static func ignoredProperties() -> [String] {
		return ["auth_token"]
	}
	
	dynamic var user_id: String!
	dynamic var environment: String! = Environment.environment.rawValue
	dynamic var deep_link: DeepLinkInfo?
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
		action <- map["data.action"]
		country_code <- map["data.attributes.country_code"]
		phone_number <- map["data.attributes.phone_number"]
		token <- map["data.attributes.token"]
		deep_link <- map["data.deep_link"]
		
		authorization_id <- map["data.id"]
		user_id <- map["data.relationships.user.data.id"]
	}
}

class AuthorizationTransform: TransformType {
	typealias Object = Authorization
	
	typealias JSON = [String: Any]
	
	func transformFromJSON(_ value: Any?) -> Authorization? {
		if let dataDic = value as? [String: Any], let authorization_id = dataDic["id"] as? String {
			var authorization: Authorization? = nil
			let dataDocument = JSONAPIDocument.init(json: dataDic)
			guard let dataResource = dataDocument.dataResource, let attributes = dataResource.attributes, let relationships = dataResource.relationships, let authorizationToken = attributes["token"] as? String, let userValue = relationships["user"] as? JSONAPIDocument, let user_id = userValue.dataResource?.id else {
				return nil
			}
			
			authorization = Authorization.init()
			authorization?.authorization_id = authorization_id
			authorization?.token = authorizationToken
			authorization?.user_id = user_id
			
			if let action = dataDocument.dataResource?.json["action"] as? String {
				authorization?.action = action
			}
			return authorization
		}
		return nil
	}
	
	func transformToJSON(_ value: Authorization?) -> [String : Any]? {
		guard let authorization = value else {
			return nil
		}
		return [
			"data": [
				"id": authorization.authorization_id,
				"action": authorization.action,
				"type": Authorization.type,
				"attributes": [
					"country_code": authorization.country_code,
					"phone_number": authorization.phone_number,
					"token": authorization.token,
				],
				"deep_link": authorization.deep_link?.toJSON() ?? [:],
				"relationships": [
					"user": [
						"data": [
							"id": authorization.user_id,
							"type": RealmUser.type,
						]
					]
				]
			]
		]
	}
}
