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

	var engine: AgoraRtcEngineKit!

	var networkQuality = [AgoraNetworkQuality]()

	var videoProfile = AgoraVideoProfile.landscape480P_4
	var joinedSession: String?

	static let shared = AgoraService()
	private override init() {
		super.init()
		engine = AgoraRtcEngineKit.sharedEngine(withAppId: ApiKey, delegate: self)
		engine.enableMainQueueDispatch(true)
		engine.setChannelProfile(.communication)
		engine.setExternalVideoSource(true, useTexture: false, pushMode: true)
		engine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
		engine.setEnableSpeakerphone(true)
		engine.enableVideo()

		HWCameraManager.shared().streamHandler = self
	}
 }


extension AgoraService: ChannelServiceManager {
	func joinChannel(matchModel: VideoCallProtocol, complete: @escaping CompletionHandler) {
		engine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
		if joinedSession != nil {
			self.leaveChannel {
				self.joinChannel(matchModel: matchModel, complete: complete)
			}
			return
		}
		
		joinedSession = matchModel.session_id
		engine.joinChannel(byToken: matchModel.channelToken, channelId: matchModel.session_id ?? "", info: nil, uid: UInt(APIController.shared.currentUser?.user_id ?? "") ?? 0) { (channel, user_id, elapsed) in
			self.engine.createDataStream(&self.dataChannelId, reliable: true, ordered: true)
			complete()
		}
	}
	func leaveChannel(complete: @escaping CompletionHandler) {
		guard joinedSession != nil else {
			complete()
			return
		}
		engine.leaveChannel { (_) in
			self.dataChannelId = -1
			self.joinedSession = nil
			complete()
		}
	}
	
	func sendMessage(message: [String: Any]) {
		let messageData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
		if let messageData = messageData {
			engine.sendStreamMessage(dataChannelId, data: messageData)
		}
	}

	func mute(user user_id: Int, mute: Bool) {
//		engine.muteRemoteAudioStream(UInt(user_id), mute: mute)
		engine.muteAllRemoteAudioStreams(mute)
	}

	func readyToCaptureStream() -> Bool {
		return true
	}
}

extension AgoraService: AgoraRtcEngineDelegate {
	func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
		observer?.remoteUserDidJoined(user: Int(uid))
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
		let droped = (reason == .dropped)
		observer?.remoteUserDidQuited(user: Int(uid), droped: droped)
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
		observer?.didReceiveRemoteVideo(user: Int(uid))
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
		self.renderVideoFor(user: Int(uid))
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
		let messageJson = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
		if let messsageJson = messageJson as? [String: Any] {
			observer?.didReceiveChannelMessage(message: messsageJson)
		}
	}

	func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
//		if (networkQuality.count > HWNetworkCountMax) {
//			[networkQuality removeObjectAtIndex:0];
//		}
//		[networkQuality addObject:@(quality)];
	}

	func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
		observer?.channelKeyInvalid()
	}
	
	func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
		observer?.remoteUserDidQuited(user: 0, droped: true)
	}
	
	func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int, error: Int, missed: Int, cached: Int) {
		observer?.remoteUserDidQuited(user: 0, droped: true)
	}

	func videoCanvasFor(user user_id: Int) -> AgoraRtcVideoCanvas? {
		guard let background = observer?.remoteViewFor(user: user_id) else {
			return nil
		}
		let videoCanvas = AgoraRtcVideoCanvas.init()
		videoCanvas.uid = UInt.init(user_id)
		videoCanvas.view = background
		videoCanvas.renderMode = .hidden
		return videoCanvas
	}

	func renderVideoFor(user user_id: Int) {
		guard let videoCanvas = videoCanvasFor(user: user_id) else {
			return
		}
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
		engine.pushExternalVideoFrame(videoFrame)
	}
}
