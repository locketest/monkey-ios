//
//  MatchManager.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/18.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

enum MatchServiceError: Int {
	case Skip = 0
	case TimeOut = 1
	case Quit = 2
	case Error = 3
}

protocol MatchServiceObserver {
	func remoteViewFor(user user_id: Int) -> UIView?
	func disconnect(reason: MatchServiceError)

	func remoteVideoReceived(user user_id: Int)
	func channelMessageReceived(message: Message)
}

class MatchManager {

	static let `default` = MatchManager()
	private init() {
		channelService.channelDelegate = self
	}

	let cameraService = HWCameraManager.shared()
	let channelService = ChannelService.shared
	var delegate: MatchServiceObserver?

	var enterChannelTimer: Timer?
	var matchModel: VideoCallProtocol?

	func matchWithModel(matchedModel: VideoCallProtocol) {
		matchModel = matchedModel
		channelService.joinChannel(matchModel: matchedModel) {
			// join success
		}
	}

	func connectMatch() {
//		guard let currentMatchModel = matchModel else {
//			return
//		}
		runAsynchronouslyOnVideoProcessingQueue {
			self.channelService.captureStream = true
		}
//		if currentMatchModel.allUserConected() {
//			stopConnectTimer()
//		}else {
//			startConnectTimer()
//		}
	}

	func beginChat() {
		channelService.mute(user: Int(matchModel?.user?.user_id ?? "") ?? 0, mute: false)
	}
	
	func sendMatchMessage(matchMessage: [String: Any]) {
		channelService.sendMessage(message: matchMessage)
//		self.matchModel?.sendedMessage += 1
	}

	func stopMatch() {
		stopConnectTimer()

		runAsynchronouslyOnVideoProcessingQueue {
			self.channelService.captureStream = false
		}
		channelService.leaveChannel {

		}
		matchModel = nil
	}

	func startConnectTimer() {
		enterChannelTimer = Timer.scheduledTimer(timeInterval: TimeInterval(RemoteConfigManager.shared.match_connect_time), target: self, selector: #selector(connectTimeout), userInfo: nil, repeats: false)
	}

	func stopConnectTimer() {
		enterChannelTimer?.invalidate()
		enterChannelTimer = nil
	}

	@objc func connectTimeout() {
		delegate?.disconnect(reason: .TimeOut)
	}
}

extension MatchManager: ChannelServiceProtocol {
	func remoteViewFor(user user_id: Int) -> UIView? {
		return delegate?.remoteViewFor(user: user_id)
	}

	func remoteUserDidJoined(user user_id: Int) {

	}
	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		delegate?.disconnect(reason: droped ? .Skip : .Quit)
	}

	func didReceiveRemoteVideo(user user_id: Int) {
		delegate?.remoteVideoReceived(user: user_id)
	}

	func channelKeyInvalid() {

	}

	func didReceiveChannelMessage(message: [String: Any]) {
		let messageType = message["type"] as? String

		var matchMessage: MatchMessage?
		if messageType == MessageType.Typing.rawValue {
			matchMessage = Mapper<TextMessage>().map(JSON: message)
		}else if messageType == MessageType.Text.rawValue {
			matchMessage = Mapper<TextMessage>().map(JSON: message)
//			matchModel?.receivedMessage += 1
		}else {
			matchMessage = Mapper<MatchMessage>().map(JSON: message)
		}

		if let matchMessage = matchMessage {
			delegate?.channelMessageReceived(message: matchMessage)
		}
	}
}
