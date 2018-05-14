//
//  RealmChannel.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/17/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Alamofire
import RealmSwift
import ObjectMapper

class RealmChannel: MonkeyModel {
	
	override class var type: String {
		return ApiType.Channels.rawValue
	}
	override static func primaryKey() -> String {
		return "channel_id"
	}
    
    dynamic var channel_id: String?
    /// The channel title.
    dynamic var title: String?
    /// The channel subtitle such as "302 online now"
    dynamic var subtitle: String?
    /// text, gif, or drawing
    dynamic var emoji: String?
    /// How many people are online in the channel.
    let users_online = RealmOptional<Int>()
    /// How many people are online in the channel.
    let is_active = RealmOptional<Bool>()
    /// Used to sort the channels.
    dynamic var updated_at: NSDate?
    /// The date the channel was created.
    dynamic var created_at: NSDate?
	
	required convenience init?(map: Map) {
		self.init()
	}
}
