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

class ChatSession: NSObject, OTSessionDelegate, OTSubscriberKitDelegate {
    weak var callDelegate:ChatSessionCallDelegate?
    weak var loadingDelegate:ChatSessionLoadingDelegate?

    var chat: Chat? // TODO This actually isnt an optional its always passed in init. cool cool
    var realmCall:RealmCall? {
        let realm = try? Realm()
        return realm?.object(ofType: RealmCall.self, forPrimaryKey: self.chat?.chatId)
    }
    var realmVideoCall:RealmVideoCall?
    private var chatNotificationToken: NotificationToken?

	var matchedTime = NSDate().timeIntervalSince1970
	var acceptTime: TimeInterval?
	var connectTime: TimeInterval?

    var didConnect = false
    var matchUserDidAccept = false
    var isDialedCall = false
    var isReportedChat = false
	var isReportedByOther = false
	var isUnMuteSound = false
	var textMode = false
    var justAddFriend = false

    var message_send = 0
    var message_receive = 0
    var common_trees: String?

    var session: OTSession!
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
					self.updateStatusTo(.consumed)
					self.loadingDelegate = nil
					self.callDelegate = nil
					self.subscriber = nil
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

    var shouldShowRating:Bool {
        // TODO: now just make shouldShowRating always false , if make sure don't need match rate anymore, you shuld delete all the logic about match rating
        return false;
//        guard let ratingValue = self.subscriberData?["r"] else {
//            return false
//        }
//        guard let divider = Int(ratingValue) else {
//            return false
//        }
//        return divider > 0 && self.didConnect && !self.friendMatched && Achievements.shared.totalChats % divider == 0
    }
    var friendMatched = false {
        didSet {
            if let callDelegate = self.callDelegate, friendMatched == true {
                callDelegate.friendMatched(in: self)
				
				var toAddInfo = ["match_success_add_friend": 1]
				if self.hadAddTime == true {
					toAddInfo["match_success_time&friend"] = 1
				}
				
				AnaliticsCenter.add(amplitudeUserProperty: toAddInfo)
				AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)
				
				self.track(matchEvent: .matchFirstAddFriend)
				self.chat?.update(callback: nil)
            }
        }
    }
    private var sessionStatus: SessionStatus = .disconnected

    /// When a disconnect is completed async, this will be the result (consumed or consumedWithError)
    private var disconnectStatus: ChatSessionStatus?

    private(set) var theirSnapchatUsername: String?

    /// The count of checks such as time and subscriber connection that have been completed (should be zero, one, or two)
    private var initiatorReadyChecks = 0 {
        didSet {
            if self.initiatorReadyChecks == 2 {
                self.tryConnecting()
            }
        }
    }

    var matchReady = false {
        didSet {
            if self.matchReady {
                self.tryConnecting()
            }
        }
    }

    private enum SessionStatus {
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
		if let match_mode = Achievements.shared.selectMatchMode, match_mode == .TextMode {
			match_type = "text"
		}

		var commonParameters = [
			"user_gender": currentUser?.gender ?? "",
			"user_age": "\(currentUser?.age.value ?? 0)",
			"user_country": currentUser?.location ?? "",
			"user_ban": "\(is_banned)",
            "match_type": match_type,
            "trees": common_trees ?? "",
		]

        if let videoCall = self.realmCall, let chat = chat {
			commonParameters["match_with_gender"] = chat.gender ?? ""
			commonParameters["match_with_country"] = chat.location ?? ""
			commonParameters["match_with_age"] = "\(chat.age ?? 0)"
            var match_with_type = "video"
			if let match_with_mode = videoCall.match_mode, match_with_mode == MatchMode.TextMode.rawValue {
				match_with_type = "text"
			}
            commonParameters["match_with_type"] = match_with_type
			commonParameters["match_room_type"] = textMode ? "text" : "video"

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

				if textMode {
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

        self.sessionStatus = .connecting
        self.isDialedCall = isDialedCall
        self.chat = chat
        self.loadingDelegate = loadingDelegate
		self.textMode = (chat.match_with_mode == .TextMode)

		let realm = try? Realm()
		if let currentMatchUser = realmCall?.user?.user_id, let friend = realm?.objects(RealmFriendship.self).filter("user.user_id == \"\(currentMatchUser)\"").first {
			self.theirSnapchatUsername = friend.user?.snapchat_username
			self.chat?.sharedSnapchat = true
			self.chat?.theySharedSnapchat = true
			self.friendMatched = true
		}

        self.chatNotificationToken = self.realmCall?.addNotificationBlock { [weak self] change in
            switch change {
            case .error(let error):
                print("Error: \(error.localizedDescription)")
            case .change(let properties):
                for property in properties {
                    if property.name == "status" {
                        let newStatus = property.newValue as? String
                        if newStatus == "MISSED" || newStatus == "ENDED" {
                            self?.disconnect(.consumed)
                            self?.chatNotificationToken?.stop()
                        }
                    }
                }
            default:
                break
            }
        }

        self.session = OTSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId, delegate: self)
        var maybeError : OTError?
        session.connect(withToken: token, error: &maybeError)
        if let error = maybeError {
            self.log(.error, "Could not connect to session \(error)")
            self.sessionStatus = .disconnected
            self.updateStatusTo(.consumedWithError)
            return
        }
    }

    deinit {
        print("sh-1226 \(self) deinit")
    }

    func accept() {
        self.response = .accepted
		self.acceptTime = NSDate().timeIntervalSince1970

		guard let connection = self.subscriberConnection else {
            // call will be accepted as soon as the subscriber connected
            return
        }

		if self.matchUserDidAccept {
			AnaliticsCenter.add(amplitudeUserProperty: ["match_connect": 1])
			AnaliticsCenter.add(firstdayAmplitudeUserProperty: ["match_connect": 1])
			self.track(matchEvent: .matchConnect)
		}
		
        self.initiatorReadyChecks += 1
        self.log(.info, "Ready")
        var maybeError : OTError?
        self.session.signal(withType: "ready", string: "", connection: connection, retryAfterReconnect: true, error: &maybeError)
        if let error = maybeError {
            self.disconnect(.consumedWithError)
            self.log(.error, "Ready signal error \(error)")
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

        guard let chat = self.chat else {
            self.log(.error, "Missing chat")
            return false
        }
        guard let connection = self.subscriberConnection else {
            self.log(.error, "Could not add a snapchat")
            self.sessionStatus = .disconnected
            self.updateStatusTo(.consumedWithError)
            return false
        }
        chat.sharedSnapchat = true
        var maybeError : OTError?
        self.session.signal(withType: "snapchat_username", string: username, connection: connection, retryAfterReconnect: true, error: &maybeError)
        if let error = maybeError {
            self.disconnect(.consumedWithError)
            self.log(.error, "Send minute error \(error)")
        }
        self.friendMatched = chat.theySharedSnapchat

        return !self.friendMatched
    }

	func sentUnMute() {
		if isReportedChat {
			return
		}

		guard let chat = self.chat else {
			self.log(.error, "Missing chat")
			return
		}

		guard let connection = self.subscriberConnection else {
			self.log(.error, "Could not add a unmute")
			self.sessionStatus = .disconnected
			self.updateStatusTo(.consumedWithError)
			return
		}
		chat.unMute = true
		var maybeError : OTError?
		self.session.signal(withType: MessageType.UnMute.rawValue, string: "", connection: connection, retryAfterReconnect: true, error: &maybeError)
		if let error = maybeError {
			self.updateStatusTo(.consumedWithError)
			self.log(.error, "Send minute error \(error)")
		}

		if self.chat?.theyUnMute == true {
			self.isUnMuteSound = true
			self.subscriber?.subscribeToAudio = true
			self.callDelegate?.soundUnMuted(in: self)
		}
	}

	func sentReport() {
		guard let chat = self.chat else {
			self.log(.error, "Missing chat")
			return
		}

		guard let connection = self.subscriberConnection else {
			self.log(.error, "Could not send a report")
			self.sessionStatus = .disconnected
			self.updateStatusTo(.consumedWithError)
			return
		}

		chat.reporting = true
		var maybeError : OTError?
		self.session.signal(withType: MessageType.Report.rawValue, string: "report", connection: connection, retryAfterReconnect: true, error: &maybeError)
        self.isReportedChat = true
        self.chat?.reported = true
		if let error = maybeError {
			self.updateStatusTo(.consumedWithError)
			self.log(.error, "Send report error \(error)")
		}

		if (hadAddTime || friendMatched || textMode) {
			self.disconnect(.consumed)
		}
	}

	func sentTypeStatus() {
		guard let connection = self.subscriberConnection else {
			self.log(.error, "Could not send a typing")
			self.sessionStatus = .disconnected
			self.updateStatusTo(.consumedWithError)
			return
		}

		var maybeError : OTError?
		self.session.signal(withType: MessageType.Typing.rawValue, string: "Typing", connection: connection, retryAfterReconnect: true, error: &maybeError)
		if let error = maybeError {
			self.updateStatusTo(.consumedWithError)
			self.log(.error, "Send typing error \(error)")
		}
	}

	func sentTextMessage(text: String) {
		guard let connection = self.subscriberConnection else {
			self.log(.error, "Could not send a message")
			self.sessionStatus = .disconnected
			self.updateStatusTo(.consumedWithError)
			return
		}

		var maybeError : OTError?
		self.session.signal(withType: MessageType.Text.rawValue, string: text, connection: connection, retryAfterReconnect: true, error: &maybeError)
		if let error = maybeError {
			self.updateStatusTo(.consumedWithError)
			self.log(.error, "Send text message error \(error)")
		}
        self.message_send = self.message_send + 1
	}

    func addFriend() -> Bool {
        //TODO:
        //needs to get relationship to pass back and instantiate messengerChatView from mainVC
        return true
    }
    
    func userTurnIntoBackground(){
        guard let connection = self.subscriberConnection else {
            self.log(.error, "Could not send a minute")
            self.sessionStatus = .disconnected
            self.updateStatusTo(.consumedWithError)
            return
        }
        
        var maybeError : OTError?
        self.session.signal(withType: "turntobackground", string: "", connection: connection, retryAfterReconnect: true, error: &maybeError)
    }

    /**
     Sends a request for a minute and adds one if it's already available.

     - Returns: isWaiting. Whether the other person still has to tap Add Minute.
     */
    func sendMinute() -> Bool {
        if self.isReportedChat {
            return false
        }

        guard let chat = self.chat else {
            self.log(.error, "Missing chat")
            return false
        }
        guard let connection = self.subscriberConnection else {
            self.log(.error, "Could not send a minute")
            self.sessionStatus = .disconnected
            self.updateStatusTo(.consumedWithError)
            return false
        }
        chat.minutesAdded += 1

        var maybeError : OTError?
        self.session.signal(withType: "request", string: "minute", connection: connection, retryAfterReconnect: true, error: &maybeError)
        if let error = maybeError {
            self.disconnect(.consumedWithError)
            self.log(.error, "Send minute error \(error)")
        }
        if chat.theirMinutesAdded >= chat.minutesAdded {
            self.log(.info, "Adding minute")
            self.callDelegate?.minuteAdded(in: self)
            self.hadAddTime = true
            return false
        }
        return true
    }

    private func sendSkip() {
        var maybeError : OTError?
        session.signal(withType: "skip", string: "", connection: self.connections.last, error: &maybeError)
        self.disconnect(.consumed)
        if let error = maybeError {
            print("send skip message error : \(error)")
        }
    }

    private func tryConnecting() {
        guard self.initiatorReadyChecks == 2 else {
            self.log(.info, "Initiator not ready")
            return
        }
        guard self.matchReady else {
            self.log(.info, "Match not ready")
            return
        }

		if textMode == false {
			self.subscriber?.subscribeToAudio = true
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
    class func parseConnectionData(_ data: String) -> Dictionary<String, String> {
        var result = Dictionary<String, String>()
        let attributes = data.components(separatedBy: ",")
        for attribute in attributes {
            var parts = attribute.components(separatedBy: "=")
            let title = parts.removeFirst()
            var value = parts.joined(separator: "=")
            if title == "bio" {
                value = value.removingPercentEncoding ?? value
            }
            result[title] = value
        }
        return result
    }
    private func updateStatusTo(_ newStatus: ChatSessionStatus) {
        if self.status == .consumed || self.status == .consumedWithError {
            // Once a chat session is consumed, it can not change.
            self.log(.warning, "Chat is already consumed as \(self.status) and can not be updated to \(newStatus)")
            return
        }

		if self.status == .connected && newStatus == .disconnecting {
			self.loadingDelegate?.consumeFromConnected?()
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
			
			if self.textMode == true {
				toAddInfo["match_success_text"] = 1
			}else {
				toAddInfo["match_success_video"] = 1
			}
			
			AnaliticsCenter.add(amplitudeUserProperty: toAddInfo)
			AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)
			
			self.track(matchEvent: .matchFirstSuccess)
			self.track(matchEvent: .matchSuccess)
			
        case .consumed:
            self.loadingDelegate?.chatSession(self, callEndedWithError: nil)
            self.chatNotificationToken?.stop()
            self.chatNotificationToken = nil
        case .consumedWithError:
            self.loadingDelegate?.chatSession(self, callEndedWithError: NSError.unknownMonkeyError)
            self.chatNotificationToken?.stop()
            self.chatNotificationToken = nil
        case .disconnecting:
            if self.didConnect {
                self.loadingDelegate?.dismissCallViewController(for: self)
            }
            DispatchQueue.global().async {
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, with: [.mixWithOthers])
                try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
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
		
		if self.subscriberConnection == nil && status == .connected {
			// Wait a few seconds to see if they connect so we can tell them we are leaving.
			self.disconnectStatus = status
			self.updateStatusTo(.disconnecting)
			DispatchQueue.main.asyncAfter(deadline: .after(seconds: 3.0)) { [weak self] in
				self?.finishDisconnecting()
			}
			return
		}
		
        if self.sessionStatus == .connected {
			
			var match_duration = 0
			if let connectTime = connectTime {
				match_duration = Int(Date().timeIntervalSince1970 - connectTime)
			}
			var toAddInfo = ["match_duration_total": match_duration]
			AnaliticsCenter.add(firstdayAmplitudeUserProperty: toAddInfo)
			
			if self.textMode == true {
				toAddInfo["match_duration_total_text"] = match_duration
			}else {
				toAddInfo["match_duration_total_video"] = match_duration
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

    private func finishDisconnecting() {
        guard status != .consumed && status != .consumedWithError else {
            // Disconnect in progress.
            self.log(.error, "Disconnects must have consumed status")
            return
        }
        log(.info, "Disconnecting")
        var maybeError : OTError?
        self.session.disconnect(&maybeError)
        if let error = maybeError {
            self.log(.error, "Disconnect error \(error)")
            self.updateStatusTo(.consumedWithError)
            return
        }
    }
    func toggleCameraPosition() {
		HWCameraManager.shared().rotateCameraPosition()
    }
    func toggleFrontCamera(front:Bool) {
		HWCameraManager.shared().changeCameraPosition(to: .front)
    }
    internal func sessionDidConnect(_ session: OTSession) {
        self.log(.info, "sh-1226- \(self) sessionDidConnect")
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
        // Wait up to 5 seconds before giving up on connecting to the session
        var callLoadingTimeout = Double(RemoteConfigManager.shared.match_connect_time)
        if isDialedCall {
            callLoadingTimeout = 30
        }
        DispatchQueue.main.asyncAfter(deadline: .after(seconds: callLoadingTimeout)) { [weak self] in
            guard let `self` = self else { return }
            if self.status == .loading {
                print("Call loading timed out")
                self.disconnect(.consumed)
            }
        }
    }
    // session will not always be defined
    internal func sessionDidDisconnect(_ session : OTSession) {
        self.log(.info, "Session disconnected")
        self.sessionStatus = .disconnected
        self.updateStatusTo(self.disconnectStatus ?? .consumed)
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

        print("sh-1226- streamCreated")

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
        self.subscriberData = ChatSession.parseConnectionData(connection.data ?? "")

        self.subscriberConnection = connection
		self.wasSkippable = true
		self.updateStatusTo(.skippable)
		if self.response == .skipped {
			self.sendSkip()
			return;
		}
		
        if self.response == .accepted {
            self.accept()
        }
		
        DispatchQueue.main.asyncAfter(deadline: .after(seconds: Double(RemoteConfigManager.shared.match_accept_time))) { [weak self] in
            guard let `self` = self else { return }
            if self.response == nil {
                print("Inactivity detected")
                MKMatchManager.shareManager.afmCount += 1
                if MKMatchManager.shareManager.needShowAFMAlert {
                    self.loadingDelegate?.warnConnectionTimeout?(in: self)
                    MKMatchManager.shareManager.afmCount = 0
                }
            }
            if self.response != nil || self.matchUserDidAccept {
                DispatchQueue.main.asyncAfter(deadline: .after(seconds: Double(RemoteConfigManager.shared.match_waiting_time))) { [weak self] in
                    guard let `self` = self else { return }
                    if self.response == nil {
                        if self.initiatorReadyChecks != 2 {
                            self.disconnectReason = .initiatorNotReady
                        } else {
                            self.disconnectReason = .matchNotReady
                        }
                        self.disconnect(.consumed)
                    }
                }
            }else {
                self.disconnect(.consumed)
            }
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
        self.connections.forEach { (connection) in
            var maybeError : OTError?
            for connection in connections {
                DispatchQueue.global().async {
                    self.session.signal(withType: "\(messageHandler.chatSessionMessagingPrefix)-\(type)", string: message, connection: connection, retryAfterReconnect: true, error: &maybeError)
                    if let error = maybeError {
                        DispatchQueue.main.async {
                            self.disconnect(.consumedWithError)
                            self.log(.error, "Send minute error \(error)")
                        }
                    }
                };
            }
        }
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

		if let messageType = MessageType.init(type: type) {

			switch messageType {
			case .AddTime:
				if (message == "minute") {
					self.chat?.theirMinutesAdded += 1
					if self.chat!.minutesAdded >= self.chat!.theirMinutesAdded {
						self.log(.info, "Adding minute")
						self.hadAddTime = true
						self.callDelegate?.minuteAdded(in: self)
					}
				}
			case .AddFriend:
				self.chat?.theySharedSnapchat = true
				self.theirSnapchatUsername = string
				if self.chat?.sharedSnapchat == true {
					self.log(.info, "Openning snapchat")
					self.friendMatched = true
                    self.justAddFriend = true
				}
			case .Accept:
				self.matchReady = true
				if self.response == .accepted {
					self.loadingDelegate?.shouldShowConnectingStatus!(in: self)
					AnaliticsCenter.add(amplitudeUserProperty: ["match_connect": 1])
					AnaliticsCenter.add(firstdayAmplitudeUserProperty: ["match_connect": 1])
					self.track(matchEvent: .matchConnect)
				}
				self.matchUserDidAccept = true
			case .UnMute:
				self.chat?.theyUnMute = true
				if self.chat?.unMute == true {
					self.isUnMuteSound = true
					self.subscriber?.subscribeToAudio = true
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
					"body": message,
					"sender": realmCall?.user?.user_id ?? ""
				]
				if let textMessage = Mapper<TextMessage>().map(JSON: messageInfo) {
					self.callDelegate?.received(textMessage: textMessage, in: self)
				}
			case .Text:
                self.message_receive = self.message_receive + 1
				let messageInfo = [
					"type": messageType.rawValue,
					"body": message,
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

    func session(_ session: OTSession, didFailWithError error: OTError) {
        self.log(.info, "session didFailWithError \(error)")
        self.disconnect(.consumedWithError)
        // sessionDidDisconnect (sometimes) called right after
    }

    // MARK: - OTSubscriber delegate callbacks
    /**
     * Sent when the subscriber successfully connects to the stream.
     * @param subscriber The subscriber that generated this event.
     */
    public func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        self.log(.info, "subscriberDidConnectToStream")
        if subscriberKit.stream == self.subscriber?.stream {
            self.initiatorReadyChecks += 1
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
            self.disconnect(.consumed)
        }
    }

    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        self.log(.info, "publisher didFailWithError \(error)")
        self.disconnect(.consumedWithError)
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
    weak var chatSession: ChatSession? { get set }
    var chatSessionMessagingPrefix: String { get }
    func chatSession(_ chatSession: ChatSession, received message: String, from connection: OTConnection, withType type: String)
    func chatSession(_ chatSession: ChatSession, statusChangedTo status: ChatSessionStatus)
    func chatSesssion(_ chatSesssion: ChatSession, connectionCreated connection: OTConnection)
}

@objc protocol ChatSessionLoadingDelegate:class {
    func presentCallViewController(for chatSession: ChatSession)
    func dismissCallViewController(for chatSession: ChatSession)
    func chatSession(_ chatSession: ChatSession, callEndedWithError error:Error?)
    @objc optional func warnConnectionTimeout(in chatSession: ChatSession)
	@objc optional func consumeFromConnected()
    @objc optional func shouldShowConnectingStatus(in chatSession:ChatSession)
}
