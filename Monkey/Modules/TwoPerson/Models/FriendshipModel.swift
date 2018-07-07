//
//  FriendshipModel.swift
//  Monkey
//
//  Created by fank on 2018/6/25.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	Dashboard 第一个接口返回的好友列表

import UIKit

class FriendshipModel: NSObject {
	
	var friendIdString : String?
	
	var friendshipIdString : String?
	
	class func friendshipModel(dict:[String:AnyObject]) -> FriendshipModel {
		
		let friendshipModel = FriendshipModel()
		
		friendshipModel.friendIdString = (dict["friend_id"] as? Int)?.description
		friendshipModel.friendshipIdString = dict["friendship_id"] as? String
		
		return friendshipModel
	}

}
