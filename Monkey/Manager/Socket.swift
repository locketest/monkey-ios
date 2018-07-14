//
//  Socket.swift
//  Monkey
//
//  Created by Isaiah Turner on 2/14/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Starscream

public enum SocketChannel: String {
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
	func receive(message: [String: Any], from channel: SocketChannel)
}

class Socket {
	static let shared = Socket()
	// 初始化
	private init() {
		webSocket.delegate = self
	}
	
	// 底层 websocket
	fileprivate let webSocket = WebSocket(url: URL(string: Environment.socketURL)!)
	
	// 记时，和记录上次发送消息时间
	fileprivate var lastResponseTime = Date().timeIntervalSince1970
	fileprivate var pingTimer: Timer?
	
	// 消息代理回调
	fileprivate let delegate: SocketMessageHandler = MessageCenter.shared

	// message 编号 0 authorization, -1 server define, other normal
	fileprivate static var messageId = 1
	// 是否有写入权限
	fileprivate var isAuthorized = false
	fileprivate var isReconnecting = false
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
	fileprivate func authorization() {
		// flat
		self.isAuthorized = true
		// ping
		self.scheduleSendPing()
		// 刚连接成功时，将所有未发送的消息全部发送
		self.dispatchPeddingMessages()
	}
	
	// 断开连接
	fileprivate func disconnect() {
		// 授权状态重置
		self.isAuthorized = false
		
		if self.webSocket.isConnected {
			// cancel send ping
			self.cancelSendPing()
			// 清空回调和未发送消息
			self.clearPeddingMessages()
			// 主动断开连接
			self.webSocket.disconnect()
		}
	}
	
	// 应用进入前台，尝试重连
	@objc fileprivate func appBecomeActive() {
		self.connect()
	}
	
	fileprivate func scheduleSendPing() {
		self.pingTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(sendPing), userInfo: nil, repeats: true)
	}
	
	fileprivate func cancelSendPing() {
		self.pingTimer?.invalidate()
		self.pingTimer = nil
	}
	
	@objc func sendPing() {
		guard self.isEnabled else {
			return
		}
		
		let currentTime = Date().timeIntervalSince1970
		guard currentTime - lastResponseTime < 30  else { return }
		self.lastResponseTime = currentTime
		self.webSocket.write(ping: Data())
	}

	// 外部调用发送 socket 消息
	func send(message: [String: Any], with messageId: Int = Socket.messageId, to channel: String) {
		let data: [Any] = [messageId, channel, message]
		Socket.messageId = Socket.messageId + 1
		self.write(string: data.toJSON)
	}
	
	// 向 websocket server 发送消息
	fileprivate func write(string: String, completion: (() -> ())? = nil) {
		if self.isAuthorized {
			print("Queuing message: \(string.trunc(length: 100))")
			self.pendingSocketWrites.append(SocketWrite(string: string))
		} else {
			print("Writing message: \(string.trunc(length: 100))")
			self.webSocket.write(string: string, completion: completion)
			// record send time
			self.lastResponseTime = Date().timeIntervalSince1970
		}
	}
	// 一次性发送所有 pedding messages
	fileprivate func dispatchPeddingMessages() {
		let socketWrites = self.pendingSocketWrites
		for socketWrite in socketWrites {
			self.write(string: socketWrite.string)
		}
		self.clearPeddingMessages()
	}
	
	// clear pedding messages
	fileprivate func clearPeddingMessages() {
		self.pendingSocketWrites.removeAll()
	}
	
	// 收到 socket 消息
	fileprivate func receive(message: [String: Any], from channel: SocketChannel) {
		switch channel {
		case .internal_error:
			fallthrough
		case .callback:
			self.didReceive(callback: message)
		default:
			self.lastResponseTime = Date().timeIntervalSince1970
			self.delegate.receive(message: message, from: channel)
			break
		}
	}
	
	// 服务端回调
	fileprivate func didReceive(callback message: [String: Any]) {
		// 如果有 error
		let error = message["error"] as? [String: Any]
		if let error = error {
			// 重连
			self.didReceive(error: NSError(domain: "NSMonkeyAPIErrorDomain", code: error["code"] as? Int ?? -1, userInfo: error))
			return
		}
		guard let messageId = message["id"] as? Int else {
			print("Callback missing message ID")
			return
		}
		guard messageId == 0 else {
			print("can not handle other callback")
			return
		}
		
		// 授权成功
		self.authorization()
	}

	// 出错重连
	fileprivate func didReceive(error: Error?) {
		// 开启了 socket
		guard self.isEnabled else {
			return
		}
		// 需要重连
		guard self.isReconnecting else {
			return
		}
		// 先断连重置 flag
		self.disconnect()
		// 收到错误重连
		self.connect()
		
		// 5s 之后重连
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
			self.didReceive(error: error)
		}
	}
}

extension Socket: WebSocketDelegate {
	// 连接成功
	func websocketDidConnect(socket: WebSocketClient) {
		print("websocketDidConnect \(webSocket)")
		
		guard let authorization = UserManager.authorization else {
			return // Signed out.
		}
		// 取消重连状态
		self.isReconnecting = false
		// 连接成功时，先发送授权消息
		self.webSocket.write(string: [0, SocketChannel.authorization.rawValue, [
			"authorization": authorization,
			"last_data_received_at": Date().iso8601,
			]].toJSON)
	}

	// 断开连接
	func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
		print("websocketDidDisconnect \(String(describing: error))")
		// 重连状态初始化
		self.isReconnecting = true
		// 如果断连，需要重连
		self.didReceive(error: error)
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
		
		self.receive(message: message, from: SocketChannel.init(channel: channel))
	}
	
	// 收到数据流消息
	func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
		print("websocketDidReceiveData \(data)")
	}
}

