//
//  OnepMatchManager.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

enum MatchError {
	// myself quit
	case MyQuit
	// 1p myself skip
	case MySkip
	// 被别人 skip
	case OtherSkip
	// 别人离开房间
	case OtherQuit
	// pair skip
	case PairSkip
	// pair quit
	case PairQuit
	
	// pair connect time out
	case PairTimeOut
	// confirm pair match time out
	case ConfirmTimeOut
	// 1p myself no response
	case ResponseTimeOut
	// waiting other response time out
	case WaitingTimeOut
	// connect time out
	case ConnectTimeOut
	// re connect time out
	case ReConnectTimeOut
	// time over
	case TimeOver
	// channel server error
	case ServerError
	
	func shouldShowSkip() -> Bool {
		if self == .OtherSkip {
			return true
		}
		return false
	}
	
	func shouldShowTimeOut() -> Bool {
		if self == .ConnectTimeOut {
			return true
		}
		return false
	}
	
	func shouldQuit() -> Bool {
		if self == .MyQuit || self == .PairQuit {
			return true
		}
		return false
	}
}

protocol MatchServiceObserver {
	func disconnect(reason: MatchError)
	func remoteVideoReceived(user user_id: Int)
	func channelMessageReceived(message: MatchMessage)
}

class OnepMatchManager {
	
	static let `default` = OnepMatchManager()
	private init() {}
	
	fileprivate let channelService = ChannelService.shared
	var delegate: MatchServiceObserver?
	fileprivate var matchModel: MatchModel?
	
	fileprivate var responseTimer: Timer?
	fileprivate var waitingTimer: Timer?
	fileprivate var connectingTimer: Timer?
	
	func match(with model: MatchModel) {
		self.channelService.channelDelegate = self
		// stop other timer
		self.stopAllTimer()
		// receive a new match
		self.matchModel = model
		// begin response timer
		self.startResponseTimer()
		// 如果支持 accept 前置，就添加 socket 监听，否则直接进入 channel
		if model.supportSocket() == false || model.matched_pair() == true {
			// join new channel
			self.channelService.joinChannel(matchModel: model)
		}
	}
	
	func accept(auto: Bool) {
		guard let match = self.matchModel else { return }
		
		// send accept message
		self.sendResponse(type: .Accept)
		// start waiting other timeout
		self.startWaitingTimer()
		// 如果是老版本，accept 时，发送 stream
		if match.supportSocket() == false || match.matched_pair() == true {
			// 开始上传视频流
			self.channelService.captureSwitch(open: true)
		}
	}
	
	func skip(auto: Bool) {
		// send skip message
		self.sendResponse(type: .Skip)
	}
	
	func connect() {
		// stop prev timer
		self.stopAllTimer()
		
		guard let match = self.matchModel else { return }
		// 如果是新版本，开始连接时才会进入 channel
		if match.supportSocket() == true && match.matched_pair() == false {
			self.channelService.joinChannel(matchModel: match)
			// 开始上传视频流
			self.channelService.captureSwitch(open: true)
		}
		
		// connect timer
		self.startConnectTimer()
	}
	
	// begin video chat
	func beginChat() {
		self.stopAllTimer()
		// 如果不是 text mode, 开启声音
		if self.matchModel?.match_room_mode != .TextMode {
			self.channelService.muteAllRemoteUser(mute: false)
		}
	}
	
	func disconnect() {
		self.channelService.leaveChannel()
		self.stopAllTimer()
		self.matchModel = nil
	}
	
	func sendResponse(type: MessageType) {
		// stop prev timer
		self.stopAllTimer()
		guard let match = self.matchModel else { return }
		
		// send response
		let socket_channel = SocketChannel.match_outroom
		let time = Date().timeIntervalSince1970
		if match.supportSocket() == true && match.matched_pair() == false {
			let messageJson = [
				"data": [
					"type": socket_channel.rawValue,
					"attributes": [
						"match_action": type.rawValue, // skip or ready
						"chat_id": match.match_id, // chat_id
						"send_time": time,
						"matched_user": ["\(match.left.user_id)"], // array of user ids
					]
				]
			]
			
			MessageCenter.shared.send(message: messageJson, to: socket_channel)
		}else {
			self.sendMatchMessage(type: type)
		}
	}
	
	func sendMatchMessage(type: MessageType, body: String = "", to target_user: MatchUser? = nil) {
		self.handleSendMessage(type: type)
		self.channelService.sendMessage(type: type, body: body, target_user: target_user)
	}
	
	func handleSendMessage(type: MessageType) {
		guard let match = self.matchModel else { return }
		
		switch type {
		case .Text:
			match.sendedMessages += 1
		default:
			break
		}
	}
}

extension OnepMatchManager {
	
	fileprivate func stopAllTimer() {
		self.stopResponseTimer()
		self.stopWaitingTimer()
		self.stopConnectTimer()
	}
	
	fileprivate func startResponseTimer() {
		self.stopResponseTimer()
		let responseTime = TimeInterval(RemoteConfigManager.shared.match_accept_time)
		self.responseTimer = Timer.scheduledTimer(timeInterval: responseTime, target: self, selector: #selector(responseTimeOut), userInfo: nil, repeats: false)
	}
	
	fileprivate func stopResponseTimer() {
		self.responseTimer?.invalidate()
		self.responseTimer = nil
	}
	
	fileprivate func startWaitingTimer() {
		self.stopWaitingTimer()
		let waitingTime = TimeInterval(RemoteConfigManager.shared.match_waiting_time)
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
	
	@objc fileprivate func responseTimeOut() {
		self.delegate?.disconnect(reason: .ResponseTimeOut)
	}
	
	@objc fileprivate func waitingTimeOut() {
		self.delegate?.disconnect(reason: .WaitingTimeOut)
	}
	
	@objc fileprivate func connectTimeOut() {
		self.delegate?.disconnect(reason: .ConnectTimeOut)
	}
}

extension OnepMatchManager: ChannelServiceProtocol {
	func matchUser(with user_id: Int) -> MatchUser? {
		return self.matchModel?.matchedUser(with: user_id)
	}
	
	func joinChannelSuccess() {
		guard let match = self.matchModel else { return }
		if match.matched_pair() {
			match.left.joined = true
			match.right?.joined = true
		}
	}
	
	func leaveChannelSuccess() {
		
	}
	
	func remoteUserDidJoined(user user_id: Int) {
		
	}
	
	func didReceiveRemoteVideo(user user_id: Int) {
		self.delegate?.remoteVideoReceived(user: user_id)
	}
	
	func didReceiveChannelMessage(message: [String: Any]) {
		let messageType = message["type"] as? String
		let type = MessageType.init(type: messageType)
		
		var matchMessage: MatchMessage?
		switch type {
		case .Typing:
			matchMessage = Mapper<TextMessage>().map(JSON: message)
		case .Text:
			matchMessage = Mapper<TextMessage>().map(JSON: message)
			self.matchModel?.left.sendedMessage += 1
		default:
			matchMessage = Mapper<MatchMessage>().map(JSON: message)
		}
		
		if let matchMessage = matchMessage {
			delegate?.channelMessageReceived(message: matchMessage)
		}
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

