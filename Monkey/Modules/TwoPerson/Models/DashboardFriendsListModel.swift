//
//  DashboardFriendsListModel.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	2P CHAT FRIEND LIST

import UIKit

class DashboardFriendsListModel: NSObject {
	
	var idString : String?
	
	var nameString : String?
	
	var pathString : String?
	
	var onlineString : String?
	
	var inviteeIdString : String?
	
	var friendshipIdString : String?
	
	var isMissedBool: Bool?
	
	var timestampDouble : Double?
	
	var statusInt : Int?
	
	class func dashboardFriendsListModel(userInfo:UsersInfoModel, friendsRequestModel:FriendsRequestModel, isMissedBool:Bool = false) -> DashboardFriendsListModel {
		
		let dashboardFriendsListModel = DashboardFriendsListModel()
		
		dashboardFriendsListModel.idString = userInfo.idString
		dashboardFriendsListModel.nameString = userInfo.usernameString
		dashboardFriendsListModel.pathString = userInfo.pathString
		dashboardFriendsListModel.onlineString = userInfo.onlineStatusString
		
		dashboardFriendsListModel.isMissedBool = isMissedBool
		
		dashboardFriendsListModel.friendshipIdString = friendsRequestModel.friendshipIdString
		dashboardFriendsListModel.inviteeIdString = friendsRequestModel.inviteeIdString
		dashboardFriendsListModel.timestampDouble = friendsRequestModel.timestampDouble
		dashboardFriendsListModel.statusInt = friendsRequestModel.statusInt
		
		return dashboardFriendsListModel
	}
}
