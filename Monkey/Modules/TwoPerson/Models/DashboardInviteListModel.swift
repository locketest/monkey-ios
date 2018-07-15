//
//  DashboardInviteListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	INVITE FRIENDS ON MONKEY

import UIKit

class DashboardInviteListModel: NSObject {
	
	var userIdInt : Int?
	
	var nameString : String?
	
	var pathString : String?
	
	var genderString : String?
	
	var friendshipIdString : String?
	
	var nextInviteAtDouble : Double?
	
	var statusInt : Int?
	
	class func dashboardInviteListModel(userInfo:UsersInfoModel, friendsRequestModel:FriendsRequestModel?) -> DashboardInviteListModel {
		
		let dashboardInviteListModel = DashboardInviteListModel()
		
		dashboardInviteListModel.userIdInt = userInfo.userIdInt
		dashboardInviteListModel.nameString = userInfo.usernameString
		dashboardInviteListModel.pathString = userInfo.pathString
		dashboardInviteListModel.genderString = userInfo.genderString
		
		dashboardInviteListModel.friendshipIdString = friendsRequestModel?.userIdInt?.description
		dashboardInviteListModel.nextInviteAtDouble = friendsRequestModel?.nextInviteAtDouble
		dashboardInviteListModel.statusInt = friendsRequestModel?.statusInt
		
		return dashboardInviteListModel
	}
}
