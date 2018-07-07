//
//  DashboardInviteListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	INVITE FRIENDS ON MONKEY

import UIKit

class DashboardInviteListModel: NSObject {
	
	var idString : String?
	
	var nameString : String?
	
	var pathString : String?
	
	var friendshipIdString : String?
	
	var timestampDouble : Double?
	
	var statusInt : Int?
	
	class func dashboardInviteListModel(userInfo:UsersInfoModel, friendsRequestModel:FriendsRequestModel) -> DashboardInviteListModel {
		
		let dashboardInviteListModel = DashboardInviteListModel()
		
		dashboardInviteListModel.idString = userInfo.idString
		dashboardInviteListModel.nameString = userInfo.usernameString
		dashboardInviteListModel.pathString = userInfo.pathString
		
		dashboardInviteListModel.friendshipIdString = friendsRequestModel.userIdInt?.description
		dashboardInviteListModel.timestampDouble = friendsRequestModel.nextInviteAtDouble
		dashboardInviteListModel.statusInt = friendsRequestModel.statusInt
		
		return dashboardInviteListModel
	}
}
