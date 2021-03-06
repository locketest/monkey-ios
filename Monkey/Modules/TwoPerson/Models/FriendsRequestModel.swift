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
	
	var genderString : String?
	
	// 非手动拼接字段
	var userIdInt : Int?
	
	var inviteeIdInt : Int?
	
	var inviteAtDouble : Double?
	
	var nextInviteAtDouble : Double?
	
	var statusInt : Int?
	
	class func friendsRequestModel(dict:[String:AnyObject], user: RealmUser? = nil) -> FriendsRequestModel {
		
		let friendsRequestModel = FriendsRequestModel()
		
		if user != nil {
			friendsRequestModel.genderString = user!.gender
			friendsRequestModel.nameString = user!.first_name
			friendsRequestModel.pathString = user!.profile_photo_url
		}
		
		friendsRequestModel.userIdInt = dict["user_id"] as? Int
		friendsRequestModel.inviteeIdInt = dict["invitee_id"] as? Int
		friendsRequestModel.inviteAtDouble = dict["invite_at"] as? Double
		friendsRequestModel.nextInviteAtDouble = dict["next_invite_at"] as? Double
		friendsRequestModel.statusInt = dict["status"] as? Int
		
		return friendsRequestModel
	}
}
