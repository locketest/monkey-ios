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
	
	func handle(messageDic: [String: Any], from channel: SocketChannel) {
		var messageDoc = JSONAPIDocument.init(json: messageDic)
		var messageObject: Any? = nil

		// handle some message data
		switch channel {
		case .match_receive:
			
			var matchJson = messageDic
			// 老的数据
			if messageDoc.dataResource?.id != nil {
				// conver to new matchJson
				matchJson = self.parseMatch(old: messageDoc)
				// 构造不能使用的 json 格式
				messageDoc = JSONAPIDocument.init(data: matchJson)
			}else {
				matchJson = self.parseMatch(new: matchJson)
			}
			
			// 根据 match attributes 构造 match 对象
			if let matchModel = Mapper<MatchModel>().map(JSON: matchJson) {
				// 构造 match model
				messageObject = matchModel
			}
			break
		case .call_receive:
			// call_id
			var call_info = messageDoc.dataResource?.attributes
			if let call_data = messageDoc.dataResource?.json, let match_id = call_data["id"] as? String {
				call_info?["id"] = match_id
			}
			
			// call_relationships
			if let call_relationships = messageDoc.dataResource?.relationships {
				// 构造新的 json 和 document
				var new_message_info = messageDoc.json
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
				messageDoc = JSONAPIDocument.init(json: new_message_info)
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
		
		RealmDataController.shared.apply(messageDoc) { (_) in
			if messageObject == nil {
				messageObject = messageDoc
			}
			self.dispatch(object: messageObject, message: messageDic, from: channel)
		}
	}
	
	func dispatch(object: Any?, message: [String: Any], from channel: SocketChannel) {
		// dispatch message data to observer(on main queue)
		var selector = #selector(MessageObserver.didReceiveUnknowMessage(message:channel:))
		// perform selector with objects
		var object1: Any?
		
		switch channel {
		case .match_outroom:
			if let messageDoc = object as? JSONAPIDocument, let attribute = messageDoc.dataResource?.attributes, let action = attribute["match_action"] as? String, let send_time = attribute["send_time"] as? TimeInterval, send_time != 0 {
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
			fallthrough
		case .call_outroom:
			if let messageDoc = object as? JSONAPIDocument, let attribute = messageDoc.dataResource?.attributes, let action = attribute["match_action"] as? String, let chat_id = attribute["chat_id"] as? String {
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
			if let match = object as? MatchModel {
				if match.pair() {
					selector = #selector(MessageObserver.didReceiveTwopMatch(match:))
				}else {
					selector = #selector(MessageObserver.didReceiveOnepMatch(match:))
				}
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
					let _ = observer.perform(selector)
				}else {
					let _ = observer.perform(selector, with: object1)
				}
			}
		})
	}
	
	private func parseMatch(old messageInfo: JSONAPIDocument) -> [String: Any] {
		var matchDic = messageInfo.dataResource?.attributes ?? [String: Any]()
		// 设置 match 属性
		if let meta = messageInfo.meta, let next_fact = meta["next_fact"] as? String {
			matchDic["fact"] = next_fact
		}
		
		if let match_id = messageInfo.dataResource?.id {
			matchDic["match_id"] = match_id
		}
		
		if let session_id = matchDic["session_id"] as? String {
			matchDic["channel_name"] = session_id
		}
		
		if let media_key = matchDic["media_key"] as? String {
			matchDic["channel_key"] = media_key
		}
		
		if let token = matchDic["token"] as? String {
			matchDic["channel_key"] = token
		}
		
		if let match_distance = matchDic["match_distance"] {
			matchDic["match_distance"] = match_distance
		}
		
		// 更正 match 结构
		if let match_relationships = messageInfo.dataResource?.relationships {
			if let user_info = match_relationships["user"] as? JSONAPIDocument, let user_id = user_info.dataResource?.id {
				// 设置 match 到的 user
				var user_attributes = user_info.dataResource?.attributes ?? [String: Any]() // 构造 user 属性
				let user_id = Int(user_id)
				user_attributes["id"] = user_id
				
				// 构造 user_info
				var user_info_attributes: [String: Any] = [String: Any]()
				user_info_attributes["user_id"] = user_id
				user_info_attributes["bio"] = matchDic["bio"]
				
				// user channesl
				if let channels = user_attributes["channels"] as? [String], let first = channels.first, let tree_id = Int(first) {
					// make channels with user's channels
					user_info_attributes["tree_id"] = tree_id
				}
				// user_info in users
				user_attributes["user_info"] = user_info_attributes
				// users
				matchDic["users"] = [user_attributes]
			}
		}
		return matchDic
	}
	
	private func parseMatch(new messageJson: [String: Any]) -> [String: Any] {
		var matchDic = messageJson
		if let users = messageJson["users"] as? [[String: Any]] {
			var new_users = [[String: Any]]()
			let user_infos = messageJson["user_infos"] as? [[String: Any]]
			
			for user in users {
				var new_user = user
				let user_id = user["id"] as? Int
				
				var new_user_info = [String: Any]()
				if let user_infos = user_infos {
					for user_info in user_infos {
						if let user_info_id = user_info["user_id"] as? Int, user_info_id == user_id {
							new_user_info = user_info
						}
					}
				}
				if new_user_info["user_id"] == nil {
					new_user_info["user_id"] = user_id
				}
				new_user["user_info"] = new_user_info
				new_users.append(new_user)
			}
			matchDic["users"] = new_users
		}
		return matchDic
	}
}

extension MessageCenter: SocketMessageHandler {
	public func receive(message: [String: Any], from channel: SocketChannel) {
		self.handle(messageDic: message, from: channel)
		LogManager.shared.addLog(type: .ReceiveSocketMessage, subTitle: channel.rawValue, info: message)
	}
}
