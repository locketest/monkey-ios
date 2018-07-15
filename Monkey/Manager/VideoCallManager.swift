//
//  VideoCallManager.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/11.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class VideoCallManager {
	
	static let `default` = VideoCallManager()
	private init() {}
	
	fileprivate let channelService = ChannelService.shared
	var delegate: MatchServiceObserver?
	fileprivate var videoCall: VideoCallModel?
	
	fileprivate var waitingTimer: Timer?
	fileprivate var connectingTimer: Timer?
	
	func startCall() {
		self.disconnect()
		self.startWaitingTimer()
	}
	
	func closeCall() {
		self.disconnect()
	}
	
	func connect(with callModel: VideoCallModel) {
		// disconnect first
		self.disconnect()
		// video call model
		self.videoCall = callModel
		// add observer
		self.channelService.channelDelegate = self
		// begin response timer
		self.startConnectTimer()
		// join new channel
		self.channelService.joinChannel(matchModel: callModel)
		// accept 时，发送 stream
		self.channelService.captureSwitch(open: true)
	}
	
	func beginChat() {
		self.stopAllTimer()
		self.channelService.muteAllRemoteUser(mute: false)
	}
	
	func disconnect() {
		self.channelService.leaveChannel()
		self.stopAllTimer()
		self.videoCall = nil
	}
	
	func sendResponse(type: MessageType, to videoCall: VideoCallModel? = nil) {
		var call = videoCall
		if call == nil {
			call = self.videoCall
		}
		guard let match = call else { return }
		
		// send response
		let channel = SocketChannel.call_outroom
		let time = Date().timeIntervalSince1970
		let messageJson = [
			"data": [
				"type": channel.rawValue,
				"attributes": [
					"match_action": type.rawValue, // skip or ready
					"chat_id": match.match_id, // chat_id
					"send_time": time,
					"matched_user": ["\(match.left.user_id)"], // array of user ids
				]
			]
		]
		
		MessageCenter.shared.send(message: messageJson, to: channel)
	}
}

extension VideoCallManager {
	
	fileprivate func stopAllTimer() {
		self.stopWaitingTimer()
		self.stopConnectTimer()
	}
	
	fileprivate func startWaitingTimer() {
		self.stopWaitingTimer()
		let waitingTime = TimeInterval(30)
		self.waitingTimer = Timer.scheduledTimer(timeInterval: waitingTime, target: self, selector: #selector(waitingTimeOut), userInfo: nil, repeats: false)
	}
	
	fileprivate func stopWaitingTimer() {
		self.waitingTimer?.invalidate()
		self.waitingTimer = nil
	}
	
	fileprivate func startConnectTimer() {
		self.stopConnectTimer()
		let connectTime = TimeInterval(RemoteConfigManager.shared.match_connect_time)
		self.connectingTimer = Timer.scheduledTimer(timeInterval: connectTime, target: self, selector: #selector(connectTimeOut), userInfo: nil, repeats: false)
	}
	
	fileprivate func stopConnectTimer() {
		self.connectingTimer?.invalidate()
		self.connectingTimer = nil
	}
	
	@objc fileprivate func waitingTimeOut() {
		self.delegate?.disconnect(reason: .WaitingTimeOut)
	}
	
	@objc fileprivate func connectTimeOut() {
		self.delegate?.disconnect(reason: .ConnectTimeOut)
	}
}

extension VideoCallManager: ChannelServiceProtocol {
	func matchUser(with user_id: Int) -> MatchUser? {
		return self.videoCall?.matchedUser(with: user_id)
	}
	
	func joinChannelSuccess() {
		
	}
	
	func leaveChannelSuccess() {
		
	}
	
	func remoteUserDidJoined(user user_id: Int) {
		
	}
	
	func didReceiveRemoteVideo(user user_id: Int) {
		self.delegate?.remoteVideoReceived(user: user_id)
	}
	
	func didReceiveChannelMessage(message: [String: Any]) {
		
	}
	
	func channelKeyInvalid() {
		
	}
	
	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		self.delegate?.disconnect(reason: .OtherQuit)
	}
	
	func didReceiveChannelError(error: Error?) {
		self.delegate?.disconnect(reason: .ServerError)
	}
}
