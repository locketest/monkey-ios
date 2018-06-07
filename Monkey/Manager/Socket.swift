//
//  Socket.swift
//  Monkey
//
//  Created by Isaiah Turner on 2/14/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Starscream
import RealmSwift
import Alamofire

enum SocketConnectStatus : String {
	case connected = "connected"
	case disconnected = "disconnected"
}

public protocol MonkeySocketDelegate: class {
	func webSocketDidRecieveMatch(match: Any, data: [String: Any])
	func webSocketDidRecieveVideoCall(videoCall: Any, data: [String: Any])
	func webSocketDidRecieveVideoCallCancel(data: [String: Any])
	func webScoketDidRecieveChatMessage(data: [String: Any])
}

public protocol ChatSocketDelegate: class {
	func webSocketDidRecieveSkip(match: Any, data: [String: Any])
	func webSocketDidRecieveAccept(match: Any, data: [String: Any])
}

class Socket: WebSocketDelegate, WebSocketPongDelegate {
	typealias Callback = (( _ error: Error?, _ response: [String: Any]?) -> ())
	private (set) var callbacks = [Int: Callback]()

	// 写操作
	struct SocketWrite {
		var string: String
		var completion: (() -> ())?
	}
	// 未发出的写操作
	private (set) var pendingSocketWrites = [SocketWrite]()
	// message 号，from 1
	private (set) var messageId = 1
	// 是否有写入权限
	private (set) var isAuthorized = false
	var fetchCollection = false

	// 单例
	static let shared = Socket()
	// 底层 websocket
	let webSocket = WebSocket(url: URL(string: Environment.socketURL)!)

	// 好友和消息请求
	weak var currentFriendshipsJSONAPIRequest: JSONAPIRequest?
	weak var currentMessagesJSONAPIRequest: JSONAPIRequest?

	// 消息代理回调
	public weak var delegate: MonkeySocketDelegate?
	
	// chat 消息回调
	private var chatMessageDelegates: [ChatSession] = [ChatSession]()
	func addChatMessageDelegate(chatMessageDelegate: ChatSession) {
		chatMessageDelegates.append(chatMessageDelegate)
	}
	
	func delChatMessageDelegate(chatMessageDelegate: ChatSession) {
		let _ = chatMessageDelegates.removeObject(object: chatMessageDelegate)
	}

	// 是否可用
	var isEnabled = false {
		didSet {
			if self.isEnabled {
				self.webSocket.connect()
			} else {
				self.webSocket.disconnect()
			}
		}
	}

	// 连接状态
	var socketConnectStatus: SocketConnectStatus {
		get {
			if (self.webSocket.isConnected){
				return .connected
			}else {
				return .disconnected
			}
		}
	}

	// 初始化
	private init() {
		webSocket.delegate = self
	}

	private func refreshFriendships() {
		self.currentFriendshipsJSONAPIRequest?.cancel()
		self.currentFriendshipsJSONAPIRequest = RealmFriendship.fetchAll { (result: JSONAPIResult<[RealmFriendship]>) in
			switch result {

			case .success(let friendships):
				let realm = try? Realm()
				guard let storedFriendships = realm?.objects(RealmFriendship.self) else {
					print("Error: No friendships to delete on the device when syncing friendships from server")
					return
				}
				let friendshipIdsToKeep = friendships.map { $0.friendship_id }
				let predicate = NSPredicate(format: "NOT friendship_id IN %@", friendshipIdsToKeep)
				let exFriends = storedFriendships.filter(predicate)
				if exFriends.count > 0 {
					do {
						try realm?.write {
							realm?.delete(exFriends)
						}
					} catch (let error) {
						print("Error: \(error.localizedDescription)")
						APIError.unableToSave.log(context: "Deleting old friendships.")
					}
				}
			case .error(let error):
				error.log(context: "RealmFriendship sync failed")
			}
		}
	}

	private func refreshMessageList() {
		self.currentMessagesJSONAPIRequest?.cancel()
		self.currentMessagesJSONAPIRequest = RealmMessage.fetchAll { (result: JSONAPIResult<[RealmMessage]>) in
			switch result {
			case .success(_):
				break
			case .error(let error):
				error.log(context: "RealmMessage sync failed")
			}
		}
	}
	
	private func uploadScreenShot(data: [String: Any], channel: String) {
		let reportInfo = JSONAPIDocument.init(json: data)
		if let reportData = reportInfo.dataResource, let attribute = reportData.attributes, let uploadUrl = attribute["upload_url"] as? String {
			HWCameraManager.shared().snapStream { (imageData) in
				Alamofire.upload(imageData, to: uploadUrl, method: .put, headers: ["Content-Type": "image/jpeg"])
			}
		}
	}
	
	private func dispatchMatchMessage(data: [String: Any], channel: String) {
		let matchMessageInfo = JSONAPIDocument.init(json: data)
		if let matchMessageData = matchMessageInfo.dataResource, let attribute = matchMessageData.attributes, let chat_id = attribute["chat_id"] as? String, let match_action = attribute["match_action"] as? String {
			for chatMessageObserver in chatMessageDelegates {
				if chatMessageObserver.chat?.chatId == chat_id {
					chatMessageObserver.didReceiveChannelMessage(message: ["type": match_action])
				}
			}
		}
	}

	internal func websocketDidConnect(socket: WebSocketClient) {
		print("websocketDidConnect \(webSocket)")

		guard let authorization = APIController.authorization else {
			return // Signed out.
		}

		if self.fetchCollection == false {
			self.refreshFriendships()
			self.refreshMessageList()
			self.fetchCollection = true
		}

		self.webSocket.write(string: [0, "authorization", [
			"authorization": authorization,
			"last_data_received_at": Date().iso8601,
			]].toJSON)
		
		callbacks[0] = { (error, data) in
			if let error = error {
				self.webSocket.disconnect()
				self.didReceive(error: error)
				return
			}
			self.isAuthorized = true
			
			// 刚连接成功时，将所有未发送的消息全部发送
			let socketWrites = self.pendingSocketWrites
			self.pendingSocketWrites = [SocketWrite]()
			for socketWrite in socketWrites {
				self.write(string: socketWrite.string, completion: socketWrite.completion)
			}
		}
	}

	internal func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
		error.then { print("websocketDidDisconnect \($0)") }
		self.isAuthorized = false
		// 断线重连
		guard let error = error else {
			if self.isEnabled {
				self.webSocket.connect()
			}
			return
		}
		self.didReceive(error: error)
	}
	internal func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
		print("websocketDidReceiveMessage \(text)")
		guard let result = text.asJSON as? [Any] else {
			print("Result must be an array")
			return
		}
		guard let channel = result.first as? String else {
			print("First element of result must be channel string")
			return
		}
		guard let data = result.last as? Dictionary<String, Any> else {
			print("Last element of result must be data result")
			return
		}
		switch channel {
		case "internal_error":
			if let error = data["error"] as? Dictionary<String, Any> {
				self.didReceive(error: NSError(domain: "NSMonkeyAPIErrorDomain", code: error["code"] as? Int ?? -1, userInfo: error))
			}
		case "callback":
			if let error = data["error"] as? Dictionary<String, Any> {
				self.didReceive(error: NSError(domain: "NSMonkeyAPIErrorDomain", code: error["code"] as? Int ?? -1, userInfo: error))
				return
			}
			if channel == "callback" {
				guard let messageId = data["id"] as? Int else {
					print("Callback missing message ID")
					return
				}
				if messageId == -1, let jsonData = data["data"] as? [String: Any] {
					self.parseJSONAPIData(data: jsonData, channel: channel)
				}
				for (callbackId, callback) in callbacks {
					if callbackId == messageId {
						callback(nil, data["data"] as? Dictionary<String, Any>)
						callbacks.removeValue(forKey: callbackId)
					}
				}
			}
		case "friendship_deleted":
			self.refreshFriendships()
		case "relationship_new":
			self.refreshFriendships()
		case "reported":
			self.uploadScreenShot(data: data, channel: channel)
		case "pos_match_request":
			self.dispatchMatchMessage(data: data, channel: channel)
		case "videocall_pos_request":
			self.dispatchMatchMessage(data: data, channel: channel)
		case "chat":
			fallthrough
		case "matched_user":
			fallthrough
		case "videocall_call":
			fallthrough
		case "json_api_data":
			fallthrough
		default:
			self.parseJSONAPIData(data: data, channel: channel)
		}
	}

	internal func parseJSONAPIData(data: [String: Any], channel: String) {
		var jsonData = data
		if channel == "matched_user" {
			var realmCall = jsonData["data"] as? [String: Any]
			if let relationships = realmCall?["relationships"] as? [String: Any], let user = relationships["user"] as? [String: Any], let userData = user["data"] as? [String: Any] {
				
				var include = userData
				if let userAttributes = userData["attributes"] as? [String: Any] {
					
					var userRelationships = [String: Any]()
					if let channels = userAttributes["channels"] as? [String] {
						// make channels with user's channels
						let channelsData = channels.flatMap { (channel_id) -> [String: String]? in
							return [
								"type": "channels",
								"id": channel_id,
								]
						}
						userRelationships["channels"] = ["data": channelsData]
					}
					
					if let instagram_account = userAttributes["instagram_account_id"] as? String {
						userRelationships["instagram_account"] = ["data": [
							"type": "instagram_accounts",
							"id": instagram_account,
							]]
					}
					
					include["relationships"] = userRelationships
				}
				
				jsonData["included"] = [include]
			}
			
		}else if channel == "videocall_call" {
			var realmCall = jsonData["data"] as? [String: Any]
			if let relationships = realmCall?["relationships"] as? [String: Any], let user = relationships["user"] as? [String: Any], let user_id = user["id"] as? String {
				var initiator = user
				initiator["data"] = [
					"type": "users",
					"id": user_id,
				]
				var userRelationships = relationships
				userRelationships["initiator"] = initiator
				realmCall?["relationships"] = userRelationships
				
				jsonData["data"] = realmCall
			}
		}
		
		RealmDataController.shared.apply(JSONAPIDocument(json: jsonData)) { result in
			switch result {
			case .error(let error):
				error.log()
			case .success(let objects):
				if(channel == "matched_user") {
					self.delegate?.webSocketDidRecieveMatch(match: objects.first as Any, data: data)
				} else if(channel == "videocall_call") {
					self.delegate?.webSocketDidRecieveVideoCall(videoCall: objects.first as Any, data: data)
				} else if(channel == "videocall_cancel") {
					self.delegate?.webSocketDidRecieveVideoCallCancel(data: data)
				} else if(channel == "chat") {
					self.delegate?.webScoketDidRecieveChatMessage(data: data)
				}
			}
		}
	}

	internal func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
		print("websocketDidReceiveData \(data)")
	}

	internal func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
		print("websocketDidReceivePong \(String(describing: data)))")
	}

	internal func send(message: Dictionary<String, Any>, to channel: String, completion: Callback? = nil) {
		let data:[Any] = [messageId, channel, message]
		callbacks[messageId] = completion
		messageId += 1
		self.write(string: data.toJSON, completion: nil)
	}

	private func write(string: String, completion: (() -> ())?) {
		guard self.isAuthorized else {
			print("Queuing message: \(string.trunc(length: 100))")
			self.pendingSocketWrites.append(SocketWrite(string: string, completion: completion))
			return
		}
		print("Writing message: \(string.trunc(length: 100))")
		self.webSocket.write(string: string, completion: completion)
	}

	private func didReceive(error: Error) {
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
			if self.isEnabled {
				self.webSocket.connect()
			}
		}
	}
}

extension Array {
	var toJSON: String {
		get {
			let defaultJSON = "[]"
			guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
				return defaultJSON
			}

			return String(data: data, encoding: .utf8) ?? defaultJSON
		}
	}
}

extension Dictionary {
	var toJSON: String {
		get {
			let defaultJSON = "{}"
			guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
				return defaultJSON
			}

			return String(data: data, encoding: .utf8) ?? defaultJSON
		}
	}
}

extension String {
	var asJSON: AnyObject? {
		let data = self.data(using: .utf8, allowLossyConversion: false)

		if let jsonData = data {
//			Will return an object or nil if JSON decoding fails
			do {
				let message = try JSONSerialization.jsonObject(with: jsonData, options:.mutableContainers)
				if let jsonResult = message as? NSMutableArray {
					return jsonResult //Will return the json array output
				} else if let jsonResult = message as? NSMutableDictionary {
					return jsonResult //Will return the json dictionary output
				} else {
					return nil
				}
			}
			catch let error as NSError {
				print("An error occurred: \(error)")
				return nil
			}
		} else {
//			Lossless conversion of the string was not possible
			return nil
		}
	}
}
