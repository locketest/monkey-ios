//
//  PairListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/26.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	Dashboard 拿到第一个接口返回的id后，再请求的所有2p好友配对列表信息

import UIKit

class PairListModel: NSObject {
	
	var userIdInt : Int?
	
	var pairIdString : String?
	
	var inviteeIdInt : Int?
	
	var nextInviteAtDouble : Double?
	
	var inviteAtDouble : Double?
	
	var statusInt : Int?
	
	class func pairListModel(dict:[String:AnyObject]) -> PairListModel {
		
		let pairListModel = PairListModel()
		
		pairListModel.userIdInt = dict["user_id"] as? Int
		pairListModel.pairIdString = dict["pair_id"] as? String
		pairListModel.inviteeIdInt = dict["invitee_id"] as? Int
		pairListModel.nextInviteAtDouble = dict["next_invite_at"] as? Double
		pairListModel.inviteAtDouble = dict["invite_at"] as? Double
		pairListModel.statusInt = dict["status"] as? Int
		
		return pairListModel
	}
	
}
