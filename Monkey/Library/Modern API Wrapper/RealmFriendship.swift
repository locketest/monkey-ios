//
//  RealmFriendship.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 9/11/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift
import ObjectMapper

class RealmFriendship: MonkeyModel {
	override class var type: String {
		return ApiType.Friendships.rawValue
	}
	override static func primaryKey() -> String {
		return "friendship_id"
	}
	
    dynamic var friendship_id: String!
    /// The other user
    dynamic var user: RealmUser?
    let messages = LinkingObjects(fromType: RealmMessage.self, property: "friendship")
    
    /// Can not be modified except by the other user
	dynamic var is_blocker: Bool = false
    // Editable by current user
	dynamic var is_blocking: Bool = false
    /// Can not be modified except by the other user
	dynamic var is_follower: Bool = false
    /// Editible
	dynamic var is_following: Bool = false
    /// Used to order conversations in the chat view
    dynamic var last_message_at: Date?
    /// Used to order conversations in the chat view
    dynamic var last_message_read_at: Date?
    /// Used to calculate "sent 3m ago" text
    dynamic var last_message_sent_at: Date?
    /// Used to calculate "received 3m ago" text
    dynamic var last_message_received_at: Date?
    /// Used to order the new friends view
    dynamic var created_at: Date?
    /// Determines sort order of friendships in the list
    dynamic var updated_at: Date?
    /// Toggles the current user's is_typing status.
	dynamic var is_typing: Bool = false
    /// Wether the other person is typing.
	dynamic var user_is_typing: Bool = false
	
	required convenience init?(map: Map) {
		if map["id"].currentValue == nil {
			return nil
		}
		self.init()
	}
}

extension RealmFriendship {
	
	enum Attribute {
		case last_message_read_at(Date?)
	}
	
	func update(attributes: [Attribute], completion: @escaping (_ error: APIError?) -> Void) {
		
		var attributesJSON = [String:Any]()
		for attribute in attributes {
			switch attribute {
			case .last_message_read_at(let lastMessageReadAt):
				attributesJSON["last_message_read_at"] = lastMessageReadAt?.iso8601 ?? NSNull()
			}
		}
		
		let friendship_id: String = self.friendship_id
		JSONAPIRequest(url: RealmFriendship.specific_request_path(specific_id: friendship_id), method: .patch, parameters: [
			"data": [
				"id": friendship_id,
				"type": RealmFriendship.type,
				"attributes": attributesJSON,
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
}
