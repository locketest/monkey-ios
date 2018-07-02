//
//  FriendsRequestModel.swift
//  Monkey
//
//  Created by fank on 2018/6/13.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
// plan AB页，第一个section模型

import UIKit

class FriendsRequestModel: NSObject {
	
	var nameString : String?
	
	var pathString : String?
	
	// 非手动拼接字段
	var idString : String?
	
	var friendshipIdString : String?
	
	var inviteeIdString : String?
	
	var timestampDouble : Double?
	
	var statusInt : Int?
	
	class func friendsRequestModel(dict:[String:AnyObject], nameString:String?, pathString:String?) -> FriendsRequestModel {
		
		let friendsRequestModel = FriendsRequestModel()
		
		friendsRequestModel.nameString = nameString
		friendsRequestModel.pathString = pathString
		
		friendsRequestModel.idString = dict["id"] as? String
		friendsRequestModel.friendshipIdString = dict["friendshipId"] as? String
		friendsRequestModel.inviteeIdString = dict["inviteeId"] as? String
		friendsRequestModel.timestampDouble = dict["timestamp"] as? Double
		friendsRequestModel.statusInt = dict["status"] as? Int
		
		return friendsRequestModel
	}
}
