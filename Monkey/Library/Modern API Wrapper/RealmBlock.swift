//
//  RealmBlock.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 9/6/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import ObjectMapper

class RealmBlock: MonkeyModel {
	override class var type: String {
		return ApiType.Blocks.rawValue
	}
	override static func primaryKey() -> String {
		return "block_id"
	}
	
    dynamic var block_id: String?
    dynamic var created_at: NSDate?
	
	required convenience init?(map: Map) {
		self.init()
	}
}
