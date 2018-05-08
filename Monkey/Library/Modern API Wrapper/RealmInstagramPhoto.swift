//
//  RealmInstagramPhoto.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/27/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class RealmInstagramPhoto: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "instagram_photos"
	static let requst_subfix = RealmInstagramPhoto.type
	static let api_version = APIController.shared.apiVersion
    
    dynamic var instagram_photo_id: String?
    dynamic var standard_resolution_image_url: String?
    
    dynamic var instagram_account: RealmInstagramAccount?
    
    override static func primaryKey() -> String {
        return "instagram_photo_id"
    }
}
