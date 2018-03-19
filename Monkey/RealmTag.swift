//
//  RealmTag.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import Alamofire

class RealmTag: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "tags"
	static let api_version = APIController.shared.apiVersion
    
    // MARK: Experiment strings
    
    /// The text of the hashtag without the # character.
    dynamic var name:String?
    
    /// The user_id that authenticated the request for this Experiment.
    dynamic var tag_id: String?
    
    // MARK: Tag strings
    override static func primaryKey() -> String {
        return "tag_id"
    }
}
