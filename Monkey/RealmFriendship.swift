//
//  RealmFriendship.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 9/11/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift

class RealmFriendship: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "friendships"
	static let requst_subfix = RealmFriendship.type
	static let api_version = APIController.shared.apiVersion
    
    dynamic var friendship_id: String?
    /// The other user
    dynamic var user: RealmUser?
    let messages = LinkingObjects(fromType: RealmMessage.self, property: "friendship")
    
    /// Can not be modified except by the other user
    let is_blocker = RealmOptional<Bool>()
    // Editable by current user
    let is_blocking = RealmOptional<Bool>()
    /// Can not be modified except by the other user
    let is_follower = RealmOptional<Bool>()
    /// Editible
    let is_following = RealmOptional<Bool>()
    /// Used to order conversations in the chat view
    dynamic var last_message_at: NSDate?
    /// Used to order conversations in the chat view
    dynamic var last_message_read_at: NSDate?
    /// Used to calculate "sent 3m ago" text
    dynamic var last_message_sent_at: NSDate?
    /// Used to calculate "received 3m ago" text
    dynamic var last_message_received_at: NSDate?
    /// Used to order the new friends view
    dynamic var created_at: NSDate?
    /// Determines sort order of friendships in the list
    dynamic var updated_at: NSDate?
    /// Toggles the current user's is_typing status.
    let is_typing = RealmOptional<Bool>()
    /// Wether the other person is typing.
    let user_is_typing = RealmOptional<Bool>()
    
    override static func primaryKey() -> String {
        return "friendship_id"
    }
    
    enum Attribute {
        case last_message_read_at(NSDate?)
    }
    
    func update(attributes: [Attribute], completion: @escaping (_ error: APIError?) -> Void) {
        guard let friendshipId = self.friendship_id else {
            completion(APIError(code: "-1", status: nil, message: "Friendship ID must exist for updates."))
            return
        }
        
        var attributesJSON = [String:Any]()
        for attribute in attributes {
            switch attribute {
            case .last_message_read_at(let lastMessageReadAt):
                attributesJSON["last_message_read_at"] = lastMessageReadAt?.iso8601 ?? NSNull()
            }
        }
		
        JSONAPIRequest(url: "\(Environment.baseURL)/api/\(RealmFriendship.api_version)/\(RealmFriendship.requst_subfix)/\(friendshipId)", method: .patch, parameters: [
            "data": [
                "id": friendshipId,
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
