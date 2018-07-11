//
//  TwopNotificationCenter.swift
//  Monkey
//
//  Created by fank on 2018/7/10.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

public let MessageIdArrayTag = "MessageIdArray"

public let AcceptPairNotificationTag = "AcceptPairNotification"

public let FriendPairNotificationTag = "FriendPairNotification"

public let InviteFriendsNotificationTag = "InviteFriendsNotification"

class TwopNotificationCenter: NSObject {
	
	let userDefault = UserDefaults.standard
	
	let notificationCenter = NotificationCenter.default
	
	init(userInfo: [String: Any]?, isBackgrounded: Bool) {
		super.init()
		
		self.handleNotificationFunc(userInfo: userInfo, isBackgrounded: isBackgrounded)
	}
	
	func handleNotificationFunc(userInfo: [String: Any]?, isBackgrounded: Bool) {
		
		if userInfo == nil { return }
		
		let twopSocketModel = TwopSocketModel.twopSocketModel(dict: userInfo! as [String : AnyObject])
		
		switch twopSocketModel.msgTypeInt {
		case SocketDefaultMsgTypeEnum.friendInvite.rawValue: // friendInvite
			notificationCenter.post(name: NSNotification.Name(rawValue: InviteFriendsNotificationTag), object: [twopSocketModel, isBackgrounded])
		case SocketDefaultMsgTypeEnum.friendPair.rawValue: // friendPair
			notificationCenter.post(name: NSNotification.Name(rawValue: FriendPairNotificationTag), object: [twopSocketModel, isBackgrounded])
		case  SocketDefaultMsgTypeEnum.acceptFriendPair.rawValue: // acceptFriendPair
			notificationCenter.post(name: NSNotification.Name(rawValue: AcceptPairNotificationTag), object: [twopSocketModel, isBackgrounded])
		default:
			break
		}
	}
}
