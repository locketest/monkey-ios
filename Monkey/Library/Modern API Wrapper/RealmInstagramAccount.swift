//
//  RealmInstagramAccount.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/27/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

class RealmInstagramAccount: MonkeyModel {
	
	override class var type: String {
		return ApiType.Instagram_accounts.rawValue
	}
	override static func primaryKey() -> String {
		return "instagram_account_id"
	}
	
    let instagram_photos = List<RealmInstagramPhoto>()

    dynamic var instagram_account_id: String!
    dynamic var code: String?
    dynamic var username: String?
	
	required convenience init?(map: Map) {
		if map["id"].currentValue == nil {
			return nil
		}
		self.init()
	}
}
