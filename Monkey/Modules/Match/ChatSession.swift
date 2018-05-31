//
//  ChatSession.swift
//  Monkey
//
//  Created by Isaiah Turner on 11/18/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

enum MonkeyMatchMode : String {
    case videoMode = "videomode"
    case chatMode = "chatmode"
    case funmeetMode = "funmeetmode"
}

class ChatSession: NSObject {
    weak var callDelegate: ChatSessionCallDelegate?
    weak var loadingDelegate: ChatSessionLoadingDelegate?

	var agoraRemoteView: UIView?
	var opentokRemoteView: MonkeyVideoRender? {
		return subscriber?.view
	}

    var chat: Chat? // TODO This actually isnt an optional its always passed in init. cool cool
    var realmCall: RealmCall? {
        let realm = try? Realm()
        return realm?.object(ofType: RealmCall.self, forPrimaryKey: self.chat?.chatId)
    }
	var realmVideoCall: RealmVideoCall? {
		let realm = try? Realm()
		return realm?.object(ofType: RealmVideoCall.self, forPrimaryKey: self.chat?.chatId)
	}
	var videoCall: VideoCallProtocol? {
		if isDialedCall {
			return realmVideoCall
		}else {
			return realmCall
		}
	}

	var remoteView: UIView? {
		if let realmCall = videoCall {
			if realmCall.supportAgora() {
				return agoraRemoteView
			}else {
				return opentokRemoteView
			}
		}
		return nil
	}

	var matchedTime: TimeInterval?
	var acceptTime: TimeInterval?
	var connectTime: TimeInterval?

    var didConnect = false
    var matchUserDidAccept = false
    var isDialedCall = false
    var isReportedChat = false
	var isReportedByOther = false
	var isUnMuteSound = false
	var matchMode: MatchMode = .VideoMode
    var justAddFriend = false

    var message_send = 0
    var message_receive = 0
    var common_tree: String?

	var agoraService = AgoraService.shared
    var session: OTSession?
    var connections = [OTConnection]()
    weak var subscriber: MonkeySubscriber?
    weak var subscriberConnection: OTConnection?
    var subscriberData: Dictionary<String, String>?
    var status: ChatSessionStatus = .loading
    var disconnectReason: DisconnectReason?
    var response: Response? {
        didSet {
			if response == .skipped {
				if self.wasSkippable {
					self.sendSkip()
				}else {
					self.disconnect(.consumed)
				}
			}
        }
    }
    var wasSkippable = false
	var hadAddTime = false {
		willSet {
			if self.hadAddTime == false && newValue == true {
				var toAddInfo = ["match_success_add_time": 1]
				if self.friendMatched == true {
					toAddInfo["match_success_time&friend"] = 1
				}

				AnaliticsCenter.add(amplitudeUserProperty: toAddInfo)
				AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)
			}
		}

		didSet {
			if self.hadAddTime {
				self.track(matchEvent: .matchFirstAddTime)
			}
		}
	}

    var shouldShowRating: Bool {
        return false;
    }

    var friendMatched = false {
        didSet {
            if let callDelegate = self.callDelegate, friendMatched == true {

				var toAddInfo = ["match_success_add_friend": 1]
				if self.hadAddTime == true {
					toAddInfo["match_success_time&friend"] = 1
				}

				AnaliticsCenter.add(amplitudeUserProperty: toAddInfo)
				AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)

				self.track(matchEvent: .matchFirstAddFriend)
				
				if videoCall?.matchedFriendship != nil {
					callDelegate.friendMatched(in: self)
				}else {
					chat?.update(callback: { ( _) in
						callDelegate.friendMatched(in: self)
					})
				}
            }
        }
    }
	fileprivate var sessionStatus: SessionStatus = .disconnected

    /// When a disconnect is completed async, this will be the result (consumed or consumedWithError)
    fileprivate var disconnectStatus: ChatSessionStatus?

    fileprivate(set) var theirSnapchatUsername: String?

    /// The count of checks such as time and subscriber connection that have been completed (should be zero, one, or two)
    fileprivate var initiatorReadyChecks = 0 {
        didSet {
            if self.initiatorReadyChecks == 2 {
				self.startConnect()
                self.tryConnecting()
            }
        }
    }

	fileprivate var didReceiveRemoteVideo = false {
		didSet {
			if didReceiveRemoteVideo {
				self.tryConnecting()
			}
		}
	}

    fileprivate enum SessionStatus {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }

    enum LogType {
        case error
        case warning
        case info
    }
    enum Response {
        case skipped
        case accepted
    }

	func commonParameters(for event: AnalyticEvent) -> [String: String] {
		let currentUser = APIController.shared.currentUser
		let is_banned = currentUser?.is_banned.value ?? false
        var match_type = "video"
		let selectMatchMode = Achievements.shared.selectMatchMode ?? .VideoMode
		if selectMatchMode == .TextMode {
			match_type = "text"
		}else if selectMatchMode == .VideoMode {
			match_type = "video"
		}else {
			match_type = "event"
		}

		var commonParameters = [
			"user_gender": currentUser?.gender ?? "",
			"user_age": "\(currentUser?.age.value ?? 0)",
			"user_country": currentUser?.location ?? "",
			"user_ban": "\(is_banned)",
            "match_type": match_type,
			"auto_accept": Achievements.shared.autoAcceptMatch ? "false" : "true",
			"user_gender_option": APIController.shared.currentUser?.show_gender ?? "both",
			"user_tree": APIController.shared.currentUser?.channels.first?.channel_id ?? "",
            "match_same_tree": common_tree ?? "",
		]

		if let _ = self.realmCall, let chat = chat {
			commonParameters["match_with_gender"] = chat.gender ?? ""
			commonParameters["match_with_country"] = chat.location ?? ""
			commonParameters["match_with_age"] = "\(chat.age ?? 0)"

            var match_with_type = "video"
			let match_with_mode = chat.match_mode
			if match_with_mode == .TextMode {
				match_with_type = "text"
			}else if match_with_mode == .VideoMode {
				match_with_type = "video"
			}else {
				match_with_type = "event"
			}
            commonParameters["match_with_type"] = match_with_type

			var match_room_type = "video"
			if matchMode == .TextMode {
				match_room_type = "text"
			}else if matchMode == .VideoMode {
				match_room_type = "video"
			}else {
				match_room_type = "event"
			}
			commonParameters["match_room_type"] = match_room_type

			if event == .matchFirstAddFriend {
				commonParameters["in_15s"] = "\(!self.hadAddTime)"
			}

			if event == .matchInfo {
				var match_duration = 0
				if let connectTime = connectTime {
					match_duration = Int(Date().timeIntervalSince1970 - connectTime)
				}

				commonParameters["duration"] = "\(match_duration)"
				let time_add = ((self.chat?.minutesAdded ?? 0) > 0)
				commonParameters["time_add"] = "\(time_add)"
				commonParameters["time_add_success_times"] = "\(min(self.chat?.minutesAdded ?? 0, self.chat?.theirMinutesAdded ?? 0))"
				commonParameters["friend_add"] = "\(self.chat?.sharedSnapchat ?? false)"
				commonParameters["firend_add_success"] = "\(self.friendMatched)"
				commonParameters["report"] = "\(self.isReportedChat)"

				if matchMode == .TextMode {
					commonParameters["sound_open"] = "\(self.chat?.unMute ?? false)"
					commonParameters["sound_open_success"] = "\(self.isUnMuteSound)"
                    commonParameters["message_send"] = "\(self.message_send)"
                    commonParameters["message_receive"] = "\(self.message_receive)"
				}

				let filter_title = Achievements.shared.selectMonkeyFilter
				if filter_title != "Normal" {
					commonParameters["filter"] = filter_title
				}
			}
		}

		return commonParameters
	}

	func track(matchEvent: AnalyticEvent) {
		AnaliticsCenter.log(withEvent: matchEvent, andParameter: commonParameters(for: matchEvent))
	}

    required init(apiKey: String, sessionId: String, chat: Chat, token: String, loadingDelegate: ChatSessionLoadingDelegate, isDialedCall: Bool) {
        super.init()

		agoraService.observer = self
        self.sessionStatus = .connecting
        self.isDialedCall = isDialedCall
        self.chat = chat
        self.loadingDelegate = loadingDelegate
		self.matchMode = chat.match_room_mode
		self.matchedTime = NSDate().timeIntervalSince1970
		
		if let friend = videoCall?.matchedFriendship {
			self.theirSnapchatUsername = friend.user?.snapchat_username
			self.chat?.sharedSnapchat = true
			self.chat?.theySharedSnapchat = true
			self.friendMatched = true
		}
		
		if videoCall?.supportSocket() == false {
			self.joinChannel()
		}else {
			Socket.shared.addChatMessageDelegate(chatMessageDelegate: self)
		}

		if isDialedCall == true {
			// Wait up to 30 seconds before giving up on connecting to the session
			DispatchQueue.main.asyncAfter(deadline: .after(seconds: 30)) { [weak self] in
				guard let `self` = self else { return }
				if self.status == .loading || self.status == .skippable {
					print("Call loading timed out")
					self.disconnect(.consumedWithError)
				}
			}
		}else {
			// accept 超时
			DispatchQueue.main.asyncAfter(deadline: .after(seconds: Double(RemoteConfigManager.shared.match_accept_time))) { [weak self] in
				guard let `self` = self else { return }
				if self.response == nil {
					self.disconnect(.consumed)
					print("Inactivity detected")
					MKMatchManager.shareManager.afmCount += 1
					if MKMatchManager.shareManager.needShowAFMAlert {
						self.loadingDelegate?.warnConnectionTimeout?(in: self)
						MKMatchManager.shareManager.afmCount = 0
					}
				}
			}
		}
    }
	
	func joinChannel() {
		guard let realmCall = videoCall else {
			self.log(.error, "Could not connect to session")
			self.disconnect(.consumed)
			return
		}
		
		if realmCall.supportAgora() {
			agoraService.joinChannel(matchModel: realmCall) { [weak self] in
				guard let `self` = self else { return }
				self.joinChannelSuccessful()
			}
		}else {
			self.session = OTSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: realmCall.session_id!, delegate: self)
			var maybeError : OTError?
			session?.connect(withToken: realmCall.token!, error: &maybeError)
			if let error = maybeError {
				self.log(.error, "Could not connect to session \(error)")
				self.disconnect(.consumedWithError)
			}
		}
	}

    deinit {
		Socket.shared.delChatMessageDelegate(chatMessageDelegate: self)
        print("chat session deinit")
    }

	func toggleCameraPosition() {
		HWCameraManager.shared().rotateCameraPosition()
	}
	func toggleFrontCamera(front:Bool) {
		HWCameraManager.shared().changeCameraPosition(to: .front)
	}

    private func tryConnecting() {
        guard self.initiatorReadyChecks == 2 else {
            self.log(.info, "Initiator not ready")
            return
        }
		
		// 双方都 accept，但是没有收到对方的流
        guard self.didReceiveRemoteVideo else {
            self.log(.info, "Stream not ready")
            return
        }

		if matchMode != .TextMode {
			self.subscriber?.subscribeToAudio = true
			agoraService.mute(user: 0, mute: false)
		}
		self.connectTime = NSDate().timeIntervalSince1970
		self.updateStatusTo(.connected)
    }
    /**
     Prints a message to the console.
     */
    func log(_ type: LogType, _ message: String) {
        print(message)
    }

    fileprivate func updateStatusTo(_ newStatus: ChatSessionStatus) {

        if self.status == .consumed || self.status == .consumedWithError {
            // Once a chat session is consumed, it can not change.
            self.log(.warning, "Chat is already consumed as \(self.status) and can not be updated to \(newStatus)")
            return
        }

		if self.status == .connected && newStatus == .disconnecting {

		}

        guard self.status != newStatus else {
            self.log(.warning, "Status is already \(newStatus)")
            return
        }

        self.log(.warning, "Status updated to \(newStatus)")
        self.status = newStatus

        switch newStatus {
        case .connected:
            self.didConnect = true
            self.loadingDelegate?.presentCallViewController(for: self)

			var toAddInfo = ["match_success": 1]
			if self.chat?.gender == Gender.female.rawValue {
				toAddInfo["match_success_f"] = 1
			}else {
				toAddInfo["match_success_m"] = 1
			}

			if self.matchMode == .TextMode {
				toAddInfo["match_success_text"] = 1
			}else if self.matchMode == .VideoMode {
				toAddInfo["match_success_video"] = 1
			}else {
				toAddInfo["match_success_eventmode"] = 1
			}

			AnaliticsCenter.add(amplitudeUserProperty: toAddInfo)
			AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)

			self.track(matchEvent: .matchFirstSuccess)
			self.track(matchEvent: .matchSuccess)

        case .consumed:
            self.loadingDelegate?.chatSession(self, callEndedWithError: nil)
        case .consumedWithError:
            self.loadingDelegate?.chatSession(self, callEndedWithError: NSError.unknownMonkeyError)
        case .disconnecting:
            if self.didConnect {
                self.loadingDelegate?.dismissCallViewController(for: self)
            }
        case .loading:
            break
        case .skippable:
            break
        }
    }

    var messageHandlers = Array<MessageHandler>()
    func add(messageHandler: MessageHandler) {
        for existingMessageHandler in self.messageHandlers {
            guard existingMessageHandler.chatSessionMessagingPrefix != messageHandler.chatSessionMessagingPrefix else {
                print("Duplicate message handler prefix.")
                return
            }
        }
        messageHandler.chatSession = self

        self.messageHandlers.append(messageHandler)
    }

    func send(message: String, from messageHandler: MessageHandler, withType type: String) {

    }

	/**
	Signals that the session should disconnect itself.
	ChatSessionDelegate.statusChangedTo(_ status: ChatSessionStatus) is
	called immediately after disconnect() is called for the first time.
	*/
	func disconnect(_ status: ChatSessionStatus) {
		if self.sessionStatus == .disconnecting || self.sessionStatus == .disconnected {
			// Disconnect in progress.
			self.log(.warning, "Attempting to disconnect while disconnecting")
			return
		}

		if status != .consumed && status != .consumedWithError {
			// Disconnect in progress.
			self.log(.error, "Disconnects must have consumed status")
			return
		}

//		if self.wasSkippable == false {
//			// Wait a few seconds to see if they connect so we can tell them we are leaving.
//			self.disconnectStatus = status
//			self.updateStatusTo(.disconnecting)
//			DispatchQueue.main.asyncAfter(deadline: .after(seconds: 3.0)) { [weak self] in
//				self?.finishDisconnecting()
//			}
//			return
//		}

		if self.status == .connected {
			var match_duration = 0
			if let connectTime = connectTime {
				match_duration = Int(Date().timeIntervalSince1970 - connectTime)
			}
			var toAddInfo = ["match_duration_total": match_duration]
			AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)

			if self.matchMode == .TextMode {
				toAddInfo["match_duration_total_text"] = match_duration
			}else if self.matchMode == .VideoMode {
				toAddInfo["match_duration_total_video"] = match_duration
			}else {
				toAddInfo["match_duration_total_eventmode"] = match_duration
			}
			AnaliticsCenter.add(amplitudeUserProperty: toAddInfo)

			self.track(matchEvent: .matchInfo)
			self.disconnectStatus = status
			self.updateStatusTo(.disconnecting)
		} else {
			self.updateStatusTo(status)
		}
		self.sessionStatus = .disconnecting
		self.finishDisconnecting()
	}

	fileprivate func finishDisconnecting() {
		log(.info, "Disconnecting")
		guard let realmCall = videoCall else {
			// Disconnect in progress.
			self.log(.error, "Disconnects must have consumed status")
			return
		}

		runAsynchronouslyOnVideoProcessingQueue {
			HWCameraManager.shared().opentok_capture = false
			HWCameraManager.shared().agora_capture = false
		}
		
		if realmCall.supportAgora() {
			self.agoraService.leaveChannel {
				self.sessionStatus = .disconnected
				self.updateStatusTo(self.disconnectStatus ?? .consumed)
			}
		}else {
			var maybeError : OTError?
			self.session?.disconnect(&maybeError)
			if let error = maybeError {
				self.log(.error, "Disconnect error \(error)")
				self.updateStatusTo(.consumedWithError)
				return
			}
			self.session = nil
			self.sessionStatus = .disconnected
			self.updateStatusTo(self.disconnectStatus ?? .consumed)
		}
	}

	func joinChannelSuccessful() {
		self.log(.info, "\(self) sessionDidConnect")

		self.sessionStatus = .connected
	}

	func sessionConnectSuccessful() {
		AnaliticsCenter.log(withEvent: .opentokConnected, andParameter: [
			"duration": Int(NSDate().timeIntervalSince1970 - self.matchedTime!),
			])

		self.wasSkippable = true
		self.updateStatusTo(.skippable)
		if self.response == .skipped {
			self.sendSkip()
		}else if self.response == .accepted, videoCall?.supportSocket() == false {
			self.accept()
		}
	}

	func startReceiveRemoteVideo() {
		self.log(.info, "session streamCreated")
		self.didReceiveRemoteVideo = true
	}

	func startConnect() {
		self.loadingDelegate?.shouldShowConnectingStatus(in: self)
		AnaliticsCenter.add(amplitudeUserProperty: ["match_connect": 1])
		AnaliticsCenter.add(firstdayAmplitudeUserProperty: ["match_connect": 1])
		self.track(matchEvent: .matchConnect)
		
		if videoCall?.supportSocket() == true {
			self.joinChannel()

			if let realmCall = videoCall, realmCall.supportAgora() {
				runAsynchronouslyOnVideoProcessingQueue {
					HWCameraManager.shared().agora_capture = true
				}
			}else {
				runAsynchronouslyOnVideoProcessingQueue {
					HWCameraManager.shared().opentok_capture = true
				}
			}
		}
		
		guard self.status != .connected else {
			return
		}

		let callLoadingTimeout = Double(RemoteConfigManager.shared.match_connect_time)
		DispatchQueue.main.asyncAfter(deadline: .after(seconds: callLoadingTimeout)) { [weak self] in
			guard let `self` = self else { return }
			if self.status == .skippable {
				print("Call loading timed out")
				self.disconnect(.consumed)
			}
		}
	}
}

/**
 ChatSessionStatus describes how the view should appear
*/
enum ChatSessionStatus {
    ///The chat session should be released, it's not going to connect to anyone. Get a new chat.
    case consumed
    ///The chat session should be released, it's not going to connect to anyone. Get a new chat after accepting user input.
    case consumedWithError
    ///The chat is connecting and for a period of time can be skipped
    case skippable
    ///The chat is connected and the video screen should be shown
    case connected
    ///The chat is developing the initial connection and the loading view should be show
    case loading
    ///The chat is about to be consumed but still has something to do (like open snapchat). Don't make a new chat yet.
    case disconnecting
}

enum DisconnectReason {
    case initiatorNotReady
    case matchNotReady
}

/**
 ChatSessionDelegate enum description
 */

protocol ChatSessionCallDelegate: class {
	func friendMatched(in chatSession: ChatSession?)
	func minuteAdded(in chatSession: ChatSession)
	func soundUnMuted(in chatSession: ChatSession)
    func opponentDidTurnToBackground(in chatSession: ChatSession)

	func received(textMessage: TextMessage, in chatSession: ChatSession)
}

protocol MessageHandler: class {
	var chatSession: ChatSession? { get set }
    var chatSessionMessagingPrefix: String { get }
    func chatSession(_ chatSession: ChatSession, received message: String, from connection: OTConnection, withType type: String)
    func chatSession(_ chatSession: ChatSession, statusChangedTo status: ChatSessionStatus)
    func chatSesssion(_ chatSesssion: ChatSession, connectionCreated connection: OTConnection)
}

@objc protocol ChatSessionLoadingDelegate: class {
    func presentCallViewController(for chatSession: ChatSession)
    func dismissCallViewController(for chatSession: ChatSession)
    func chatSession(_ chatSession: ChatSession, callEndedWithError error: Error?)
	func shouldShowConnectingStatus(in chatSession: ChatSession)
    @objc optional func warnConnectionTimeout(in chatSession: ChatSession)
}

extension ChatSession {

	@discardableResult func send(messageType: MessageType, body: String? = "") -> Bool {
		guard let realmCall = videoCall else {
			return false
		}
		guard let currentChat = self.chat else {
			self.log(.error, "Missing chat")
			return false
		}

		guard wasSkippable == true else {
			if videoCall?.supportSocket() == true, messageType == .Skip || messageType == .Accept {

				let socket_channel = isDialedCall ? "videocall_pos_request" : "pos_match_request"
				Socket.shared.send(message: [
					"data": [
						"type": socket_channel,
						"attributes": [
							"match_action": messageType.rawValue, // skip or ready
							"chat_id": currentChat.chatId, // chat_id
							"matched_user": [currentChat.user_id ?? ""], // array of user ids
						]
					]
					], to: socket_channel, completion: { (error, _) in
						guard error == nil else {
							print("Error: Unable to send message")
							return
						}
				})
				return true
			}
			
			return false
		}

		if realmCall.supportAgora() {
			let message: [String: Any] = [
				"type": messageType.rawValue,
				"body": body ?? "",
				"sender": APIController.shared.currentUser?.user_id ?? "",
				"time": Date().timeIntervalSince1970,
				]
			agoraService.sendMessage(message: message)
		}else {
			guard let connection = self.subscriberConnection else {
				// call will be accepted as soon as the subscriber connected
				self.log(.error, "not connected")
				return false
			}

			var maybeError : OTError?
			self.session?.signal(withType: messageType.rawValue, string: body, connection: connection, retryAfterReconnect: true, error: &maybeError)
			if let error = maybeError {
				self.disconnect(.consumedWithError)
				self.log(.error, "Ready signal error \(error)")
			}
		}
		return true
	}

	fileprivate func receive(messageType: MessageType, body: String? = "") {
		switch messageType {
		case .AddTime:
			if (body == "minute") {
				self.chat?.theirMinutesAdded += 1
				if self.chat!.minutesAdded >= self.chat!.theirMinutesAdded {
					self.log(.info, "Adding minute")
					self.hadAddTime = true
					self.callDelegate?.minuteAdded(in: self)
				}
			}
		case .AddFriend:
			self.chat?.theySharedSnapchat = true
			self.theirSnapchatUsername = body
			if self.chat?.sharedSnapchat == true {
				self.log(.info, "Openning snapchat")
				self.friendMatched = true
				self.justAddFriend = true
			}
		case .Accept:
			self.matchUserDidAccept = true
			self.initiatorReadyChecks += 1
		case .UnMute:
			self.chat?.theyUnMute = true
			if self.chat?.unMute == true {
				self.isUnMuteSound = true
				self.subscriber?.subscribeToAudio = true
				self.agoraService.mute(user: 0, mute: false)
				self.callDelegate?.soundUnMuted(in: self)
			}
		case .Skip:
			self.disconnect(.consumed)
		case .Report:
			self.chat?.reported = true
			self.isReportedChat = true
			self.isReportedByOther = true
		case .Typing:
			let messageInfo = [
				"type": messageType.rawValue,
				"body": body ?? "",
				"sender": realmCall?.user?.user_id ?? ""
			]
			if let textMessage = Mapper<TextMessage>().map(JSON: messageInfo) {
				self.callDelegate?.received(textMessage: textMessage, in: self)
			}
		case .Text:
			self.message_receive += 1
			let messageInfo = [
				"type": messageType.rawValue,
				"body": body ?? "",
				"sender": realmCall?.user?.user_id ?? ""
			]
			if let textMessage = Mapper<TextMessage>().map(JSON: messageInfo) {
				self.callDelegate?.received(textMessage: textMessage, in: self)
			}
		case .Background:
			self.callDelegate?.opponentDidTurnToBackground(in: self)
			break
		default: break
		}
	}

	func accept() {
		if self.response == nil {
			self.response = .accepted
			self.acceptTime = NSDate().timeIntervalSince1970

			if self.matchUserDidAccept == false, self.isDialedCall == false {
				DispatchQueue.main.asyncAfter(deadline: .after(seconds: Double(RemoteConfigManager.shared.match_waiting_time))) { [weak self] in
					guard let `self` = self else { return }
					if self.matchUserDidAccept == false {
						self.disconnectReason = .matchNotReady
						self.disconnect(.consumed)
					}
				}
			}
		}

		// 如果是老版本，accept 时，发送 stream
		if videoCall?.supportSocket() == false {
			if let realmCall = videoCall, realmCall.supportAgora() {
				runAsynchronouslyOnVideoProcessingQueue {
					HWCameraManager.shared().agora_capture = true
				}
			}else {
				runAsynchronouslyOnVideoProcessingQueue {
					HWCameraManager.shared().opentok_capture = true
				}
			}
		}

		if self.send(messageType: MessageType.Accept) {
			self.log(.info, "Ready")
			self.initiatorReadyChecks += 1
		}
	}

	/**
	Sends a snapchat username to the other client.

	- Parameter username:   The string of the current user's Snapchat.

	- Returns: isWaiting. Wether the other person still has to tap Add Snapchat.
	*/
	func sendSnapchat(username: String) -> Bool {
		if isReportedChat {
			return false
		}

		self.send(messageType: MessageType.AddFriend, body: username)

		self.chat?.sharedSnapchat = true
		self.friendMatched = self.chat?.theySharedSnapchat ?? false

		return !self.friendMatched
	}

	func sentUnMute() {
		if isReportedChat {
			return
		}

		self.send(messageType: MessageType.UnMute)

		self.chat?.unMute = true
		if self.chat?.theyUnMute == true {
			self.isUnMuteSound = true

			self.agoraService.mute(user: 0, mute: false)
			self.subscriber?.subscribeToAudio = true
			self.callDelegate?.soundUnMuted(in: self)
		}
	}

	func sentReport() {
		self.send(messageType: MessageType.Report, body: "Report")

		self.chat?.reporting = true
		self.isReportedChat = true
		self.chat?.reported = true

		if (hadAddTime || friendMatched || matchMode != .VideoMode) {
			self.disconnect(.consumed)
		}
	}

	func sentTypeStatus() {

		self.send(messageType: MessageType.Typing, body: "Typing")
	}

	func sentTextMessage(text: String) {
		self.send(messageType: MessageType.Text, body: text)
		self.message_send += 1
	}

	func userTurnIntoBackground() {
		self.send(messageType: MessageType.Background)
	}

	/**
	Sends a request for a minute and adds one if it's already available.

	- Returns: isWaiting. Whether the other person still has to tap Add Minute.
	*/
	func sendMinute() -> Bool {
		if self.isReportedChat {
			return false
		}

		self.send(messageType: MessageType.AddTime, body: "minute")

		self.chat?.minutesAdded += 1
		if let theirMinutesAdded = self.chat?.theirMinutesAdded, let minutesAdded = self.chat?.minutesAdded, theirMinutesAdded >= minutesAdded {
			self.log(.info, "Adding minute")
			self.callDelegate?.minuteAdded(in: self)
			self.hadAddTime = true
			return false
		}

		return true
	}

	fileprivate func sendSkip() {

		self.send(messageType: MessageType.Skip)
		self.disconnect(.consumed)
	}
}

extension ChatSession: OTSessionDelegate {

	internal func sessionDidConnect(_ session: OTSession) {
		self.sessionStatus = .connected
		/**
		* Sets up an instance of OTPublisher to use with this session. OTPubilsher
		* binds to the device camera and microphone, and will provide A/V streams
		* to the OpenTok session.
		*/
		var maybeError : OTError?
		session.publish(MonkeyPublisher.shared, error: &maybeError)

		if let error = maybeError {
			self.disconnect(.consumedWithError)
			self.log(.error, "Do publish error \(error)")
		}
	}

	// session will not always be defined
	internal func sessionDidDisconnect(_ session : OTSession) {
		self.log(.info, "Session disconnected")
		self.disconnect(.consumed)
	}

	func session(_ session: OTSession, streamCreated stream: OTStream) {
		self.log(.info, "session streamCreated")
		guard self.subscriber == nil else {
			// Someone is trying to publish a second feed.
			self.log(.error, "Multiple stream publishes attempted")
			self.disconnect(.consumedWithError)
			return
		}
		guard let subscriber = MonkeySubscriber(stream: stream, delegate: self) else {
			// Someone is trying to publish a second feed.
			self.log(.error, "Could not create subscriber")
			self.disconnect(.consumedWithError)
			return
		}
		guard self.disconnectStatus == nil else {
			self.log(.info, "Not subscribing to stream durring disconnecting")
			return
		}
		self.subscriber = subscriber
		// Don't subscribe to audio until loading completed
		subscriber.subscribeToAudio = false

		var maybeError : OTError?
		session.subscribe(subscriber, error: &maybeError)
		if let error = maybeError {
			if error.code == 1015 { // Session in illegal state
				self.disconnect(.consumed)
				return
			}
			self.disconnect(.consumedWithError)
			self.log(.error, "Do subscribe error \(error)")
		}
	}

	func session(_ session: OTSession, streamDestroyed stream: OTStream) {
		self.log(.info, "session streamDestroyed")
		self.disconnect(.consumed)
	}


	func session(_ session: OTSession, connectionCreated connection : OTConnection) {
		connections.append(connection)
		self.log(.info, "session connectionCreated")
		// i_o = is observer
		if connection.data?.contains("i_o=true") == true {
			self.log(.info, "Strange connection created")
			// allow us to peek in on different conversations
			return
		}
		guard self.subscriberConnection == nil else {
			self.log(.info, "Duplicate subscription created")
			self.disconnect(.consumed)
			return
		}
		guard self.status != .disconnecting else {
			self.finishDisconnecting()
			return
		}
		for messageHandler in messageHandlers {
			messageHandler.chatSesssion(self, connectionCreated: connection)
		}

		self.subscriberConnection = connection
		self.sessionConnectSuccessful()
	}

	func session(_ session: OTSession, connectionDestroyed connection : OTConnection) {
		self.log(.info, "session connectionDestroyed")
		let isConnectionRemovalSuccessful = connections.removeObject(object: connection)
		print("isConnectionRemovalSuccessful \(isConnectionRemovalSuccessful)")
		if connection.data?.contains("i_o=true") == true {
			self.log(.info, "Strange connection destroyed")
			// allow us to peek in on different conversations
			return
		}
		self.disconnect(.consumed)
	}

	func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
		self.log(.info, "session receivedSignalType \(type ?? "unknown type") with \(string ?? "unknown value")")
		guard let connection = connection, connection == self.subscriberConnection else {
			self.log(.error, "Received message from unknown connection")
			return
		}
		guard let type = type else {
			self.log(.error, "Signal missing type")
			return
		}
		guard let message = string else {
			self.log(.error, "Received a signal (OpenTok messaging) without a message string")
			return
		}
		for messageHandler in messageHandlers {
			if type.hasPrefix(messageHandler.chatSessionMessagingPrefix) {
				messageHandler.chatSession(self, received: message, from: connection, withType: type.replacingFirstOccurrence(of: "\(messageHandler.chatSessionMessagingPrefix)-", withString: ""))
				return
			}
		}

		self.receive(messageType: MessageType.init(type: type) ?? MessageType.Normal, body: string)
	}

	func session(_ session: OTSession, didFailWithError error: OTError) {
		self.log(.info, "session didFailWithError \(error)")
		self.disconnect(.consumedWithError)
		// sessionDidDisconnect (sometimes) called right after
		AnaliticsCenter.log(withEvent: .opentokError, andParameter: [
			"channel": "session",
			"code": error.code,
			"duration": Int(NSDate().timeIntervalSince1970 - self.matchedTime!),
			])
	}
}

extension ChatSession: OTSubscriberKitDelegate {
	// MARK: - OTSubscriber delegate callbacks
	/**
	* Sent when the subscriber successfully connects to the stream.
	* @param subscriber The subscriber that generated this event.
	*/
	public func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
		self.log(.info, "subscriberDidConnectToStream")
		if subscriberKit.stream == self.subscriber?.stream {
			self.startReceiveRemoteVideo()
		}
	}

	func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
		self.log(.info, "subscriberDidDisconnect")
		self.disconnect(.consumed)
	}
	func subscriberDidReconnect(toStream subscriberKit: OTSubscriberKit) {
		self.log(.info, "subscriberDidReconnectToStream")
	}

	func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error : OTError) {
		self.log(.info, "subscriber didFailWithError \(error)")
		self.disconnect(.consumedWithError)
		AnaliticsCenter.log(withEvent: .opentokError, andParameter: [
			"channel": "subscriber",
			"code": error.code,
			"duration": Int(NSDate().timeIntervalSince1970 - self.matchedTime!),
			])
	}

	func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
		self.log(.info, "publisher streamCreated")
	}

	func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
		self.log(.info, "publisher streamDestroyed")
		if self.status != .consumed && self.status != .consumedWithError {
			self.disconnect(.consumed)
		}
	}

	func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
		self.log(.info, "publisher didFailWithError \(error)")
		self.disconnect(.consumedWithError)
		AnaliticsCenter.log(withEvent: .opentokError, andParameter: [
			"channel": "publisher",
			"code": error.code,
			"duration": Int(NSDate().timeIntervalSince1970 - self.matchedTime!),
			])
	}
}

extension ChatSession: ChannelServiceProtocol {
	func remoteViewFor(user user_id: Int) -> UIView? {
		if self.agoraRemoteView == nil {
			self.agoraRemoteView = UIView.init()
		}
		return self.agoraRemoteView
	}

	func remoteUserDidJoined(user user_id: Int) {
		self.agoraService.mute(user: 0, mute: true)
		self.sessionConnectSuccessful()
	}

	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		self.log(.info, "agora disconnect")
		self.disconnect(.consumedWithError)
	}

	func didReceiveRemoteVideo(user user_id: Int) {
		self.startReceiveRemoteVideo()
	}

	func channelKeyInvalid() {

	}

	func didReceiveChannelMessage(message: [String : Any]) {
		self.receive(messageType: MessageType.init(type: message["type"] as? String ?? "") ?? MessageType.Normal, body: message["body"] as? String)
	}
}
