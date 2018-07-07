//
//  Socket.swift
//  Monkey
//
//  Created by Isaiah Turner on 2/14/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Starscream

enum SocketChannel: String {
	case internal_error = "internal_error"
	case callback = "callback"
	
	// deleted a friend
	case friend_deleted = "friendship_deleted"
	// add a friend
	case friend_new = "relationship_new"
	// receive report
	case reported = "reported"
	
	// out room channel
	case match_outroom = "pos_match_request"
	case call_outroom = "videocall_pos_request"
	
	// chat message
	case friend_chat = "chat"
	
	// match_message
	case match_receive = "matched_user"
	case call_receive = "videocall_call"
	case call_cancel = "videocall_cancel"
	
	// 授权
	case authorization = "authorization"
	
	// just receive json
	case json_api = "json_api_data"
	
	case twop_default = "default"
	
	init(channel: String) {
		self = SocketChannel.init(rawValue: channel) ?? .json_api
	}
}

// socket message call back(main queue)
public protocol SocketMessageHandler: class {
	func receive(message: [String: Any], from channel: String)
}

class Socket {
	static let shared = Socket()
	// 初始化
	private init() {
		webSocket.delegate = self
	}
	
	// 底层 websocket
	fileprivate let webSocket = WebSocket(url: URL(string: Environment.socketURL)!)
	// 消息代理回调
	fileprivate let delegate: SocketMessageHandler = MessageCenter.shared

	// message 编号 0 authorization, -1 server define, other normal
	fileprivate static var messageId = 1
	// 是否有写入权限
	fileprivate var isAuthorized = false
	// 是否可用
	var isEnabled = false {
		didSet {
			if self.isEnabled {
				self.connect()
				NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
			} else {
				self.disconnect()
				NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
			}
		}
	}
	
	// 写操作
	fileprivate struct SocketWrite {
		var string: String
	}
	// 未发出的写操作
	fileprivate var pendingSocketWrites = [SocketWrite]()
	
	// 开始连接
	fileprivate func connect() {
		guard self.isEnabled else {
			return
		}
		self.webSocket.connect()
	}
	
	// 断开连接
	fileprivate func disconnect() {
		self.isAuthorized = false
		self.webSocket.disconnect()
	}
	
	// 应用进入前台，尝试重连
	@objc fileprivate func appBecomeActive() {
		self.connect()
	}

	// 外部调用发送 socket 消息
	func send(message: [String: Any], with messageId: Int = Socket.messageId, to channel: String) {
		let data: [Any] = [messageId, channel, message]
		Socket.messageId = Socket.messageId + 1
		self.write(string: data.toJSON)
	}
	
	// 收到 socket 消息
	fileprivate func receive(message: [String: Any], from channel: String) {
		// 如果有 error
		let error = message["error"] as? [String: Any]
		if let error = error {
			self.didReceive(error: NSError(domain: "NSMonkeyAPIErrorDomain", code: error["code"] as? Int ?? -1, userInfo: error))
		}
		
		switch channel {
		case SocketChannel.internal_error.rawValue:
			break
		case SocketChannel.callback.rawValue:
			guard let messageId = message["id"] as? Int else {
				print("Callback missing message ID")
				return
			}
			if messageId == 0 {
				if error == nil {
					self.isAuthorized = true
					// 刚连接成功时，将所有未发送的消息全部发送
					let socketWrites = self.pendingSocketWrites
					self.pendingSocketWrites = [SocketWrite]()
					for socketWrite in socketWrites {
						self.write(string: socketWrite.string)
					}
				}else {
					// 授权出错，直接断开连接
					self.disconnect()
				}
			}else {
				fallthrough
			}
		default:
			delegate.receive(message: message, from: channel)
			break
		}
	}
	
	// 向 websocket server 发送消息
	fileprivate func write(string: String, completion: (() -> ())? = nil) {
		guard self.isAuthorized else {
			print("Queuing message: \(string.trunc(length: 100))")
			self.pendingSocketWrites.append(SocketWrite(string: string))
			return
		}
		print("Writing message: \(string.trunc(length: 100))")
		self.webSocket.write(string: string, completion: completion)
	}

	// 出错重连
	fileprivate func didReceive(error: Error) {
		// 收到错误重连
		if self.isEnabled {
			self.webSocket.connect()
		}
		// 5s 之后重连
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
			if self.isEnabled {
				self.webSocket.connect()
			}
		}
	}
}

extension Socket: WebSocketDelegate {
	// 连接成功
	func websocketDidConnect(socket: WebSocketClient) {
		print("websocketDidConnect \(webSocket)")
		
		guard let authorization = APIController.authorization else {
			return // Signed out.
		}
		
		// 连接成功时，先发送授权消息
		self.webSocket.write(string: [0, SocketChannel.authorization.rawValue, [
			"authorization": authorization,
			"last_data_received_at": Date().iso8601,
			]].toJSON)
	}

	// 断开连接
	func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
		print("websocketDidDisconnect \(String(describing: error))")
		
		self.isAuthorized = false
		// 清空回调和未发送消息
		self.pendingSocketWrites.removeAll()
		// 如果发生错误，尝试重连
		if let error = error {
			self.didReceive(error: error)
		}
	}
	// 收到文本消息
	func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
		print("websocketDidReceiveMessage \(text)")
		guard let result = text.asJSON as? [Any] else {
			print("Result must be an array")
			return
		}
		guard let channel = result.first as? String else {
			print("First element of result must be channel string")
			return
		}
		guard let message = result.last as? [String: Any] else {
			print("Last element of result must be data result")
			return
		}
		
		self.receive(message: message, from: channel)
	}
	// 收到数据流消息
	func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
		print("websocketDidReceiveData \(data)")
	}
}

