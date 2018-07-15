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
	
	var isMissedBool: Bool?
	
	var nextInviteAtDouble : Double?
	
	var weightDouble : Double? // 排序权重
	
	var statusInt : Int?
	
	class func dashboardFriendsListModel(userInfo:UsersInfoModel, pairListModel:PairListModel? = nil) -> DashboardFriendsListModel {
		
		let dashboardFriendsListModel = DashboardFriendsListModel()
		
		dashboardFriendsListModel.userIdInt = userInfo.userIdInt
		dashboardFriendsListModel.nameString = userInfo.usernameString
		dashboardFriendsListModel.pathString = userInfo.pathString
		dashboardFriendsListModel.genderString = userInfo.genderString
		dashboardFriendsListModel.onlineStatusBool = userInfo.onlineStatusBool

		dashboardFriendsListModel.inviteeIdInt = pairListModel?.inviteeIdInt
		dashboardFriendsListModel.nextInviteAtDouble = pairListModel?.nextInviteAtDouble
		dashboardFriendsListModel.statusInt = pairListModel?.statusInt
		
		// 设置online状态、权重
		if let online = userInfo.onlineStatusBool, let nextInviteAt = dashboardFriendsListModel.nextInviteAtDouble, let statusInt = dashboardFriendsListModel.statusInt {
			
			dashboardFriendsListModel.isMissedBool = false
			
			if online { // 1 online
				
				dashboardFriendsListModel.weightDouble = nextInviteAt * SortWeight.online.rawValue
				
				if Tools.timestampIsExpiredFunc(timestamp: nextInviteAt).isExpired && statusInt == TwopChatRequestsStatusEnum.unhandle.rawValue {
					dashboardFriendsListModel.isMissedBool = true
				}
			} else if statusInt == 1 { // 1 pair接受过
				dashboardFriendsListModel.weightDouble = nextInviteAt * SortWeight.paired.rawValue
			} else if Tools.timestampIsExpiredFunc(timestamp: nextInviteAt).isExpired && statusInt == TwopChatRequestsStatusEnum.unhandle.rawValue { // timestamp过期了并且未操作就是missed，此处有漏洞，如果时间过期了就是负数，负数乘以miss的权重后会比other还小，如果有遇到，把other的系数改成负数负100即可。
				dashboardFriendsListModel.weightDouble = nextInviteAt * SortWeight.missed.rawValue
				dashboardFriendsListModel.isMissedBool = true
			} else {
				dashboardFriendsListModel.weightDouble = nextInviteAt * SortWeight.others.rawValue
			}
		} else {
			dashboardFriendsListModel.weightDouble = 0
		}
		
		return dashboardFriendsListModel
	}
}
