//
//  ChannelService.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

protocol ChannelServiceProtocol {
	func remoteViewFor(user user_id: Int) -> UIView?

	func remoteUserDidJoined(user user_id: Int)
	func remoteUserDidQuited(user user_id: Int, droped: Bool)

	func didReceiveRemoteVideo(user user_id: Int)

	func channelKeyInvalid()

	// 处理消息回调
	func didReceiveChannelMessage(message: [String: Any])
}

protocol ChannelServiceManager {
	func joinChannel(matchModel: VideoCallProtocol, complete: @escaping CompletionHandler)
	func leaveChannel(complete: @escaping CompletionHandler)
	func mute(user user_id: Int, mute: Bool)

	func sendMessage(message: [String: Any])
	func readyToCaptureStream() -> Bool
}

class ChannelService {
	var cameraManager = HWCameraManager.shared()

	static let shared = ChannelService()
	private init() {
		cameraManager.streamHandler = self
	}

	/**
	*  当前匹配到的 match
	*/
	var matchModel: VideoCallProtocol?
	/**
	*  channel observer
	*/
	var channelDelegate: ChannelServiceProtocol?

	// agora service
	var agoraService = AgoraService.shared
	// opentok service
	var opentokService = OpenTokService.init()

	var channelService: ChannelServiceManager? {
		return channelService(for: matchModel)
	}

	// 等待发送的消息
	var peddingMessages: [MatchMessage] = [MatchMessage]()
	// 是否可发送视频流
	var captureStream = false
}

extension ChannelService: ChannelServiceManager {

	func channelService(for match: VideoCallProtocol?) -> ChannelServiceManager? {
		guard let match = match else {
			return nil
		}
		if match.supportAgora() {
			return agoraService
		}else {
			return opentokService
		}
	}

	func joinChannel(matchModel: VideoCallProtocol, complete: @escaping CompletionHandler) {
		leaveChannel(matchModel: self.matchModel) {
			self.matchModel = nil
			self.channelService(for: matchModel)?.joinChannel(matchModel: matchModel, complete: {
				self.matchModel = matchModel
				complete()
			})
		}
	}

	private func leaveChannel(matchModel: VideoCallProtocol?, complete: @escaping CompletionHandler) {
		guard let leaveMatch = matchModel else {
			complete()
			return
		}
		channelService(for: leaveMatch)?.leaveChannel(complete: complete)
	}

	func leaveChannel(complete: @escaping CompletionHandler) {
		self.matchModel = nil
		leaveChannel(matchModel: matchModel) {
			complete()
		}
	}

	func sendMessage(message: [String: Any]) {
		channelService?.sendMessage(message: message)
	}

	func mute(user user_id: Int, mute: Bool) {
		channelService?.mute(user: user_id, mute: mute)
	}

	func readyToCaptureStream() -> Bool {
		return captureStream
	}
}

extension ChannelService: ChannelServiceProtocol {
	func remoteViewFor(user user_id: Int) -> UIView? {
		return channelDelegate?.remoteViewFor(user: user_id)
	}

	func remoteUserDidJoined(user user_id: Int) {
//		matchModel?.user?.joined = true
//		channelService?.mute(user: user_id, mute: true)
		channelDelegate?.remoteUserDidJoined(user: user_id)
	}
	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		channelDelegate?.remoteUserDidQuited(user: user_id, droped: droped)
	}

	func didReceiveRemoteVideo(user user_id: Int) {
//		matchModel?.user?.connected = true
		channelDelegate?.didReceiveRemoteVideo(user: user_id)
	}

	func channelKeyInvalid() {

	}

	func didReceiveChannelMessage(message: [String: Any]) {
		channelDelegate?.didReceiveChannelMessage(message: message)
	}
}

extension ChannelService: StreamBufferHandler, StreamRawDataHandler {
	func newFrameBufferAvailable(_ frameBuffer: CVPixelBuffer) {
		guard readyToCaptureStream() == true, let currentMatchModel = matchModel else {
			return
		}
		if currentMatchModel.supportAgora() {
			agoraService.newFrameBufferAvailable(frameBuffer)
		}
	}

	func newFrameRawDataAvailable(_ rawData: UnsafeMutablePointer<GLubyte>) {
		guard readyToCaptureStream() == true, let currentMatchModel = matchModel else {
			return
		}
		if currentMatchModel.supportAgora() == false {
			opentokService.newFrameRawDataAvailable(rawData)
		}
	}
}
