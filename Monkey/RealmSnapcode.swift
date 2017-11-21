//
//  RealmSnapcode.swift
//  Monkey
//
//  Created by Philip Bernstein on 9/12/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift
import Alamofire
import Amplitude_iOS

class RealmSnapcode: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "snapcodes"
    dynamic var snapcode_id:String?
    dynamic var svg:String?
    dynamic var snapchat_username:String?
    
    override static func primaryKey() -> String {
        return "snapcode_id"
    }
}

