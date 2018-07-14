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
	init(type: String?) {
		switch type {
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
		case MessageType.Background.rawValue:
			self = .Background
		case MessageType.Foreground.rawValue:
			self = .Foreground
		case MessageType.PceOut.rawValue:
			self = .PceOut
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
	case Confirm = "confirm"
	case Match = "Match"
	case PceOut = "pceout"
    case Background = "turntobackground"
	case Foreground = "turntoforeground"
	
	func supportSocket() -> Bool {
		switch self {
		case .Accept:
			fallthrough
		case.Skip:
			return true
		default:
			return false
		}
	}
}

class Message: NSObject, Mappable {
	var type: String = MessageType.Normal.rawValue
	var body: String = ""
	lazy var time = Date.init().timeIntervalSince1970
	
	var sender: Int?
	var parameter: String?
	var target: [Int]?
	
	// get type from type
	var messageType: MessageType {
		return MessageType.init(type: type)
	}
	
	var supportSocket: Bool {
		let type = self.messageType
		return type.supportSocket()
	}
	
	func messageJson() -> [String: Any] {
		var basicJson: [String: Any] = [
			"type": type,
			"body": body,
			"time": time,
		]
		if let sender = Int(UserManager.UserID ?? "0") {
			basicJson["sender"] = sender
		}
		if let target = target {
			basicJson["target"] = target
		}
		if let parameter = parameter {
			basicJson["parameter"] = parameter
		}
		return basicJson
	}
	
	required init?(map: Map) {
		if map["type"].currentValue == nil {
			return nil
		}
	}
	
	init(type: String) {
		super.init()
		self.type = type
	}
	
	func mapping(map: Map) {
		time <- map["time"]
		type <- map["type"]
		body <- map["body"]
		sender <- map["sender"]
		target <- map["target"]
		parameter <- map["parameter"]
	}
}

class MatchMessage: Message {
	var match_id: String?
	
	required init?(map: Map) {
		super.init(map: map)
	}
	
	override func messageJson() -> [String : Any] {
		var basicJson = super.messageJson()
		if let match_id = match_id {
			basicJson["match_id"] = match_id
		}
		return basicJson
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
		match_id <- map["match_id"]
	}
}

class TextMessage: MatchMessage {
	static let minmumHeight: CGFloat = 21
	static let maxmumWidth: CGFloat = UIScreen.main.bounds.size.width - 20 - 16
	var direction: MessageDirection {
		if let sender = self.sender, let current_user = UserManager.UserID, sender == Int(current_user) {
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
		self.type = MessageType.Text.rawValue
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
	}
}

