//
//  ChannelService.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

protocol ChannelServiceProtocol {
	// 远程用户加入房间
	func remoteUserDidJoined(user user_id: Int)
	
	// 远程用户离开房间(是否掉线)
	func remoteUserDidQuited(user user_id: Int, droped: Bool)

	// 收到远程用户视频
	func didReceiveRemoteVideo(user user_id: Int)

	// media_key 失效
	func channelKeyInvalid()
	
	// 自己成功加入房间
	func joinChannelSuccess()
	
	// 自己成功退出房间
	func leaveChannelSuccess()
	
	// 收到房间内错误
	func didReceiveChannelError(error: Error?)

	// 处理消息回调
	func didReceiveChannelMessage(message: [String: Any])
}

protocol ChannelServiceManager {
	// 加入新房间
	func joinChannel(matchModel: ChannelModel)
	// 离开旧房间
	func leaveChannel()
	
	// 对所有远程用户静音开关
	func muteAllRemoteUser(mute: Bool)
	// 对某个远程用户静音开关
	func mute(user user_id: Int, mute: Bool)
	// 发送一条房间内消息
	func sendMessage(message: MatchMessage)
}

class ChannelService {
	var cameraManager = HWCameraManager.shared()

	static let shared = ChannelService()
	private init() {
		self.cameraManager.streamHandler = self
		self.agoraService.observer = self
		self.opentokService.observer = self
	}

	/**
	*  channel observer
	*/
	var channelDelegate: ChannelServiceProtocol?
	// 当前匹配到的 match
	fileprivate var matchModel: ChannelModel?
	// agora service
	fileprivate var agoraService = AgoraService.shared
	// opentok service
	fileprivate var opentokService = OpenTokService.shared

	// 根据当前模型选择 channelService
	fileprivate func channelService(for match: ChannelModel) -> ChannelServiceManager {
		if match.supportAgora() {
			return self.agoraService
		}else {
			return self.opentokService
		}
	}

	// 等待发送的消息
	fileprivate var peddingMessages: [MatchMessage] = [MatchMessage]()
}

extension ChannelService: ChannelServiceManager {
	
	func joinChannel(matchModel: ChannelModel) {
		self.matchModel = matchModel
		self.channelService(for: matchModel).joinChannel(matchModel: matchModel)
	}

	// 离开房间
	func leaveChannel() {
		// 如果还在房间
		guard let match = self.matchModel else {
			return
		}
		// 离开 channel
		self.channelService(for: match).leaveChannel()
		// 模型置空
		self.matchModel = nil
		// 消息情空
		self.peddingMessages.removeAll()
	}
	
	// 静音所有用户
	func muteAllRemoteUser(mute: Bool) {
		guard let match = self.matchModel else { return }
		
		self.channelService(for: match).muteAllRemoteUser(mute: mute)
	}

	// 对某个人静音开关
	func mute(user user_id: Int, mute: Bool) {
		guard let match = self.matchModel else { return }
		
		self.channelService(for: match).mute(user: user_id, mute: mute)
	}
	
	func sendMessage(type: MessageType, body: String) {
		let dic = [
			"type": type.rawValue,
			"body": body,
			]
		
		// json to model
		if let message = Mapper<MatchMessage>().map(JSON: dic) {
			self.sendMessage(message: message)
		}
	}
	
	// 发送消息
	func sendMessage(message: MatchMessage) {
		// 没有 match 不会发送消息
		guard let match = self.matchModel, match.allUserJoined() else {
			// 缓存消息等对方加入后发送
			self.peddingMessages.append(message)
			return
		}
		
		self.channelService(for: match).sendMessage(message: message)
	}
	
	// 发送 pedding message
	fileprivate func dispatchPeddingMessages(to user_id: Int) {
		guard let match = self.matchModel else { return }
		// 如果对方全都加入房间了，且当前有未发送完的消息，继续发送
		if match.allUserJoined() {
			// 遍历发送未发送消息
			let peddingMessages = self.peddingMessages
			let channelService = self.channelService(for: match)
			peddingMessages.forEach { (message) in
				channelService.sendMessage(message: message)
			}
			
			// 清空未发送消息
			self.peddingMessages.removeAll()
		}
	}
}

extension ChannelService: ChannelServiceProtocol {
	func joinChannelSuccess() {
		guard let match = self.matchModel else { return }
		
		match.joined = true
		self.channelDelegate?.joinChannelSuccess()
	}
	
	func leaveChannelSuccess() {
		self.channelDelegate?.leaveChannelSuccess()
	}

	func remoteUserDidJoined(user user_id: Int) {
		// 如果进入的人是匹配到的人
		guard let match = self.matchModel, let user = match.matchedUser(with: user_id) else { return }
		// joined
		user.joined = true
		// mute first
		self.channelService(for: match).mute(user: user_id, mute: true)
		// 当前有未发送完的消息，继续发送
		self.dispatchPeddingMessages(to: user_id)
		// notify delegate
		self.channelDelegate?.remoteUserDidJoined(user: user_id)
	}
	
	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		guard let match = self.matchModel, match.matchedUser(with: user_id) != nil else { return }
		
		// 与远程用户断开连接
		self.channelDelegate?.remoteUserDidQuited(user: user_id, droped: droped)
	}

	func didReceiveRemoteVideo(user user_id: Int) {
		// 如果收到的流，不是当前匹配到的用户的流
		guard let match = self.matchModel, let user = match.matchedUser(with: user_id) else { return }
		
		user.joined = true
		if user.accept == false {
			self.channelDelegate?.didReceiveChannelMessage(message: [
				"type": MessageType.Accept.rawValue,
				])
		}
		user.accept = true
		user.connected = true
		self.channelDelegate?.didReceiveRemoteVideo(user: user_id)
	}
	
	func didReceiveChannelError(error: Error?) {
		self.channelDelegate?.didReceiveChannelError(error: error)
	}

	func channelKeyInvalid() {
		self.channelDelegate?.channelKeyInvalid()
	}

	func didReceiveChannelMessage(message: [String: Any]) {
		// 如果收到的消息，不是匹配到的用户发送的消息
		
		self.channelDelegate?.didReceiveChannelMessage(message: message)
	}
}

extension ChannelService: StreamRawDataHandler, StreamBufferHandler {
	func newFrameBufferAvailable(_ frameBuffer: CVPixelBuffer) {
		guard let match = self.matchModel else { return }
		
		if match.supportAgora() {
			self.agoraService.newFrameBufferAvailable(frameBuffer)
		}
	}

	func newFrameRawDataAvailable(_ rawData: UnsafeMutablePointer<GLubyte>) {
//		guard let match = self.matchModel else { return }
		
	}
}
