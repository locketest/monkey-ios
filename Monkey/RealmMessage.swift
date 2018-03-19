//
//  RealmMessage.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift

class RealmMessage: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "messages"
	static let requst_subfix = RealmMessage.type
	static let api_version = APIController.shared.apiVersion
    
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
    
    dynamic var updated_at: NSDate?
    
    dynamic var created_at: NSDate?
    
    var parsedData: Data? {
        guard let base64EncodedString = self.data else {
            return nil
        }
        return Data(base64Encoded: base64EncodedString)
    }
    
    override static func primaryKey() -> String {
        return "message_id"
    }
}

