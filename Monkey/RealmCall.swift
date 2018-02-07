//
//  RealmCall.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/8/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class RealmCall: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "chats"
    
    dynamic var chat_id: String?
    
    dynamic var session_id: String?
    dynamic var status: String?
    dynamic var token: String?
    dynamic var bio: String?
    dynamic var created_at: NSDate?
	
	dynamic var match_mode: String?
    dynamic var user: RealmUser?
    dynamic var friendship: RealmFriendship?
    dynamic var initiator: RealmUser?
    
    override static func primaryKey() -> String {
        return "chat_id"
    }
}
