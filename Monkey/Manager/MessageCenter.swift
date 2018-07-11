//
//  MessageCenter.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

@objc protocol MessageObserver: class, NSObjectProtocol {
	// 在状态 2 收到的 match
	@objc optional func didReceiveOnepMatch(match: MatchModel)
	@objc optional func didReceiveTwopMatch(match: MatchModel)
	
	// 收到房间消息
	@objc optional func didReceiveRoomMessage(action: String, in chat: String)
	// 收到对 match 的操作
	@objc optional func didReceiveSkip(in chat: String)
	@objc optional func didReceiveAccept(in chat: String)
	
	// friend 发生改变
	@objc optional func didReceiveFriendAdded()
	@objc optional func didReceiveFriendRemoved()
	@objc optional func didReceiveFriendInvite()
	
	// 收到对方的 video call
	@objc optional func didReceiveVideoCall(call: VideoCallModel)
	@objc optional func didReceiveCallCancel(call: String)
	
	// 收到 pair 消息
	@objc optional func didReceiveTwopDefault(message: [String: Any])
	
	// 收到好友聊天消息
	@objc optional func didReceiveConversationMessage()
	// 收到被举报消息
	@objc optional func didReceiveReportedMessage(url: String)
	
	// 未知消息类型
	@objc optional func didReceiveUnknowMessage(message: [String: Any], channel: String)
}

class MessageCenter {
	
	static let shared = MessageCenter()
	private init() {}
	
	// 消息回调处理
	private let safe_queue = DispatchQueue(label: "com.monkey.cool.SafeMessageObserverQueue", attributes: .concurrent)
	private var observers: WeakSet<MessageObserver> = WeakSet<MessageObserver>()
	
	func addMessageObserver(observer: MessageObserver) {
		safe_queue.async {
			self.observers.add(observer)
		}
	}
	
	func delMessageObserver(observer: MessageObserver) {
		safe_queue.async {
			self.observers.remove(observer)
		}
	}
	
	func send(message: [String: Any], to channel: SocketChannel) {
		Socket.shared.send(message: message, to: channel.rawValue)
		LogManager.shared.addLog(type: .SendSocketMessage, subTitle: channel.rawValue, info: message)
	}
	
	func handle(message: [String: Any], from channel: SocketChannel) {
		
		var messageInfo = JSONAPIDocument.init(json: message)
		var messageObject: Any? = nil

		// handle some message data
		switch channel {
		case .match_receive:
			var match_info = messageInfo.dataResource?.attributes
			// 设置 match 属性
			if let meta = messageInfo.meta, let next_fact = meta["next_fact"] as? String {
				match_info?["next_fact"] = next_fact
			}
			
			if let match_data = messageInfo.dataResource?.json, let match_id = match_data["id"] as? String {
				match_info?["id"] = match_id
			}
			
			// 更正 match 结构
			if let match_relationships = messageInfo.dataResource?.relationships {
				if let user_info = match_relationships["user"] as? [String: Any], let user_id = user_info["id"] as? String {
					// 设置 match 到的 user_id
					match_info?["user_id"] = user_id
					
					// 配置 json，使 includes 可用
					if let user_data = user_info["data"] as? [String: Any] {
						var include = user_data // 构造 user 字典
						var user_attributes = user_data["attributes"] as? [String: Any] ?? [String: Any]() // 构造 user 属性
						// 构造 user 外键关系
						var user_relationships = [String: Any]()
						// user channesl
						if let channels = user_attributes["channels"] as? [String] {
							// make channels with user's channels
							let channels_info = channels.flatMap { (channel_id) -> [String: String]? in
								return [
									"type": "channels",
									"id": channel_id,
									]
							}
							user_relationships["channels"] = ["data": channels_info]
						}
						
						// user instagram_account
						if let instagram_account = user_attributes["instagram_account_id"] as? String {
							user_relationships["instagram_account"] = ["data": [
								"type": "instagram_accounts",
								"id": instagram_account,
								]]
						}
						include["relationships"] = user_relationships
						
						// 构造新的 JsonApiDocument
						var new_message_info = messageInfo.json
						var new_match_relationships = match_relationships
						new_match_relationships["user"] = user_data
						new_message_info["relationships"] = new_match_relationships
						new_message_info["included"] = [include]
						messageInfo = JSONAPIDocument.init(json: new_message_info)
					}
				}
				
				// 设置 match 的 channel
				if let channels_info = match_relationships["channels"] as? [String: Any], let channels = channels_info["data"] as? [[String: Any]], let user_channel = channels.first, let channel_id = user_channel["id"] as? String {
					match_info?["channel_id"] = channel_id
				}
				
				if let channel_info = match_relationships["channel"] as? [String: Any], let channel_id = channel_info["id"] as? String {
					match_info?["channel_id"] = channel_id
				}
			}
			
			// 根据 match attributes 构造 match 对象
			if let match_info = match_info, let matchModel = Mapper<MatchModel>().map(JSON: match_info) {
				messageObject = matchModel
				// 设置 match_user 属性
				
			}
			break
		case .call_receive:
			// call_id
			var call_info = messageInfo.dataResource?.attributes
			if let call_data = messageInfo.dataResource?.json, let match_id = call_data["id"] as? String {
				call_info?["id"] = match_id
			}
			
			// call_relationships
			if let call_relationships = messageInfo.dataResource?.relationships {
				// 构造新的 json 和 document
				var new_message_info = messageInfo.json
				var new_call_relationships = call_relationships
				
				// 设置 match 到的 user_id
				if let user_info = call_relationships["user"] as? [String: Any], let user_id = user_info["id"] as? String {
					call_info?["user_id"] = user_id
					new_call_relationships["user"] = [
						"id": user_id,
						"type": RealmUser.type,
					]
				}
				
				// 设置 match 到的 initiator
				if let initiator_info = call_relationships["initiator"] as? [String: Any], let initiator_id = initiator_info["id"] as? String {
					call_info?["initiator_id"] = initiator_id
					new_call_relationships["initiator"] = [
						"id": initiator_id,
						"type": RealmUser.type,
					]
				}
				
				// 设置 match 到的 friendship_id
				if let friendship_id = call_relationships["friendship_id"] as? String {
					call_info?["friendship_id"] = friendship_id
					new_call_relationships["friendship"] = [
						"id": friendship_id,
						"type": RealmFriendship.type,
					]
				}
				
				new_message_info["relationships"] = new_call_relationships
				messageInfo = JSONAPIDocument.init(json: new_message_info)
			}
			
			// 根据 call attributes 构造 match 对象
			if let call_info = call_info, let callModel = Mapper<VideoCallModel>().map(JSON: call_info) {
				messageObject = callModel
				// 设置 user 属性
				
			}
			break
		case .reported:
			fallthrough
		case .match_outroom:
			fallthrough
		case .call_outroom:
			fallthrough
		case .call_cancel:
			fallthrough
		case .friend_deleted:
			fallthrough
		case .friend_new:
			fallthrough
		case .friend_chat:
			fallthrough
		case .json_api:
			fallthrough
		case .twop_default:
			fallthrough
		default:
			break
		}
		
		RealmDataController.shared.apply(messageInfo) { (_) in
			if messageObject == nil {
				messageObject = messageInfo
			}
			self.dispatch(object: messageObject, message: message, from: channel)
		}
	}
	
	func dispatch(object: Any?, message: [String: Any], from channel: SocketChannel) {
		// dispatch message data to observer(on main queue)
		var selector = #selector(MessageObserver.didReceiveUnknowMessage(message:channel:))
		// perform selector with objects
		var object1: Any?
		
		switch channel {
		case .match_outroom:
			if let attribute = message["attributes"] as? [String: Any], let action = attribute["match_action"] as? String, let send_time = attribute["send_time"] as? TimeInterval, send_time != 0 {
				let currentTime = Date.init().timeIntervalSince1970
				let duration = Int(ceil(currentTime - send_time))
				var session = "7+"
				if duration < 8 {
					session = "\(duration)"
				}
				
				AnalyticsCenter.log(withEvent: .matchReceiveSocket, andParameter: [
					"session": session,
					"receive_action": action,
					])
			}
//			selector = #selector(MessageObserver.didReceiveRoomMessage(action:in:))
			fallthrough
		case .call_outroom:
//			selector = #selector(MessageObserver.didReceiveRoomMessage(action:in:))
			if let objectDocument = object as? JSONAPIDocument, let objectAttributes = objectDocument.dataResource?.attributes, let action = objectAttributes["action"] as? String, let chat_id = objectAttributes["chat_id"] as? String {
				object1 = chat_id
				if action == MessageType.Accept.rawValue {
					selector = #selector(MessageObserver.didReceiveAccept(in:))
				}else {
					selector = #selector(MessageObserver.didReceiveSkip(in:))
				}
			}
			break
		case .match_receive:
			object1 = object
			if let match = object as? MatchModel, match.pair() == true {
				selector = #selector(MessageObserver.didReceiveTwopMatch(match:))
			}else {
				selector = #selector(MessageObserver.didReceiveOnepMatch(match:))
			}
			break
		case .call_receive:
			object1 = object
			selector = #selector(MessageObserver.didReceiveVideoCall(call:))
			break
		case .call_cancel:
			selector = #selector(MessageObserver.didReceiveCallCancel(call:))
			if let objectDocument = object as? JSONAPIDocument, let chat_id = objectDocument.dataResource?.id {
				object1 = chat_id
			}else {
				object1 = channel.rawValue
			}
			break
		case .reported:
			selector = #selector(MessageObserver.didReceiveReportedMessage(url:))
			if let objectDocument = object as? JSONAPIDocument, let upload_url = objectDocument.dataResource?.attributes?["upload_url"] as? String {
				object1 = upload_url
			}else {
				object1 = channel.rawValue
			}
			break
		case .friend_deleted:
			selector = #selector(MessageObserver.didReceiveFriendAdded)
			break
		case .friend_new:
			selector = #selector(MessageObserver.didReceiveFriendRemoved)
			break
		case .friend_chat:
			selector = #selector(MessageObserver.didReceiveConversationMessage)
			break
		case .json_api:
			break
		case .twop_default:
			object1 = message
			selector = #selector(MessageObserver.didReceiveTwopDefault(message:))
			break
		default:
			break
		}
		
		let observers = self.observers
		observers.forEach({ (observer) in
			if observer.responds(to: selector) {
				if selector == #selector(MessageObserver.didReceiveUnknowMessage(message:channel:)) {
					observer.didReceiveUnknowMessage?(message: message, channel: channel.rawValue)
				}else if object1 == nil {
					observer.perform(selector)
				}else {
					observer.perform(selector, with: object1)
				}
			}
		})
	}
}

extension MessageCenter: SocketMessageHandler {
	public func receive(message: [String: Any], from channel: String) {
		self.handle(message: message, from: SocketChannel.init(channel: channel))
		LogManager.shared.addLog(type: .ReceiveSocketMessage, subTitle: channel, info: message)
	}
}
