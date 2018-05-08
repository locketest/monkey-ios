//
//  RealmVideoCall.swift
//  Monkey
//
//  Created by YY on 2018/3/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class RealmVideoCall: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "videocall"
    static let requst_subfix = "videocall"
    static let api_version = "v1.3"
    
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
