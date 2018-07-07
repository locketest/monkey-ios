//
//  UsersInfoModel.swift
//  Monkey
//
//  Created by fank on 2018/6/26.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	Dashboard 拿到第一个接口返回的id后，再请求所有的userInfo

import UIKit

class UsersInfoModel: NSObject {
	
	var idString : String?
	
	var usernameString : String?
	
	var genderString : String?
	
	var pathString : String?
	
	var unlock2pBool : Bool?
	
	var onlineStatusBool : Bool? // 在线状态
	
	var lastLoginTimeDouble : Double? // 上次登录的时间，排序用
	
	var contactInviteRemainTimeDouble : Double? // 1p好友可邀请剩余时间
	
	class func usersInfoModel(dict:[String:AnyObject]) -> UsersInfoModel {
		
		let usersInfoModel = UsersInfoModel()
		
		usersInfoModel.idString = dict["id"] as? String
		usersInfoModel.usernameString = dict["first_name"] as? String
		usersInfoModel.genderString = dict["gender"] as? String
		usersInfoModel.pathString = dict["photoUrl"] as? String
		usersInfoModel.unlock2pBool = dict["unlocked_two_p"] as? Bool
		usersInfoModel.onlineStatusBool = dict["online"] as? Bool
		usersInfoModel.lastLoginTimeDouble = dict["lastLoginTime"] as? Double
		usersInfoModel.contactInviteRemainTimeDouble = dict["contactInviteRemainTimes"] as? Double
		
		return usersInfoModel
	}
	
}
