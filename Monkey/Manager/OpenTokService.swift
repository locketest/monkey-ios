//
//  OpenTokService.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class OpenTokService: NSObject {

	var observer: ChannelServiceProtocol {
		return ChannelService.shared
	}
	var videoFrame = OTVideoFrame()
	var videoCaptureConsumer: OTVideoCaptureConsumer?
	var capturing = false

	var currentSession: OTSession?
	var connections = [OTConnection]()
	weak var subscriber: MonkeySubscriber?
	weak var subscriberConnection: OTConnection?
	var subscriberData: Dictionary<String, String>?

	override init() {
		super.init()
		let videoFormat = OTVideoFormat.init()
		videoFormat.pixelFormat = .ARGB
		videoFormat.imageWidth = 480
		videoFormat.imageHeight = 640
		videoFormat.bytesPerRow = NSMutableArray.init(object: 480 * 4)
		videoFrame.format = videoFormat
	}
}

extension OpenTokService: OTVideoCapture {
	func initCapture() {

	}

	func releaseCapture() {

	}

	func start() -> Int32 {
		runAsynchronouslyOnVideoProcessingQueue {
			self.capturing = true
		}
		return 0
	}

	func stop() -> Int32 {
		runAsynchronouslyOnVideoProcessingQueue {
			self.capturing = false
		}
		return 0
	}

	func isCaptureStarted() -> Bool {
		return capturing
	}

	func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
		videoFormat.pixelFormat = .ARGB
		videoFormat.imageWidth = 480
		videoFormat.imageHeight = 640
		return 0
	}
}

extension OpenTokService: ChannelServiceManager {
	func joinChannel(matchModel: VideoCallProtocol, complete: @escaping CompletionHandler) {
		let session = OTSession.init(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: matchModel.session_id ?? "", delegate: self)
		var maybeError : OTError?
		session?.connect(withToken: matchModel.channelToken, error: &maybeError)

		guard session != nil, maybeError == nil else {
			// call back error
			observer.remoteUserDidQuited(user: Int(matchModel.user?.user_id ?? "0") ?? 0, droped: true)
			return
		}
		complete()
	}

	func leaveChannel(complete: @escaping CompletionHandler) {
		var maybeError : OTError?
		self.currentSession?.disconnect(&maybeError)
		if maybeError != nil {
			// handle error
		}
		complete()
	}

	func sendMessage(message: [String: Any]) {
		// var maybeError : OTError?
		// self.currentSession?.signal(withType: message.type, string: message.body, connection: self.subscriberConnection, error: &maybeError)
		// if maybeError != nil {
		// 	// handle error
		// }
	}

	func mute(user user_id: Int, mute: Bool) {
		self.subscriber?.subscribeToAudio = mute
	}

	func readyToCaptureStream() -> Bool {
		return capturing
	}
}

extension OpenTokService: OTSessionDelegate {
	func sessionDidConnect(_ session: OTSession) {
		print("session did connect")

		/**
		* Sets up an instance of OTPublisher to use with this session. OTPubilsher
		* binds to the device camera and microphone, and will provide A/V streams
		* to the OpenTok session.
		*/
		var maybeError : OTError?
		session.publish(MonkeyPublisher.shared, error: &maybeError)

		if maybeError != nil {
			self.observer.remoteUserDidQuited(user: 0, droped: true)
		}
	}

	func sessionDidDisconnect(_ session: OTSession) {
		print("did disconnect")
	}

	func sessionDidBeginReconnecting(_ session: OTSession) {
		print("did reconnecting")
	}

	func sessionDidReconnect(_ session: OTSession) {
		print("did reconnect")
	}

	func session(_ session: OTSession, didFailWithError error: OTError) {
		print("did FailWithError")
		self.observer.remoteUserDidQuited(user: 0, droped: true)
	}

	func session(_ session: OTSession, streamCreated stream: OTStream) {
		print("did streamCreated")
		guard let subscriber = MonkeySubscriber(stream: stream, delegate: self) else {
			// Someone is trying to publish a second feed.
			print("Could not create subscriber")
			return
		}

		self.subscriber = subscriber
		// Don't subscribe to audio until loading completed
		subscriber.subscribeToAudio = false

		var maybeError : OTError?
		session.subscribe(subscriber, error: &maybeError)
		if let error = maybeError {
			print("Do subscribe error \(error)")
			self.observer.remoteUserDidQuited(user: 0, droped: true)
		}

	}

	func session(_ session: OTSession, streamDestroyed stream: OTStream) {
		print("did streamDestroyed")
		self.observer.remoteUserDidQuited(user: 0, droped: true)
	}

	func session(_ session: OTSession, connectionCreated connection: OTConnection) {
		print("did connectionCreated")
		connections.append(connection)

		guard self.subscriberConnection == nil else {
			print("Duplicate subscription created")
			return
		}

		self.subscriberConnection = connection
	}

	func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
		print("did connectionDestroyed")
		self.observer.remoteUserDidQuited(user: 0, droped: true)
	}

	func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
		let messageJson = [
			"type": type ?? MessageType.Match.rawValue,
			"body": string ?? "",
			"sender": "other",
		]
		observer.didReceiveChannelMessage(message: messageJson)
	}

	func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {

	}

	func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {

	}
}

extension OpenTokService: OTSubscriberKitDelegate {
	func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {

	}

	func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {

	}

	func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {

	}

	func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {

	}

	func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {

	}

	func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {

	}

	func subscriberVideoDisableWarning(_ subscriber: OTSubscriberKit) {

	}

	func subscriberVideoDisableWarningLifted(_ subscriber: OTSubscriberKit) {

	}
}

extension OpenTokService: StreamRawDataHandler {
	func newFrameRawDataAvailable(_ rawData: UnsafeMutablePointer<GLubyte>) {
		videoFrame.clearPlanes()
		videoFrame.planes?.addPointer(rawData)
		videoCaptureConsumer?.consumeFrame(videoFrame)
	}
}
