//
//  RealmInstagramPhoto.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/27/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import ObjectMapper

class RealmInstagramPhoto: MonkeyModel {
	override class var type: String {
		return ApiType.Instagram_photos.rawValue
	}
	override static func primaryKey() -> String {
		return "instagram_photo_id"
	}
	
    dynamic var instagram_photo_id: String?
    dynamic var standard_resolution_image_url: String?
	
	required convenience init?(map: Map) {
		self.init()
	}
}
