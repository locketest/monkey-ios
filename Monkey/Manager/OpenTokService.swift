//
//  OpenTokService.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

// Replace with your generated session ID
let kSessionId = "1_MX40NTcwMjI2Mn5-MTUzMTMyMTQ2NDQ1OH4rZ2VnZFN2dE92WmNuN1NuWldBdDRhRFB-UH4"
// Replace with your generated token
let kToken = "T1==cGFydG5lcl9pZD00NTcwMjI2MiZzaWc9MWI4YmFkNGFiOTE5YTY1ZGYxNjM0ZThkMzBiODJiOWExZjUwOWFjMzpzZXNzaW9uX2lkPTFfTVg0ME5UY3dNakkyTW41LU1UVXpNVE15TVRRMk5EUTFPSDRyWjJWblpGTjJkRTkyV21OdU4xTnVXbGRCZERSaFJGQi1VSDQmY3JlYXRlX3RpbWU9MTUzMTMyMTQ2NCZub25jZT0tMjEzMTQ0NzA4NyZyb2xlPXB1Ymxpc2hlciZleHBpcmVfdGltZT0xNTMxNDA3ODY0JmNvbm5lY3Rpb25fZGF0YT11c2VyX2lkJTNEMTElMkNjJTNENDE5MDA3YjQtNzZjMi00NjA3LThiNmEtMWM1NzA3MmZiZmJh"

class OpenTokService: NSObject {

	var observer: ChannelServiceProtocol?
	fileprivate weak var channelModel: ChannelModel?

	var publisher: OTPublisherKit?
	var currentSession: OTSession?
	weak var subscriber: OTSubscriberKit?
	weak var subscriberConnection: OTConnection?

	static let shared = OpenTokService()
	override init() {}
}

extension OpenTokService: ChannelServiceManager {
	
	func joinChannel(matchModel: ChannelModel) {
		self.currentSession = OTSession.init(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: matchModel.channel_name, delegate: self)
		var maybeError : OTError?
		self.currentSession?.connect(withToken: matchModel.channel_key, error: &maybeError)
		print("opentok: connect session")

		guard self.currentSession != nil, maybeError == nil else {
			// call back error
			self.observer?.didReceiveChannelError(error: nil)
			return
		}
		self.channelModel = matchModel
	}

	func leaveChannel() {
		var maybeError : OTError?
		print("opentok: disconnect session")
		if let publisher = self.publisher {
			self.currentSession?.unpublish(publisher, error: nil)
			publisher.videoCapture = nil
			self.publisher = nil
		}
		self.currentSession?.disconnect(&maybeError)
		if let error = maybeError {
			self.observer?.didReceiveChannelError(error: error)
		}
	}
	
	func sendMessage(message: MatchMessage) {
		var maybeError : OTError?
		self.currentSession?.signal(withType: message.type, string: message.body, connection: self.subscriberConnection, error: &maybeError)
		
		if let error = maybeError {
			self.observer?.didReceiveChannelError(error: error)
		}
	}

	func mute(user user_id: Int, mute: Bool) {
		self.subscriber?.subscribeToAudio = !mute
	}
	
	func muteAllRemoteUser(mute: Bool) {
		self.subscriber?.subscribeToAudio = !mute
	}
}

extension OpenTokService: OTSessionDelegate {
	func sessionDidConnect(_ session: OTSession) {
		print("opentok: session did connect")

		/**
		* Sets up an instance of OTPublisher to use with this session. OTPubilsher
		* binds to the device camera and microphone, and will provide A/V streams
		* to the OpenTok session.
		*/
		var maybeError : OTError?
		if self.publisher == nil {
			self.publisher = OTPublisher.init(delegate: nil, settings: OTPublisherSettings.init())
			let capture = HWCameraManager.shared()
			self.publisher?.videoCapture = capture
		}
		session.publish(self.publisher!, error: &maybeError)

		if let error = maybeError {
			self.observer?.didReceiveChannelError(error: error)
		}
	}

	func sessionDidDisconnect(_ session: OTSession) {
		print("opentok: did disconnect")
		
		self.observer?.leaveChannelSuccess()
	}

	func sessionDidBeginReconnecting(_ session: OTSession) {
		print("opentok: did begin reconnecting")
	}

	func sessionDidReconnect(_ session: OTSession) {
		print("opentok: did reconnect")
		
		self.observer?.joinChannelSuccess()
	}

	func session(_ session: OTSession, didFailWithError error: OTError) {
		print("opentok: did FailWithError")
		
		self.observer?.didReceiveChannelError(error: nil)
	}

	func session(_ session: OTSession, streamCreated stream: OTStream) {
		print("opentok: did streamCreated")
		
		guard self.subscriber == nil else {
			// Someone is trying to publish a second feed.
			print("opentok: Multiple stream publishes attempted")
			self.observer?.didReceiveChannelError(error: nil)
			return
		}
		guard let subscriber = OTSubscriberKit(stream: stream, delegate: self) else {
			// Someone is trying to publish a second feed.
			print("opentok: Could not create subscriber")
			return
		}

		let videoRender = MonkeyVideoRender(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
		subscriber.videoRender = videoRender
		self.channelModel?.left.container = videoRender
		self.subscriber = subscriber

		var maybeError : OTError?
		session.subscribe(subscriber, error: &maybeError)
		if let error = maybeError {
			print("opentok: Do subscribe error \(error)")
			self.observer?.didReceiveChannelError(error: error)
		}
	}

	func session(_ session: OTSession, streamDestroyed stream: OTStream) {
		print("opentok: did streamDestroyed")
		if stream == self.subscriber?.stream {
			self.observer?.remoteUserDidQuited(user: self.channelModel?.left.user_id ?? 0, droped: true)
		}
	}

	func session(_ session: OTSession, connectionCreated connection: OTConnection) {
		print("opentok: did connectionCreated")

		// i_o = is observer
		if connection.data?.contains("i_o=true") == true {
			print("opentok: Strange connection created")
			// allow us to peek in on different conversations
			return
		}
		guard self.subscriberConnection == nil else {
			print("opentok: Duplicate subscription created")
			return
		}

		self.subscriberConnection = connection
		self.observer?.remoteUserDidJoined(user: self.channelModel?.left.user_id ?? 0)
	}

	func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
		print("opentok: did connectionDestroyed")
		if connection.data?.contains("i_o=true") == true {
			print("opentok: Strange connection destroyed")
			// allow us to peek in on different conversations
			return
		}
	}

	func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
		print("opentok: did receive signal type: \(type ?? ""), body: \(string ?? "")")
		let messageJson = [
			"type": type ?? MessageType.Match.rawValue,
			"body": string ?? "",
		]
		self.observer?.didReceiveChannelMessage(message: messageJson)
	}
}

extension OpenTokService: OTSubscriberKitDelegate {
	func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
		print("opentok: subscriberDidConnectToStream")
		if subscriber.stream == self.subscriber?.stream {
			self.observer?.didReceiveRemoteVideo(user: self.channelModel?.left.user_id ?? 0)
		}
	}

	func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
		print("opentok: subscriber did disconnect")
		if subscriber.stream == self.subscriber?.stream {
			self.observer?.remoteUserDidQuited(user: self.channelModel?.left.user_id ?? 0, droped: true)
		}
	}

	func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {
		print("opentok: subscriber did reconnect")
	}

	func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
		print("opentok: Subscriber didFailWithError \(error)")
	}
	
	func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
		print("opentok: publisher streamCreated")
	}
	
	func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
		print("opentok: publisher streamDestroyed")
	}
	
	func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
		print("opentok: Publisher didFailWithError \(error)")
	}
}
