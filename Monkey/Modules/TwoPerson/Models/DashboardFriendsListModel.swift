//
//  DashboardFriendsListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	2P CHAT FRIEND LIST

import UIKit

class DashboardFriendsListModel: NSObject {
	
	var userIdInt : Int?
	
	var nameString : String?
	
	var pathString : String?
	
	var genderString : String?
	
	var onlineStatusBool : Bool? // 在线状态
	
	var inviteeIdInt : Int?
	
//	var friendshipIdString : String?
	
	var isMissedBool: Bool?
	
	var nextInviteAtDouble : Double?
	
	var statusInt : Int?
	
	class func dashboardFriendsListModel(userInfo:UsersInfoModel, pairListModel:PairListModel? = nil, isMissedBool:Bool = false) -> DashboardFriendsListModel {
		
		let dashboardFriendsListModel = DashboardFriendsListModel()
		
		dashboardFriendsListModel.userIdInt = userInfo.userIdInt
		dashboardFriendsListModel.nameString = userInfo.usernameString
		dashboardFriendsListModel.pathString = userInfo.pathString
		dashboardFriendsListModel.genderString = userInfo.genderString
		dashboardFriendsListModel.onlineStatusBool = userInfo.onlineStatusBool
		
		dashboardFriendsListModel.isMissedBool = isMissedBool
		
//		dashboardFriendsListModel.friendshipIdString = pairListModel.userIdInt?.description
		dashboardFriendsListModel.inviteeIdInt = pairListModel?.inviteeIdInt
		dashboardFriendsListModel.nextInviteAtDouble = pairListModel?.nextInviteAtDouble
		dashboardFriendsListModel.statusInt = pairListModel?.statusInt
		
		return dashboardFriendsListModel
	}
}
