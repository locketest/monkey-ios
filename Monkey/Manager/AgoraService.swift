//
//  AgoraService.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class AgoraService: NSObject {
	
	fileprivate let ApiKey = "678fa24f22c34e56a5a68b3e2e7d8588"
	fileprivate var dataChannelId: Int = -1
	
	var observer: ChannelServiceProtocol?
	fileprivate var engine: AgoraRtcEngineKit!
	
	fileprivate weak var matchModel: MatchModel?
	fileprivate weak var videoModel: VideoCallModel?
	fileprivate weak var pairModel: FriendPairModel?
	fileprivate weak var channelModel: ChannelModel?
	
	fileprivate var networkQuality = [AgoraNetworkQuality]()
	fileprivate var videoProfile = AgoraVideoProfile.landscape480P_4
	
	static let shared = AgoraService()
	private override init() {
		super.init()
		engine = AgoraRtcEngineKit.sharedEngine(withAppId: ApiKey, delegate: self)
		engine.enableMainQueueDispatch(true)
		engine.setChannelProfile(.communication)
		engine.setExternalVideoSource(true, useTexture: false, pushMode: true)
		engine.setVideoProfile(self.videoProfile, swapWidthAndHeight: true)
		engine.setEnableSpeakerphone(true)
		engine.enableVideo()
	}
}

extension AgoraService: ChannelServiceManager {
	
	func joinChannel(matchModel: ChannelModel) {
		if let match = matchModel as? MatchModel {
			self.matchModel = match
		}
		
		if let video = matchModel as? VideoCallModel {
			self.videoModel = video
		}
		
		if let pair = matchModel as? FriendPairModel {
			self.pairModel = pair
		}
		
		// channel model
		self.channelModel = matchModel
		// 当前用户 id
		let current_user = UInt(UserManager.UserID ?? "0") ?? 0
		// channel profile
		self.engine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
		// join agora channel
		self.engine.joinChannel(byToken: matchModel.channel_key, channelId: matchModel.channel_name, info: nil, uid: current_user, joinSuccess: nil)
	}
	
	func leaveChannel() {
		self.engine.leaveChannel(nil)
		self.dataChannelId = -1
	}

	func mute(user user_id: Int, mute: Bool) {
		self.engine.muteRemoteAudioStream(UInt(user_id), mute: mute)
	}

	func muteAllRemoteUser(mute: Bool) {
		if let matchModel = self.matchModel {
			for user in matchModel.users {
				self.mute(user: user.user_id, mute: mute)
			}
		}
		
		if let pairModel = self.pairModel {
			self.mute(user: pairModel.left.user_id, mute: mute)
		}
		
		if let videoModel = self.videoModel {
			self.mute(user: videoModel.left.user_id, mute: mute)
		}
	}
	
	func sendMessage(message: MatchMessage) {
		let messageData = try? JSONSerialization.data(withJSONObject: message.messageJson(), options: .prettyPrinted)
		if let messageData = messageData {
			self.engine.sendStreamMessage(dataChannelId, data: messageData)
		}
	}
}

extension AgoraService: AgoraRtcEngineDelegate {
	
	/**
	*  Event of the user joined the channel.
	*
	*  @param engine  The engine kit
	*  @param channel The channel name
	*  @param uid     The remote user id
	*  @param elapsed The elapsed time (ms) from session beginning
	*/
	func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
		self.didJoinChannel(channel: channel, user_id: uid)
	}
	
	/**
	*  Event of the user rejoined the channel
	*
	*  @param engine  The engine kit
	*  @param channel The channel name
	*  @param uid     The user id
	*  @param elapsed The elapsed time (ms) from session beginning
	*/
	func rtcEngine(_ engine: AgoraRtcEngineKit, didRejoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
		self.didJoinChannel(channel: channel, user_id: uid)
	}
	
	private func didJoinChannel(channel: String, user_id: UInt) {
		// 当前用户 id
		let current_user = UInt(UserManager.UserID ?? "0")
		guard user_id == current_user else {
			return
		}
		// 加入房间后，创建消息数据流通道
		self.engine.createDataStream(&self.dataChannelId, reliable: true, ordered: true)
		self.observer?.joinChannelSuccess()
	}
	
	/**
	*  The statistics of the call when leave channel
	*
	*  @param engine The engine kit
	*  @param stats  The statistics of the call, including duration, sent bytes and received bytes
	*/
	func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
		self.observer?.leaveChannelSuccess()
	}
	
	func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
		self.observer?.remoteUserDidJoined(user: Int(uid))
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
		let droped = (reason == .dropped)
		self.observer?.remoteUserDidQuited(user: Int(uid), droped: droped)
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
		self.observer?.didReceiveRemoteVideo(user: Int(uid))
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
		self.renderVideoFor(user: Int(uid))
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
		guard let match = self.matchModel, match.matchedUser(with: Int(uid)) != nil else { return }
		
		let messageJson = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
		if let messsageJson = messageJson as? [String: Any] {
			self.observer?.didReceiveChannelMessage(message: messsageJson)
		}
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
//		if (networkQuality.count > HWNetworkCountMax) {
//			[networkQuality removeObjectAtIndex:0];
//		}
//		[networkQuality addObject:@(quality)];
	}

	func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
		self.observer?.channelKeyInvalid()
	}
	
	func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
		self.observer?.didReceiveChannelError(error: nil)
	}
	
	func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int, error: Int, missed: Int, cached: Int) {
		self.observer?.didReceiveChannelError(error: nil)
	}

	private func videoCanvasFor(user user_id: Int) -> AgoraRtcVideoCanvas? {
		guard let remoteUser = self.channelModel?.matchedUser(with: user_id) else { return nil }
		
		let backgroundView = remoteUser.renderContainer
		let videoCanvas = AgoraRtcVideoCanvas.init()
		videoCanvas.uid = UInt.init(user_id)
		videoCanvas.view = backgroundView
		videoCanvas.renderMode = .hidden
		return videoCanvas
	}

	private func renderVideoFor(user user_id: Int) {
		guard let videoCanvas = self.videoCanvasFor(user: user_id) else { return }
		
		self.engine.setupRemoteVideo(videoCanvas)
	}
}

extension AgoraService: StreamBufferHandler {
	func newFrameBufferAvailable(_ frameBuffer: CVPixelBuffer) {
		let videoFrame = AgoraVideoFrame.init()
		videoFrame.format = 12
		videoFrame.textureBuf = frameBuffer
		let mediaTime = CACurrentMediaTime()
		videoFrame.time = CMTimeMakeWithSeconds(mediaTime, 1000)
		self.engine.pushExternalVideoFrame(videoFrame)
	}
}
