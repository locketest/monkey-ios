//
//  PairListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/26.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	Dashboard 拿到第一个接口返回的id后，再请求的所有2p好友配对列表信息

import UIKit

class PairListModel: NSObject {
	
	var idString : String?
	
	var friendshipId : String?
	
	var inviteeIdString : String?
	
	var timestampString : String?
	
	var statusString : String?
	
	class func pairListModel(dict:[String:AnyObject]) -> PairListModel {
		
		let pairListModel = PairListModel()
		
		pairListModel.idString = dict["id"] as? String
		pairListModel.friendshipId = dict["friendshipId"] as? String
		pairListModel.inviteeIdString = dict["inviteeId"] as? String
		pairListModel.timestampString = dict["timestamp"] as? String
		pairListModel.statusString = dict["status"] as? String
		
		return pairListModel
	}
	
}
