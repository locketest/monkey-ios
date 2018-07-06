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

	// 配到的时间
	var matchedTime: TimeInterval?
	// 点击 accept 的时间
	var acceptTime: TimeInterval?
	// connect 的时间
	var connectTime: TimeInterval?

	// 是不是 video call
	var isDialedCall = false
	// 对方是否进入当前 channel
	var wasSkippable = false
	// 对方是否 accept
    var matchUserDidAccept = false
	// 是否 auto skip 了对方
	var  auto_skip = false
	// 是否见到脸
	var didConnect = false
	// 是否举报了对方
    var isReportedChat = false
	// 是否被对方举报了
	var isReportedByOther = false
	// 是否 unmute 成功
	var isUnMuteSound = false
	// 当前 match mode
	var matchMode: MatchMode = .VideoMode

	// 发送文本消息的个数
    var message_send = 0
	// 收到文本消息的个数
    var message_receive = 0
	// 相同的 channel
    var common_tree: String?

	var agoraService = AgoraService.shared
    var session: OTSession?
    var connections = [OTConnection]()
    weak var subscriber: MonkeySubscriber?
    weak var subscriberConnection: OTConnection?
	
	// 当前配对状态
	/**
	*	.loading 默认状态
	*	.skippable 对方进入房间
	*	.connected 已经见到对方
	*	.disconnecting 正在断开连接
	*	.consumed 断开连接
	*	.consumedWithError 因为 opentok 问题导致退出
	*/
	var status: ChatSessionStatus = .loading
	
	// 当前配对状态
	/**
	*	.connecting 正在连接
	*	.connected 连接成功
	*	.disconnecting 正在断连
	*	.disconnected 断连成功
	*/
	fileprivate var sessionStatus: SessionStatus = .disconnected
	
	/// When a disconnect is completed async, this will be the result (consumed or consumedWithError)
	fileprivate var disconnectStatus: ChatSessionStatus?
	
	// 我的操作 skip / accept
    var response: Response? {
        didSet {
			if response == .skipped {
				// 当我点击了 accept 或者 skip，取消 responseTimeout 定时
				NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(responseTimeout), object: nil)
				self.sendSkip()
				self.disconnect(.consumed)
			}
        }
    }
	
	// 是否加成功过时间
	var hadAddTime = false {
		willSet {
			if self.hadAddTime == false && newValue == true {
				var toAddInfo = ["match_success_add_time": 1]
				if self.friendMatched == true {
					toAddInfo["match_success_time&friend"] = 1
				}

				AnalyticsCenter.add(amplitudeUserProperty: toAddInfo)
				AnalyticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)
			}
		}

		didSet {
			if self.hadAddTime {
				self.track(matchEvent: .matchFirstAddTime)
			}
		}
	}

	// 是否是好友
    var friendMatched = false {
        didSet {
            if let callDelegate = self.callDelegate, friendMatched == true {
				
				if videoCall?.matchedFriendship != nil {
					callDelegate.friendMatched(in: self)
				}else {
					chat?.update(callback: { ( _) in
						callDelegate.friendMatched(in: self)
					})
				}

				if chat?.sharedSnapchat == true && chat?.theySharedSnapchat == true {
					
					var toAddInfo = ["match_success_add_friend": 1]
					if self.hadAddTime == true {
						toAddInfo["match_success_time&friend"] = 1
					}
					
					AnalyticsCenter.add(amplitudeUserProperty: toAddInfo)
					AnalyticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)
					
					self.track(matchEvent: .matchFirstAddFriend)
				}
            }
        }
    }

    /// The count of checks such as time and subscriber connection that have been completed (should be zero, one, or two)
    fileprivate var initiatorReadyChecks = 0 {
        didSet {
            if self.initiatorReadyChecks == 2 {
				NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(waitResponseTimeout), object: nil)
				NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dialedCallTimeout), object: nil)
				self.startConnect()
                self.tryConnecting()
            }
        }
    }

	// 收到对方的 accept 消息
	func didReceiveAccept() {
		if matchUserDidAccept == false {
			self.matchUserDidAccept = true
			self.initiatorReadyChecks += 1
		}
	}

	// 收到对方的视频流
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
	
	enum Response: String {
        case skipped = "skipped"
        case accepted = "accepted"
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
			"auto_accept": Achievements.shared.autoAcceptMatch ? "true" : "false",
			"user_gender_option": APIController.shared.currentUser?.show_gender ?? "both",
			"user_tree": APIController.shared.currentUser?.channels.first?.title ?? "",
            "match_same_tree": common_tree ?? "",
			"nearby_status": Achievements.shared.nearbyMatch ? "true" : "false",
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
		AnalyticsCenter.log(withEvent: matchEvent, andParameter: commonParameters(for: matchEvent))
	}

	func trackMatchingSession() {
		guard let chat = chat, let currentUser = APIController.shared.currentUser else {
			return
		}

		var Mode_type = "1"
		if matchMode == .TextMode {
			Mode_type = "2"
		}else if matchMode == .EventMode {
			Mode_type = "3"
		}

		var match_duration = 0
		if let connectTime = connectTime {
			match_duration = Int(Date().timeIntervalSince1970 - connectTime)
		}

		var report_type = "Non-report"
		if chat.showReport > 0 {
			report_type = chat.reportReason?.eventTrackValue() ?? "Cancel"
		}

		var sessionParameters: [String: Any] = [
			"duration": match_duration,
			"friend_add_request": chat.sharedSnapchat ? "1" : "0",
			"friend_add_success": chat.sharedSnapchat && chat.theySharedSnapchat ? "true" : "false",
			"matching_report_click": chat.showReport,
			"matching_report_type": report_type,
			"matching_switch_camera_click": chat.switch_camera_click,
			"matching_switch_camera_result": chat.switch_camera_click % 2 == 0 ? "Front" : "back",
			"Mode_type": Mode_type,
			"user_tree": APIController.shared.currentUser?.channels.first?.title ?? "",
			"nearby_status": Achievements.shared.nearbyMatch ? "true" : "false",
			]

		if friendMatched {
			sessionParameters["pce out"] = (chat.my_pce_out ? currentUser.user_id : chat.user_id) ?? ""
		}

		let cuttentFilter = Achievements.shared.selectMonkeyFilter
		if matchMode == .TextMode {
			sessionParameters["sound_open_click"] = chat.unMute ? "true" : "false"
			sessionParameters["sound_open_success"] = chat.unMute && chat.theyUnMute ? "true" : "false"
			sessionParameters["message_send"] = chat.sendedMessage
			sessionParameters["message_receive"] = chat.receivedMessage
		}else if matchMode == .VideoMode {
			sessionParameters["matching_vfilter_click"] = chat.initialFilter == cuttentFilter ? "keep" : "Change"
			sessionParameters["matching_vfilter_info"] = cuttentFilter
			sessionParameters["time_add_count"] = chat.minutesAdded
			sessionParameters["time_add_success_times"] = min(chat.minutesAdded, chat.theirMinutesAdded)
		}

		AnalyticsCenter.log(withEvent: .matchingSession, andParameter: sessionParameters)
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

		// 是否匹配到好友
		if videoCall?.matchedFriendship != nil {
			self.friendMatched = true
		}

		// 如果支持 accept 前置，就添加 socket 监听，否则直接进入 channel
		if videoCall?.supportSocket() == false {
			self.joinChannel()
		}else {
			Socket.shared.addChatMessageDelegate(chatMessageDelegate: self)
		}

		// 等待响应超时
		if isDialedCall == true {
			// Wait up to 30 seconds before giving up on connecting to the session
			self.perform(#selector(dialedCallTimeout), with: nil, afterDelay: 30)
		}else {
			// 操作超时
			let responseTime = Double(RemoteConfigManager.shared.match_accept_time)
			self.perform(#selector(responseTimeout), with: nil, afterDelay: responseTime)
		}
    }
	
	func dialedCallTimeout() {
		// 对方没有 accept 或者自己没有 accept video call
		if self.status == .loading || self.status == .skippable {
			print("Call loading timed out")
			self.disconnect(.consumed)
		}
	}
	
	func responseTimeout() {
		// 没有操作，并且对方也没有 skip
		if self.response == nil && (self.status == .loading || self.status == .skippable) {
			self.auto_skip = true

			AnalyticsCenter.log(withEvent: .matchWaitTimeout, andParameter: [
				"reason": "myself timeout"
				])
			
			LogManager.shared.addLog(type: .CustomLog, subTitle: "operation timeout - 5s", info: [
				"video_service": self.videoCall?.video_service ?? "",
				"notify_accept": self.videoCall?.supportSocket() ?? false,
				"operation": "auto skip",
				"show_skip": false,
				])
			
			MKMatchManager.shareManager.afmCount += 1
			if MKMatchManager.shareManager.needShowAFMAlert {
				self.loadingDelegate?.warnConnectionTimeout?(in: self)
				MKMatchManager.shareManager.afmCount = 0
			}
			
			self.sendSkip()
		}
	}
	
	func waitResponseTimeout() {
		// 如果对方没有 accept
		if self.matchUserDidAccept == false && (self.status == .loading || self.status == .skippable) {
			self.disconnect(.consumed)
			
			AnalyticsCenter.log(withEvent: .matchWaitTimeout, andParameter: [
				"reason": "the other timeout",
				])
			
			LogManager.shared.addLog(type: .CustomLog, subTitle: "wait accept timeout", info: [
				"video_service": self.videoCall?.video_service ?? "",
				"notify_accept": self.videoCall?.supportSocket() ?? false,
				"show_timeout": true,
				])
		}
	}
	
	func connectingTimeout() {
		// 连接超时(此时对方有可能进入房间，也有可能没进入房间)
		if self.status == .loading || self.status == .skippable {
			
			var reason = "no face"
			if (self.sessionStatus == .connecting) {
				reason = "failed myself"
			}else if (self.status == .loading) {
				reason = "failed the other"
			}
			AnalyticsCenter.log(withEvent: .matchConnectingFailed, andParameter: [
				"reason": reason,
				])
			self.track(matchEvent: .matchConnectTimeOut)
			
			LogManager.shared.addLog(type: .CustomLog, subTitle: "connect timeout", info: [
				"video_service": self.videoCall?.video_service ?? "",
				"notify_accept": self.videoCall?.supportSocket() ?? false,
				"show_timeout": true,
				])
			
			print("Call loading timed out")
			self.disconnect(.consumed)
		}
	}
	
	// 老版本
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
        print("chat session deinit")
    }

	func toggleCameraPosition() {
		chat?.switch_camera_click += 1
		HWCameraManager.shared().rotateCameraPosition()
	}
	func toggleFrontCamera(front: Bool) {
		HWCameraManager.shared().changeCameraPosition(to: .front)
	}

    private func tryConnecting() {
        guard self.initiatorReadyChecks == 2 else {
            self.log(.info, "Initiator not ready")
            return
        }

		// 双方都 accept，但是没有收到对方的流
        guard self.didReceiveRemoteVideo == true else {
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

			AnalyticsCenter.add(amplitudeUserProperty: toAddInfo)
			AnalyticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)

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

		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(responseTimeout), object: nil)
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(waitResponseTimeout), object: nil)
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(connectingTimeout), object: nil)
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dialedCallTimeout), object: nil)
		
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
			AnalyticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)

			if self.matchMode == .TextMode {
				toAddInfo["match_duration_total_text"] = match_duration
			}else if self.matchMode == .VideoMode {
				toAddInfo["match_duration_total_video"] = match_duration
			}else {
				toAddInfo["match_duration_total_eventmode"] = match_duration
			}
			AnalyticsCenter.add(amplitudeUserProperty: toAddInfo)

			self.track(matchEvent: .matchInfo)
			self.trackMatchingSession()
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
		Socket.shared.delChatMessageDelegate(chatMessageDelegate: self)
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

	// 和对方建立连接成功
	func sessionConnectSuccessful() {
		self.wasSkippable = true
		self.updateStatusTo(.skippable)
		
		if self.response == .skipped {
			// 连接成功时，如果发现 response 是 skip，补发 skip
			self.sendSkip()
		}else if self.response == .accepted, videoCall?.supportSocket() == false {
			// 如果是老版本，补发 accept
			self.accept()
		}
	}

	// 开始收到对方的视频流
	func startReceiveRemoteVideo() {
		if self.didReceiveRemoteVideo == false {
			self.log(.info, "session streamCreated")
			self.didReceiveRemoteVideo = true
		}
	}

	// 如果两个人都 accept，开始连接
	func startConnect() {
		self.loadingDelegate?.shouldShowConnectingStatus(in: self)
		AnalyticsCenter.add(amplitudeUserProperty: ["match_connect": 1])
		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_connect": 1])
		self.track(matchEvent: .matchConnect)

		// 如果是老版本，已经收到对方的视频流，直接返回
		guard self.status != .connected else {
			return
		}
		
		// 如果是新版本，开始连接时才会进入 channel
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

		// if begin connecting, waiting for connecting
		let callLoadingTimeout = Double(RemoteConfigManager.shared.match_connect_time)
		self.perform(#selector(connectingTimeout), with: nil, afterDelay: callLoadingTimeout)
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
			// 如果是老版本，并且对方不在房间内， skip 和 accept 消息通过 socket 发送
			if videoCall?.supportSocket() == true, messageType == .Skip || messageType == .Accept {

				let socket_channel = isDialedCall ? "videocall_pos_request" : "pos_match_request"
				Socket.shared.send(message: [
					"data": [
						"type": socket_channel,
						"attributes": [
							"match_action": messageType.rawValue, // skip or ready
							"chat_id": currentChat.chatId, // chat_id
							"send_time": Date().timeIntervalSince1970,
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

		if messageType == .Text {
			chat?.sendedMessage += 1
		}

		// 分别通过 agora 或 opentok 发送房间内消息
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
			if chat?.theySharedSnapchat == false {
				self.chat?.theySharedSnapchat = true
				self.friendMatched = self.chat?.sharedSnapchat ?? false
			}
		case .Accept:
			self.didReceiveAccept()
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
			
			LogManager.shared.addLog(type: .CustomLog, subTitle: "receive skip", info: [
				"video_service": self.videoCall?.video_service ?? "",
				"notify_accept": self.videoCall?.supportSocket() ?? false,
				"operation": self.response?.rawValue ?? "no operation",
				"connected": self.didConnect,
				"show_skip": self.didConnect ? false : true,
				])
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
			self.chat?.receivedMessage += 1
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
		// 如果还没有 response
		if self.response == nil {
			self.response = .accepted
			self.acceptTime = NSDate().timeIntervalSince1970

			// if other not accept, and is not dialed call
			if self.matchUserDidAccept == false, self.isDialedCall == false {
				// waiting for accept
				let waitResponseTime = Double(RemoteConfigManager.shared.match_waiting_time)
				self.perform(#selector(waitResponseTimeout), with: nil, afterDelay: waitResponseTime)
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

		// 如果能发送 accept，尝试进入 connecting
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
	func sendSnapchat(username: String) {
		if isReportedChat {
			return
		}

		self.send(messageType: MessageType.AddFriend, body: username)
		self.chat?.sharedSnapchat = true
		self.friendMatched = self.chat?.theySharedSnapchat ?? false
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

		LogManager.shared.addLog(type: .CustomLog, subTitle: "send skip", info: [
			"video_service": self.videoCall?.video_service ?? "",
			"notify_accept": self.videoCall?.supportSocket() ?? false,
			"operation": self.response?.rawValue ?? "no operation",
			"connected": self.didConnect,
			"show_skip": false,
			])
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
			LogManager.shared.addLog(type: .CustomLog, subTitle: "join opentok error", info: [
				"video_service": self.videoCall?.video_service ?? "",
				"notify_accept": self.videoCall?.supportSocket() ?? false,
				"show_skip": true,
				])
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

		self.receive(messageType: MessageType.init(type: type) ?? MessageType.Normal, body: string)
	}

	func session(_ session: OTSession, didFailWithError error: OTError) {
		self.log(.info, "session didFailWithError \(error)")
		self.disconnect(.consumedWithError)
		// sessionDidDisconnect (sometimes) called right after
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
	}

	func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
		self.log(.info, "publisher streamCreated")
	}

	func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
		self.log(.info, "publisher streamDestroyed")
		if self.status != .consumed && self.status != .consumedWithError {
			self.disconnect(.consumedWithError)
		}
	}

	func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
		self.log(.info, "publisher didFailWithError \(error)")
		self.disconnect(.consumedWithError)
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
//		self.agoraService.mute(user: 0, mute: true)
		self.sessionConnectSuccessful()
	}

	func remoteUserDidQuited(user user_id: Int, droped: Bool) {
		self.log(.info, "agora disconnect")
		self.disconnect(.consumedWithError)

		LogManager.shared.addLog(type: .CustomLog, subTitle: "other left", info: [
			"video_service": self.videoCall?.video_service ?? "",
			"notify_accept": self.videoCall?.supportSocket() ?? false,
			"show_skip": false,
			])
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
