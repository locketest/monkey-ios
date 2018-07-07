//
//  PairListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/26.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	Dashboard 拿到第一个接口返回的id后，再请求的所有2p好友配对列表信息

import UIKit

class PairListModel: NSObject {
	
	var userIdString : String?
	
	var pairIdString : String?
	
	var inviteeIdString : String?
	
	var nextInviteAtDouble : Double?
	
	var statusInt : Int?
	
	class func pairListModel(dict:[String:AnyObject]) -> PairListModel {
		
		let pairListModel = PairListModel()
		
		pairListModel.userIdString = dict["user_id"] as? String
		pairListModel.pairIdString = dict["pair_id"] as? String
		pairListModel.inviteeIdString = dict["invitee_id"] as? String
		pairListModel.nextInviteAtDouble = dict["next_invite_at"] as? Double
		pairListModel.statusInt = dict["status"] as? Int
		
		return pairListModel
	}
	
}
