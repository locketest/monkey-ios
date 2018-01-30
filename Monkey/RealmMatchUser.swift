//
//  RealmMatchUser.swift
//  Monkey
//
//  Created by YY on 2018/1/29.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift

class RealmMatchedUser: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "matchedUser"
    
    dynamic var id: String?
    
    dynamic var gender:String?
    dynamic var snapchat_username:String?
    dynamic var first_name:String?
    dynamic var location:String?
//    dynamic var channels:RLMArray<String>?
    let age = RealmOptional<Int>()
    dynamic var birth_date: NSDate?
    
    override static func primaryKey() -> String {
        return "id"
    }
}
