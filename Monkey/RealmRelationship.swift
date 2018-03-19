//
//  RealmRelationship.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift

class RealmRelationship: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "relationships"
	static let api_version = APIController.shared.apiVersion
    
    dynamic var relationship_id: String?
    /// The other user
    dynamic var user: RealmUser?
//    let messages = LinkingObjects(fromType: RealmMessage.self, property: "relationship")
    
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
    /// Determines sort order of relationships in the list
    dynamic var updated_at: NSDate?
    /// Toggles the current user's is_typing status.
    let is_typing = RealmOptional<Bool>()
    /// Wether the other person is typing.
    let user_is_typing = RealmOptional<Bool>()
    
    override static func primaryKey() -> String {
        return "relationship_id"
    }
    
    enum Attribute {
        case last_message_read_at(NSDate?)
    }
    
    func update(attributes: [Attribute], completion: @escaping (_ error: APIError?) -> Void) {
        guard let relationship_id = self.relationship_id else {
            completion(APIError(code: "-1", status: nil, message: "Relationship ID must exist for updates."))
            return
        }
        
        var attributesJSON = [String:Any]()
        for attribute in attributes {
            switch attribute {
            case .last_message_read_at(let last_message_read_at):
                attributesJSON["last_message_read_at"] = last_message_read_at?.iso8601 ?? NSNull()
            }
        }
        
        let type = type(of: self).type
        JSONAPIRequest(url: "\(Environment.baseURL)/api/\(APIController.shared.apiVersion)/\(type)/\(relationship_id)", method: .patch, parameters: [
            "data": [
                "id": relationship_id,
                "type": type,
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
