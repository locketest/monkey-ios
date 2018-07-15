//
//  RealmMessage.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift
import ObjectMapper

class RealmMessage: MonkeyModel {
	override class var type: String {
		return ApiType.Messages.rawValue
	}
	override static func primaryKey() -> String {
		return "message_id"
	}
    
    dynamic var friendship: RealmFriendship?
    dynamic var sender: RealmUser?
    
    dynamic var message_id: String?
    /// URL to download the gif
    dynamic var text: String?
    /// Base 64 data
    dynamic var data: String?
    /// URL to download the gif
    dynamic var get_gif_url: String?
    /// text, gif, or drawing
    dynamic var type: String?
    /// client generated UUID. Used to match messages returned from the server with PendingMessages on the client
    dynamic var uuid: String?
    
    dynamic var updated_at: Date?
    
    dynamic var created_at: Date?
    
    var parsedData: Data? {
        guard let base64EncodedString = self.data else {
            return nil
        }
        return Data(base64Encoded: base64EncodedString)
    }
	
	required convenience init?(map: Map) {
		if map["id"].currentValue == nil {
			return nil
		}
		self.init()
	}
}

