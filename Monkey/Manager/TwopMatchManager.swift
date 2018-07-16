//
//  TwopMatchManager.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/12.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper

class TwopMatchManager {
	
	static let `default` = TwopMatchManager()
	private init() {}
	
	fileprivate let channelService = ChannelService.shared
	weak var delegate: MatchServiceObserver?
	fileprivate var matchModel: MatchModel?
	fileprivate var friendPair: FriendPairModel?
	
	fileprivate var pairTimer: Timer?
	fileprivate var confirmTimer: Timer?
	fileprivate var waitingTimer: Timer?
	fileprivate var connectingTimer: Timer?
	fileprivate var reConnectingTimer: Timer?
	
	func connect(with friendPair: FriendPairModel) {
		self.channelService.channelDelegate = self
		
		// stop other timer
		self.stopAllTimer()
		
		// save friend pair
		self.friendPair = friendPair
		
		// join channel 之后直接开启视频流
		self.channelService.joinChannel(matchModel: friendPair)
		self.channelService.captureSwitch(open: true)
	}
	
	func reconnect(with friendPair: FriendPairModel) {
		self.channelService.channelDelegate = self
		
		// stop other timer
		self.stopAllTimer()
		
		// save friend pair
		self.friendPair = friendPair
		
		// reconnecting
		self.startReConnectTimer()
		
		// join channel 之后直接开启视频流
		self.channelService.joinChannel(matchModel: friendPair)
		self.channelService.captureSwitch(open: true)
	}
	
	func pairSuccess(with friendPair: FriendPairModel) {
		// connect success with my friend
		self.stopAllTimer()
		self.channelService.mute(user: friendPair.left.user_id, mute: false)
	}
	
	func stopConnect(with friendPair: FriendPairModel? = nil) {
		// leave channel
		if self.channelService.matchModel == self.matchModel || self.channelService.matchModel == self.friendPair {
			self.channelService.leaveChannel()
			// disable video capture
			self.channelService.captureSwitch(open: false)
		}
		// stop other timer
		self.stopAllTimer()
		// clear friend pair
		self.friendPair = nil
		// endchat
		self.endChat()
	}
	
	// 收到新的 match
	func match(with match: MatchModel) {
		// stop other timer
		self.stopAllTimer()
		
		// receive a new match
		self.matchModel = match
		
		// 如果是 pair，开启 confirm timer, 否则等待对方操作
		if match.matched_pair() {
			// send confirm
			self.sendConfirm()
		}else {
			// begin response timer
			self.startWaitingTimer()
			
//			DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 2)) {
//				self.didReceiveChannelMessage(message: [
//					"type": MessageType.Accept.rawValue,
//					"sender": match.left.user_id,
//					"match_id": match.match_id,
//					"target": [self.friendPair?.friend.user_id ?? 0, Int(UserManager.UserID ?? "0") ?? 0]
//					])
//			}
		}
	}
	
	// 与新的 match connect
	func connect(with match: MatchModel) {
		// stop other timer
		self.stopAllTimer()
		// receive a new match
		self.matchModel = match
		// start connect timer
		self.startConnectTimer()
		// 如果是 pair，先退出当前 pair 房间，再加入新的 match 房间
		if match.matched_pair() {
			self.friendPair?.left.joined = false
			self.friendPair?.left.connected = false
			// leave old channel
			self.channelService.leaveChannel()
			// join new room
			self.channelService.joinChannel(matchModel: match)
			// reopen video capture
			self.channelService.captureSwitch(open: true)
		}
		
//		DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 2)) {
//			self.didReceiveRemoteVideo(user: match.left.user_id)
//		}
	}
	
	func beginChat() {
		self.stopAllTimer()
		self.channelService.muteAllRemoteUser(mute: false)
	}
	
	func endChat() {
		self.stopAllTimer()
		self.matchModel = nil
	}
	
	func sendConfirm() {
		// stop prev timer
		self.stopAllTimer()
		
		// if no friend, return
		guard let friendPair = self.friendPair else { return }
		// confirm timer
		self.startConfirmTimer()
		// confirm message
		self.sendMatchMessage(type: .Confirm, to: friendPair.friend)
	}
	
	func sendMatchMessage(type: MessageType, body: String = "", to target_user: MatchUser? = nil) {
		self.channelService.sendMessage(type: type, body: body, target_match: self.matchModel?.match_id, target_user: target_user)
	}
}

extension TwopMatchManager {
	
	fileprivate func stopAllTimer() {
		self.stopPairTimer()
		self.stopWaitingTimer()
		self.stopConfirmTimer()
		self.stopConnectTimer()
		self.stopReConnectTimer()
	}
	
	fileprivate func startPairTimer() {
		self.stopPairTimer()
		let pairTime = TimeInterval(10)
		self.pairTimer = Timer.scheduledTimer(timeInterval: pairTime, target: self, selector: #selector(pairTimeOut), userInfo: nil, repeats: false)
	}
	
	fileprivate func stopPairTimer() {
		self.pairTimer?.invalidate()
		self.pairTimer = nil
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
	
	fileprivate func startConfirmTimer() {
		self.stopConfirmTimer()
		let confirmTime = TimeInterval(2)
		self.confirmTimer = Timer.scheduledTimer(timeInterval: confirmTime, target: self, selector: #selector(confirmTimeOut), userInfo: nil, repeats: false)
	}
	
	fileprivate func stopConfirmTimer() {
		self.confirmTimer?.invalidate()
		self.confirmTimer = nil
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
	
	fileprivate func startReConnectTimer() {
		self.stopReConnectTimer()
		let reConnectTime = TimeInterval(RemoteConfigManager.shared.match_connect_time)
		self.reConnectingTimer = Timer.scheduledTimer(timeInterval: reConnectTime, target: self, selector: #selector(reConnectTimeOut), userInfo: nil, repeats: false)
	}
	
	fileprivate func stopReConnectTimer() {
		self.reConnectingTimer?.invalidate()
		self.reConnectingTimer = nil
	}
	
	@objc fileprivate func pairTimeOut() {
		self.delegate?.disconnect(reason: .PairTimeOut)
	}
	
	@objc fileprivate func waitingTimeOut() {
		self.delegate?.disconnect(reason: .WaitingTimeOut)
	}
	
	@objc fileprivate func confirmTimeOut() {
		self.delegate?.disconnect(reason: .ConfirmTimeOut)
	}
	
	@objc fileprivate func connectTimeOut() {
		self.delegate?.disconnect(reason: .ConnectTimeOut)
	}
	
	@objc fileprivate func reConnectTimeOut() {
		self.delegate?.disconnect(reason: .ReConnectTimeOut)
	}
}

extension TwopMatchManager: ChannelServiceProtocol {
	func matchUser(with user_id: Int) -> MatchUser? {
		if let matchUser = self.friendPair?.matchedUser(with: user_id) {
			return matchUser
		}
		return self.matchModel?.matchedUser(with: user_id)
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
		if let matchMessage = Mapper<MatchMessage>().map(JSON: message) {
			delegate?.channelMessageReceived(message: matchMessage)
		}
	}
	
	func channelKeyInvalid() {
		// if no friend, return
		guard let friendPair = self.friendPair else { return }
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/renew/\(friendPair.channel_name)", method: .post) { (result: JSONAPIResult<[String: Any]>) in
			switch result {
			case .error(let error):
				// revert fade animation back to screen
				// notify user call failed
				error.log(context: "Create (POST) on an initiated call")
			case .success(let responseJSON):
				break
			}
		}
	}
	
	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		var error = MatchError.OtherQuit
		if self.friendPair?.matchedUser(with: user_id) != nil {
			error = MatchError.PairQuit
		}
		self.delegate?.disconnect(reason: error)
	}
	
	func didReceiveChannelError(error: Error?) {
		self.delegate?.disconnect(reason: .ServerError)
	}
}
