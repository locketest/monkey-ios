//
//  PushNotification.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class NotificationUserInfo {
	private let userInfo: [AnyHashable: Any]
	init(userInfo: [AnyHashable: Any]) {
		self.userInfo = userInfo
	}
	var aps: [AnyHashable: Any]? {
		return userInfo["aps"] as? [AnyHashable: Any]
	}
	var attachData: [AnyHashable: Any]? {
		var attachInfo = userInfo["data"] ?? aps?["data"]
		
		if attachInfo != nil, let attachString: String = attachInfo as? String, let attachData = attachString.data(using: .utf8) {
			
			let convertInfo = try? JSONSerialization.jsonObject(with: attachData, options: JSONSerialization.ReadingOptions.mutableContainers)
			if let convertDic = convertInfo, convertDic is [String: String] {
				attachInfo = convertDic
			}
		}
		return attachInfo as? [AnyHashable: Any]
	}
	var emoji: String? {
		return userInfo["e"] as? String
	}
	var inAppText: String? {
		return userInfo["t"] as? String
	}
	var alwaysOpenURL: Int? {
		return userInfo["a"] as? Int
	}
	var link: String? {
		return attachData?["link"] as? String
	}
	var urls: [String]? {
		return userInfo["u"] as? [String]
	}
	var displayTimeout: NSNumber? {
		return userInfo["i"] as? NSNumber
	}
	var notificationType: Int? {
		return userInfo["n"] as? Int
	}
	var sound: Int? {
		return userInfo["s"] as? Int
	}
	var source: String {
		return userInfo["src"] as? String ?? attachData?["source"] as? String ?? "other"
	}
}
