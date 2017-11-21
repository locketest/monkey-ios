//
//  RealmInstagramAccount.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/27/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift

class RealmInstagramAccount: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "instagram_accounts"
    let instagram_photos = List<RealmInstagramPhoto>()

    dynamic var instagram_account_id: String?
    dynamic var code: String?
    dynamic var username: String?

    dynamic var user: RealmUser?
    
    override static func primaryKey() -> String {
        return "instagram_account_id"
    }
}
