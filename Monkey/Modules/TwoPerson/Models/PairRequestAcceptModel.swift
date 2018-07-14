//
//  PairRequestAcceptModel.swift
//  Monkey
//
//  Created by fank on 2018/7/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class PairRequestAcceptModel: NSObject {

	var userIdInt : Int?
	
	var pairIdString : String?
	
	var inviteeIdString : Int?
	
	var nextInviteAtDouble : Double?
	
	var channelKeyString : String?
	
	var channelNameString : String?
	
	var statusInt : Int?
	
	class func pairRequestAcceptModel(dict:[String:AnyObject]) -> PairRequestAcceptModel {
		
		let pairRequestAcceptModel = PairRequestAcceptModel()
		
		pairRequestAcceptModel.userIdInt = dict["user_id"] as? Int
		pairRequestAcceptModel.pairIdString = dict["pair_id"] as? String
		pairRequestAcceptModel.inviteeIdString = dict["invitee_id"] as? Int
		pairRequestAcceptModel.nextInviteAtDouble = dict["next_invite_at"] as? Double
		pairRequestAcceptModel.channelKeyString = dict["channel_key"] as? String
		pairRequestAcceptModel.channelNameString = dict["channel_name"] as? String
		pairRequestAcceptModel.statusInt = dict["status"] as? Int
		
		return pairRequestAcceptModel
	}
	
}
