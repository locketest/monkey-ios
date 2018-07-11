//
//  TwopSocketModel.swift
//  Monkey
//
//  Created by fank on 2018/7/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class TwopSocketModel: NSObject {
	
	var msgIdString : String?
	
	var msgTypeInt : Int?
	
	var senderIdInt : Int?
	
	var contentString : String?
	
	var extDictModel : TwopSocketExtDictModel?
	
	class func twopSocketModel(dict:[String:AnyObject]) -> TwopSocketModel {
		
		let twopSocketModel = TwopSocketModel()
		
		twopSocketModel.msgIdString = dict["msg_id"] as? String
		twopSocketModel.msgTypeInt = dict["msg_type"] as? Int
		twopSocketModel.senderIdInt = dict["sender_id"] as? Int
		twopSocketModel.contentString = dict["content"] as? String
		
		if let extDict = dict["ext"] as? [String:AnyObject] {
			twopSocketModel.extDictModel = TwopSocketExtDictModel.twopSocketExtDictModel(dict: extDict)
		}
		
		return twopSocketModel
	}
	
}

class TwopSocketExtDictModel: NSObject {
	
	var friendIdInt : Int?
	
	var onlineBool : Bool?
	
	var friendshipIdString : String?
	
	var channelKeyString : String?
	
	var channelNameString : String?
	
	var expireTimeDouble : Double?
	
	class func twopSocketExtDictModel(dict:[String:AnyObject]) -> TwopSocketExtDictModel {
		
		let twopSocketExtDictModel = TwopSocketExtDictModel()
		
		twopSocketExtDictModel.friendIdInt = dict["friend_id"] as? Int
		twopSocketExtDictModel.onlineBool = dict["online"] as? Bool
		twopSocketExtDictModel.friendshipIdString = dict["friendship_id"] as? String
		twopSocketExtDictModel.channelKeyString = dict["channel_key"] as? String
		twopSocketExtDictModel.channelNameString = dict["channel_name"] as? String
		twopSocketExtDictModel.expireTimeDouble = dict["expire_time"] as? Double
		
		return twopSocketExtDictModel
	}
	
}
