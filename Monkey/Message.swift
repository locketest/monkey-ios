//
//  Message.swift
//  Monkey
//
//  Created by 王广威 on 2018/2/6.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

enum MessageType: String {
	init?(type: String?) {
		guard let messageType = type else { return nil }
		
		switch messageType {
		case MessageType.Typing.rawValue:
			self = .Typing
		case MessageType.UnMute.rawValue:
			self = .UnMute
		case MessageType.Report.rawValue:
			self = .Report
		case MessageType.AddTime.rawValue:
			self = .AddTime
		case MessageType.AddFriend.rawValue:
			self = .AddFriend
		case MessageType.Accept.rawValue:
			self = .Accept
		case MessageType.Skip.rawValue:
			self = .Skip
		case MessageType.Match.rawValue:
			self = .Match
		case MessageType.Text.rawValue:
			self = .Text
		default:
			self = .Normal
		}
	}
	
	case Normal = "normal"
	case Typing = "typing"
	case UnMute = "unmute"
	case Report = "report"
	case AddTime = "request"
	case AddFriend = "snapchat_username"
	case Accept = "ready"
	case Skip = "skip"
	case Text = "text"
	case Match = "Match"
}

class Message: Mappable {
	var sender: String?
	var parameter: String?
	lazy var type: String = MessageType.Normal.rawValue
	lazy var body: String = ""
	lazy var time = Date.init().timeIntervalSince1970
	
	required init?(map: Map) {
		
	}
	
	func mapping(map: Map) {
		time <- map["time"]
		type <- map["type"]
		body <- map["body"]
		sender <- map["sender"]
		parameter <- map["parameter"]
	}
}

class MatchMessage: Message {
	var room: String?
	lazy override var type: String = MessageType.Match.rawValue
	
	required init?(map: Map) {
		super.init(map: map)
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
		room <- map["room"]
	}
}

class TextMessage: MatchMessage {
	lazy override var type: String = MessageType.Text.rawValue
	static let minmumHeight: CGFloat = 21
	static let maxmumWidth: CGFloat = UIScreen.main.bounds.size.width - 20 - 16
	var direction: MessageDirection {
		if let sender = self.sender, let current_user = APIController.shared.currentUser?.user_id, sender == current_user {
			return .Send
		}
		return .Received
	}
	
	override var body: String {
		didSet {
			let messageRect = self.body.boundingRect(forFont: UIFont.systemFont(ofSize: 17), constrainedTo: CGSize.init(width: TextMessage.maxmumWidth, height: TextMessage.maxmumWidth))
			textHeight = CGFloat(max(ceilf(Float(messageRect.size.height)), Float(TextMessage.minmumHeight)))
			
			if textHeight > TextMessage.minmumHeight {
				textWidth = TextMessage.maxmumWidth
			}else {
				let messageRect = self.body.boundingRect(forFont: UIFont.systemFont(ofSize: 17), constrainedTo: CGSize.init(width: TextMessage.maxmumWidth, height: TextMessage.maxmumWidth))
				textWidth = CGFloat(min(ceilf(Float(messageRect.size.width)), Float(TextMessage.maxmumWidth)))
			}
		}
	}
	
	var textHeight: CGFloat = 0
	var textWidth: CGFloat = 0
	
	required init?(map: Map) {
		super.init(map: map)
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
	}
}

