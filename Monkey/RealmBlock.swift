//
//  RealmBlock.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 9/6/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class RealmBlock: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "blocks"
	static let api_version = APIController.shared.apiVersion
    
    dynamic var block_id:String?
    dynamic var blocked_user:RealmUser?
    dynamic var created_at:NSDate?

    override static func primaryKey() -> String {
        return "block_id"
    }
}
