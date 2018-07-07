//
//  OnepMatchController.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/27.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import Kingfisher
import ObjectMapper

typealias MatchViewController = UIViewController & MatchViewControllerProtocol

class OnepMatchController: MonkeyViewController {
	
	internal func showAlert(alert: UIAlertController) {
		self.present(alert, animated: true, completion: nil)
	}
	
	// tap to start
	@IBOutlet weak var startView: UIView!
	@IBOutlet weak var fingerLabel: UILabel!
	@IBOutlet weak var exitButton: BigYellowButton!
	
	// content
	@IBOutlet weak var loadingContentView: MakeUIViewGreatAgain!
	// match tips
	@IBOutlet weak var loadingTextLabel: LoadingTextLabel!
	var nextFact = APIController.shared.currentExperiment?.initial_fact_discover ?? ""
	
	// user info
	@IBOutlet weak var commonTreeTip: UILabel!
	@IBOutlet weak var matchUserPhoto: UIImageView!
	// user bio
	@IBOutlet weak var factTextBottom: NSLayoutConstraint!
	@IBOutlet weak var factTextView: UILabel!
	// text mode 匹配信息展示内容区域
	@IBOutlet weak var matchModeContainer: UIView!
	@IBOutlet weak var matchModeTip: UILabel!
	@IBOutlet weak var matchModeEmojiLeft: UILabel!
	@IBOutlet weak var matchModeEmojiRight: UILabel!
	
	// text mode 开关
	@IBOutlet weak var matchModeSwitch: MatchModeSwitch!
	
	// event mode 开关和内容区域
	@IBOutlet weak var eventModePopup: SmallYellowButton!
	@IBOutlet weak var eventModeEmoji: UILabel!
	@IBOutlet weak var eventModeTitle: UILabel!
	@IBOutlet weak var eventModeSwitch: MonkeySwitch!
	@IBOutlet weak var eventModeDescription: UILabel!
	
	// 展示 match mode 提示文案
	@IBOutlet weak var matchModePopupTop: NSLayoutConstraint!
	@IBOutlet weak var matchModePopup: UIView!
	@IBOutlet weak var matchModeLabel: UILabel!
	
	// response
	@IBOutlet weak var acceptButton: BigYellowButton!
	@IBOutlet weak var rejectButton: BigYellowButton!
	@IBOutlet weak var skipButton: UIButton!
	@IBOutlet weak var skippedText: UILabel!
	
	// MARK: UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

//		Step 1: apperance
		self.configureApperance()
		
//		Step 2: tap to start
		let startGesture = UITapGestureRecognizer.init(target: self, action: #selector(startFindingMatch))
		startView.addGestureRecognizer(startGesture)
	}
	
	func configureApperance() {
		self.view.backgroundColor = UIColor.clear
		
		// event mode 展示
		self.eventModePopup.layer.cornerRadius = 12
		self.eventModePopup.layer.masksToBounds = true
		self.eventModePopup.addTarget(self, action: #selector(changeEventMode), for: .touchUpInside)
		// event mode 开关
		self.eventModeSwitch.backgroundColor = UIColor.clear
		self.eventModeSwitch.openEmoji = "🤩"
		self.eventModeSwitch.closeEmoji = "🤩"
		
		// match mode 提示
		self.matchModePopup.layer.cornerRadius = 12
		
		// match mode 展示
		self.matchModeContainer.layer.cornerRadius = 24
		self.matchModeContainer.layer.masksToBounds = true
		self.matchModeContainer.layer.borderWidth = 3;
		self.matchModeContainer.layer.borderColor = UIColor.clear.cgColor
		
		// common tree
		self.commonTreeTip.isHidden = true
		self.commonTreeTip.layer.cornerRadius = 24
		self.commonTreeTip.layer.masksToBounds = true
		
		// user icon
		self.matchUserPhoto.isHidden = true
		self.matchUserPhoto.layer.cornerRadius = 24
		self.matchUserPhoto.layer.masksToBounds = true
		self.matchUserPhoto.layer.shadowRadius = 4
		self.matchUserPhoto.layer.shadowColor = UIColor.init(white: 0, alpha: 0.25).cgColor
		
		// fact
		self.acceptButton.isHidden = true
		self.rejectButton.isHidden = true
		self.skipButton.isHidden = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.refreshMatchModeStatus()
	}
	
	func refreshMatchModeStatus() {
		if self.onepStatus.canSwipe() {
			// 如果 text chat mode 开关打开
			if RemoteConfigManager.shared.text_chat_mode {
				self.matchModeSwitch.isEnabled = true
				self.matchModeSwitch.isHidden = false
			}else {
				self.matchModeSwitch.isEnabled = false
				self.matchModeSwitch.isHidden = true
			}
			
			let currentMatchMode = Achievements.shared.selectMatchMode
			// event mode 可用
			if let matchInfo = UserManager.shared.currentMatchInfo, let matchEvent = matchInfo.events, matchEvent.isAvailable() {
				self.eventModePopup.isHidden = false
				
				// 配置 event mode
				self.eventModeEmoji.text = matchEvent.emoji
				self.eventModeTitle.text = matchEvent.name
				self.eventModeDescription.text = matchEvent.event_bio
				
				if (currentMatchMode == .EventMode) {
					self.eventModeSwitch.open = true
				}else {
					self.eventModeSwitch.open = false
				}
			}else {
				// 如果当前时间不在活动开放时间内
				self.eventModePopup.isHidden = true
				
				// 关闭 event mode
				if (currentMatchMode == .EventMode) {
					Achievements.shared.selectMatchMode = .VideoMode
				}
			}
			
			// match tip 位置
			var matchTipPopupTop = self.eventModePopup.frame.maxY + 2
			if self.eventModePopup.isHidden {
				matchTipPopupTop = self.matchModeSwitch.frame.maxY + 2
			}
			self.matchModePopupTop.constant = matchTipPopupTop
		}else {
			// 直接隐藏
			self.matchModeSwitch.isEnabled = false
			self.matchModeSwitch.isHidden = true
			self.eventModePopup.isHidden = true
			self.matchModePopup.isHidden = true
		}
	}
	
	@IBAction func matchModeChanged(_ sender: MatchModeSwitch) {
		self.stopFindingChats(forReason: "switch-match-mode")
		self.revokePrevMatchRequest {
			self.startFindingChats(forReason: "switch-match-mode")
		}
		
		self.eventModeSwitch.open = false
		
		var currentMatchMode = MatchMode.TextMode
		// 如果之前选择过其他的 mode
		if let prevMatchMode = Achievements.shared.selectMatchMode {
			// 如果选择的是 TextMode，反选为 VideoMode，否则选为 TextMode
			currentMatchMode = (prevMatchMode == .TextMode) ? .VideoMode : .TextMode
		}
		
		// event track
		AnalyticsCenter.log(withEvent: .textModeClick, andParameter: [
			"status": (currentMatchMode == .VideoMode) ? "toggle off" : "toggle on"
			])
		
		// 保存当前选中的 match mode
		Achievements.shared.selectMatchMode = currentMatchMode
		// ui
		sender.switchToMode(matchMode: currentMatchMode)
		matchModeLabel.text = (currentMatchMode == .VideoMode) ? "Turn off text mode to get video chat matches only 📹" : "Turn on text mode to get both text and video chat matches 🙊💬"
		showPopup(popup: matchModePopup)
	}
	
	func changeEventMode() {
		self.stopFindingChats(forReason: "switch-match-mode")
		self.revokePrevMatchRequest {
			self.startFindingChats(forReason: "switch-match-mode")
		}
		self.matchModeSwitch.switchToMode(matchMode: .VideoMode)
		
		// 以当前的 event mode id 构造 MatchMode
		var currentMatchMode = MatchMode.EventMode
		// 如果之前选择过其他的 mode
		if let prevMatchMode = Achievements.shared.selectMatchMode {
			// 如果选择的是 EventMode，反选为 VideoMode，否则选为 EventMode
			currentMatchMode = (prevMatchMode == .EventMode) ? .VideoMode : currentMatchMode
		}
		
		// event track
		AnalyticsCenter.log(withEvent: .eventModeClick, andParameter: [
			"status": (currentMatchMode == .EventMode) ? "toggle off" : "toggle on"
			])
		
		// 保存当前选中的 match mode
		Achievements.shared.selectMatchMode = currentMatchMode
		// ui
		let eventModeOpen = (currentMatchMode == .EventMode)
		self.eventModeSwitch.open = eventModeOpen
		if eventModeOpen {
			self.matchModeLabel.text = "You can only choose 1 between event mode and text mode"
			self.showPopup(popup: matchModePopup)
		}
		
		print("eventModeOpen = \(eventModeOpen)")
	}
	
	func loadCurrentEventMode() {
		guard let authorization = UserManager.authorization else {
			return
		}
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v1.3/experiments/\(Environment.appVersion)/match", options: [
			.header("Authorization", authorization),
			]).addCompletionHandler { (result) in
				switch result {
				case .error(let error):
					error.log()
				case .success(let jsonAPIDocument):
					if let matchInfo = Mapper<RealmMatchInfo>().map(JSON: jsonAPIDocument.json) {
						if let realm = try? Realm() {
							do {
								try realm.write {
									realm.add(matchInfo, update: true)
								}
							} catch(let error) {
								print("Error: ", error)
							}
						}
					}
					self.refreshMatchModeStatus()
				}
		}
	}
	
	var onepStatus: OnepStatus = .WaitingStart
	fileprivate func update(to newStatus: OnepStatus) {
		guard let mainVC = self.mainViewController else {
			return
		}
		
		if newStatus == self.onepStatus {
			return
		}
		let oldStatus = self.onepStatus
		self.onepStatus = newStatus
		
		self.startView.isHidden = (newStatus != .WaitingStart)
		self.exitButton.isHidden = (newStatus != .RequestMatch)
		self.loadingContentView.isHidden = (newStatus == .WaitingStart || newStatus == .Chating)
		self.loadingTextLabel.isHidden = (newStatus == .RequestMatch)
		self.matchModeContainer.isHidden = (newStatus != .WaitingResponse || newStatus != .Connecting)
		self.matchUserPhoto.isHidden = (newStatus != .WaitingResponse || newStatus != .Connecting)
		self.commonTreeTip.isHidden = (newStatus != .WaitingResponse || newStatus != .Connecting)
		self.acceptButton.isHidden = (newStatus != .WaitingResponse)
		self.rejectButton.isHidden = (newStatus != .WaitingResponse)
		self.skipButton.isHidden = (newStatus != .WaitingResponse)
		self.refreshMatchModeStatus()
		
		switch oldStatus {
		case .WaitingStart:
			break
			//
		case .RequestMatch:
			break
		case .WaitingResponse:
			break
		case .Connecting:
			break
		case .Chating:
			break
		}
		
		switch newStatus {
		case .WaitingStart:
			break
			//
		case .RequestMatch:
			if oldStatus != .WaitingStart {
				self.startFindingChats(forReason: "receive-match")
				mainVC.endMatchProcess()
			}
			self.resetFact()
		case .WaitingResponse:
			self.stopFindingChats(forReason: "receive-match")
			self.showMatchInfo()
			mainVC.beginMatchProcess()
		case .Connecting:
			break
		case .Chating:
			break
		}
	}
	
	var responseTimeoutCount = 0
	var matchRequestTimer: Timer?
	var chatRequest: JSONAPIRequest? // use to know match request is running
	var continuous_request_count = 0
	var request_id: String?
	var request_time: Date!
	var stopFindingReasons = ["tap-to-start"]
	
	func commomParameters(for event: AnalyticEvent) -> [String: Any] {
		let currentUser = APIController.shared.currentUser
		let is_banned = currentUser?.is_banned ?? false
		var match_type = "video"
		if let match_mode = Achievements.shared.selectMatchMode, match_mode == .TextMode {
			match_type = "text"
		}
		
		var commonParameters = [String: Any]()
		commonParameters["user_gender"] = currentUser?.gender
		commonParameters["user_age"] = currentUser?.age
		commonParameters["user_country"] = currentUser?.location
		commonParameters["user_ban"] = is_banned ? "true" : "false"
		commonParameters["match_type"] = match_type
		commonParameters["trees"] = currentUser?.channels.first?.title
		return commonParameters
	}
	
	fileprivate weak var lastMatchModel: MatchModel? = nil
	fileprivate var matchModel: MatchModel? = nil
	
	@IBAction func acceptButtonTapped(sender: Any) {
		self.responseTimeoutCount = 0
		guard let matchModel = self.matchModel else { return }
		
		let acceptTime = Date.init()
		let user_id: String = matchModel.left?.user.user_id ?? ""
		let duration: TimeInterval = matchModel.beginTime.timeIntervalSince1970 - request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Accept",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(withEvent: .matchSendAccept, andParameter: [
			"type": (sender is BigYellowButton) ? "btn accept" : "auto accept",
			])
		
		matchModel.acceptTime = acceptTime
		matchModel.accept = true
		self.updateResponseStatus()
	}
	
	@IBAction func rejectButtonTapped(_ sender: Any) {
		self.responseTimeoutCount = 0
		guard let matchModel = self.matchModel else { return }
		
		let user_id: String = matchModel.left?.user.user_id ?? ""
		let duration: TimeInterval = matchModel.beginTime.timeIntervalSince1970 - request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Reject",
			"info": user_id,
			"match duration": duration,
			])
		AnalyticsCenter.log(event: .matchSendSkip)
		
		matchModel.skip = true
		self.updateResponseStatus()
	}
	
	@IBAction func skipButtonTapped(_ sender: Any) {
		self.responseTimeoutCount = 0
		guard let matchModel = self.matchModel else { return }
		
		let user_id: String = matchModel.left?.user.user_id ?? ""
		let duration: TimeInterval = matchModel.beginTime.timeIntervalSince1970 - request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Skip",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(event: .matchSendSkip)
		
		matchModel.skip = true
		self.updateResponseStatus()
	}
	
	private func updateResponseStatus() {
		
	}
	
	func progressMatch(call: RealmCall, data: [String: Any]) {
//		let jsonAPIDocument = JSONAPIDocument.init(json: data)
//
//		if let meta = jsonAPIDocument.meta, let nextFact = meta["next_fact"] as? String {
//			self.nextFact = nextFact
//		}
//
//		guard let chatId = call.chat_id, /*let received_id = call.request_id, self.request_id == received_id,*/ let sessionId = call.session_id else {
//			print("Error: RealmCall object did not return with sufficient data to create a chatSession")
//			return
//		}
//		if call.channelToken.count == 0 {
//			return
//		}
//
//		self.stopFindingChats(forReason: "receive-match")
//		self.listTree(tree: call.user?.channels.first?.channel_id ?? "")
//		self.matchUserPhoto.isHidden = false
//
//		var imageName = "ProfileImageDefaultMale"
//		if call.user?.gender == Gender.female.rawValue {
//			imageName = "ProfileImageDefaultFemale"
//		}
//		let placeholder = UIImage.init(named: imageName)
//		let profile_photo_url = URL.init(string: call.user?.profile_photo_url ?? "")
//		self.matchUserPhoto.kf.setImage(with: profile_photo_url, placeholder: placeholder)
//
//		var bio = "connecting"
//		if let callBio = call.bio, let convertBio = callBio.removingPercentEncoding {
//			bio = convertBio
//			if RemoteConfigManager.shared.app_in_review == true {
//				let user_age_str = convertBio.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
//				//				print("match a user with age \(user_age_str)")
//				if let age_range = convertBio.range(of: user_age_str), let user_age = Int(user_age_str), user_age < 19, user_age > 0 {
//					let new_age = abs(Int.arc4random() % 5) + 19
//					bio = convertBio.replacingCharacters(in: age_range, with: "\(new_age)")
//				}
//			}
//		}
//
//		if let match_distance = call.match_distance.value, match_distance > 0, Achievements.shared.nearbyMatch == true {
//			bio = bio.appending("\n🏡\(match_distance)m")
//		}
		
//		self.chatSession = ChatSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId, chat: Chat(chat_id: chatId, first_name: call.user?.first_name, gender: call.user?.gender, age: call.user?.age.value, location: call.user?.location, profile_image_url: call.user?.profile_photo_url, user_id: call.user?.user_id, match_mode: call.match_mode), token: call.channelToken, loadingDelegate: self, isDialedCall: false)
		
//		AnalyticsCenter.add(amplitudeUserProperty: ["match_receive": 1])
//		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_receive": 1])
//
//		self.chatSession?.track(matchEvent: .matchFirstRecieved)
//		self.chatSession?.track(matchEvent: .matchReceived)
//		self.start(fact: bio)
//
//		if Achievements.shared.autoAcceptMatch {
//			self.acceptButtonTapped(sender: self)
//		}
	}
	
	private func showMatchInfo() {
		guard let matchModel = self.matchModel else { return }
		
		let matchMode = MatchMode.init(string: matchModel.match_mode)
		if matchMode == .VideoMode {
			self.acceptButton.backgroundColor = UIColor.init(red: 100.0 / 255.0, green: 74.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
			self.matchModeEmojiLeft.text = "🎦"
			self.matchModeEmojiRight.text = "🎦"
			self.matchModeTip.text = "Video Chat"
			self.factTextBottom.constant = 0
			self.matchModeContainer.layer.borderColor = UIColor.clear.cgColor
			self.matchModeTip.textColor = UIColor.white
		}else if matchMode == .TextMode {
			self.acceptButton.backgroundColor = UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
			self.matchModeEmojiLeft.text = "💬"
			self.matchModeEmojiRight.text = "💬"
			self.matchModeTip.text = "Text Chat"
			self.factTextBottom.constant = 0
			self.matchModeContainer.layer.borderColor = UIColor.clear.cgColor
			self.matchModeTip.textColor = UIColor.white
		}else {
			self.acceptButton.backgroundColor = UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
			self.matchModeEmojiLeft.text = "🤩"
			self.matchModeEmojiRight.text = "🤩"
			self.matchModeTip.text = "Fan Meet"
			self.factTextBottom.constant = 14
			self.matchModeContainer.layer.borderColor = UIColor.init(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1).cgColor
			self.matchModeTip.textColor = UIColor.init(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1)
		}
	}
	
	weak var matchViewController: MatchViewController?
	func presentCallViewController() {
		guard let matchModel = self.matchModel else { return }
		
		Achievements.shared.totalChats += 1
		var matchModeId = "callVC"
		if (matchModel.match_room_mode == .TextMode) {
			matchModeId = "textModeVC"
		}
			
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: matchModeId) as! MatchViewController
		self.matchViewController = matchViewController
//		matchViewController.commonTree = self.curCommonTree
		
//		viewController.present(matchViewController, animated: false, completion: nil)
//		if chatSession.friendMatched {
//			matchViewController.friendMatched(in: nil)
//		}
	}
	
	func dismissCallViewController() {
		HWCameraManager.shared().removePixellate()
		HWCameraManager.shared().changeCameraPosition(to: .front)
		
		guard let matchModel = self.matchModel else { return }
//		if chatSession.isReportedChat, chatSession.friendMatched, let userID = self.chatSession?.realmCall?.user?.user_id, chatSession.isReportedByOther == false {
//			self.showAfterReportFriendAlert(userID: userID)
//		}else if let realmVideoCall = chatSession.realmVideoCall, let userID = realmVideoCall.initiator?.user_id, chatSession.isReportedChat, chatSession.isReportedByOther == false {
//			/// it is a video call
//			self.showAfterReportFriendAlert(userID: userID)
//		}
		
//		chatSession.chat?.update(callback: nil)
		
//		if chatSession.wasSkippable {
//			self.resetFact()
//		}
//		if chatSession.response != .skipped && !chatSession.didConnect {
//			self.skipped(show: false)
//		}
//
//		let presentingViewController = self.matchViewController?.presentingViewController
//		self.factTextView.text = self.nextFact
//		let callViewController = self.matchViewController
//
//		if chatSession.matchMode == .VideoMode && chatSession.hadAddTime == false {
//			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
//		}else if chatSession.matchMode == .TextMode && chatSession.isUnMuteSound == false,
//			let connectTime = chatSession.connectTime,
//			(Date.init().timeIntervalSince1970 - connectTime) <= 30.0 {
//			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
//		}else if let connectTime = chatSession.connectTime,
//			(Date.init().timeIntervalSince1970 - connectTime) <= 30.0 {
//			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
//		}
//
//		UIView.animate(withDuration: 0.3, animations: {
//			callViewController?.isPublisherViewEnlarged = true
//			callViewController?.view.layoutIfNeeded()
//		}) { [unowned self] (success) in
//			presentingViewController?.dismiss(animated: false) {
//				UIView.animate(withDuration: 0.2, animations: {
////					self.colorGradientView.alpha = 1.0
//					presentingViewController?.view.alpha = 1.0
//				}) { (Bool) in
//					self.containerView.setNeedsLayout()
//					self.matchViewController = nil
//
//					if chatSession.chat?.sharedSnapchat == true, chatSession.chat?.theySharedSnapchat == true, UserDefaults.standard.bool(forKey: showRateAlertReason.addFriendJust.rawValue) == false {
//						UserDefaults.standard.set(true, forKey: showRateAlertReason.addFriendJust.rawValue)
//						self.showRateAlert(reason: .addFriendJust)
//					} else if Configs.contiLogTimes() == 3,
//						UserDefaults.standard.bool(forKey: showRateAlertReason.contiLoginThreeDay.rawValue) == false {
//						UserDefaults.standard.set(true,forKey: showRateAlertReason.contiLoginThreeDay.rawValue)
//						self.showRateAlert(reason: .contiLoginThreeDay)
//					}
//				}
//			}
//		}
		
		self.startFindingChats(forReason: "receive-match")
	}
	
}

// MARK: - loading view logic
extension OnepMatchController {
	
	func setFactText(_ text: String) {
		self.factTextView.text = text
	}
	
	fileprivate func resetFact() {
		self.setFactText(self.nextFact)
	}
	
	func start(fact: String) {
		self.setFactText(fact)
	}
	
	func listTree(tree: String) {
//		if let curTree = APIController.shared.currentUser?.channels.first, tree == curTree.channel_id {
//			self.chatSession?.common_tree = curTree.title!
////			self.curCommonTree = curTree
//			self.commonTreeTip.text = curTree.emoji
//			self.commonTreeTip.isHidden = false
//		}
	}
	
	func skipped(show: Bool = true) {
//		DispatchQueue.main.async {
//			self.start()
//			if show {
//				self.skippedText.layer.opacity = 1.0
//			}
//			self.skippedText.text = "Skipped!!"
//			self.factTextView.text = self.nextFact
//			UIView.animate(withDuration: 1.5, animations: {
//				self.skippedText.layer.opacity = 0.0
//			})
//			self.hideTreeLabels()
//		}
	}
}

// request match
extension OnepMatchController {
	func startFindingChats(forReason: String) {
		let prevReasonCount = self.stopFindingReasons.count
		let reason = self.stopFindingReasons.removeObject(object: forReason)
		print("Started finding \(forReason):  \(reason)")
		if prevReasonCount != 0 && self.stopFindingReasons.count == 0 {
			self.beginMatchRequest()
		} else {
			print("Still not finding because: \(stopFindingReasons.split(separator: ","))")
		}
	}
	
	func stopFindingChats(forReason: String) {
		print("Stopped finding: \(forReason)")
		self.continuous_request_count = 0
		self.stopFindingReasons.append(forReason)
		if self.stopFindingReasons.count == 1 {
			self.stopMatchRequest()
		}
		
		if forReason == "show-screen" || forReason == "tap-to-start" {
			self.revokePrevMatchRequest()
		}
	}
	
	func startFindingMatch() {
		if let mainVC = self.mainViewController {
			mainVC.startMatch()
		}
		
		UIApplication.shared.isIdleTimerDisabled = true
		self.startFindingChats(forReason: "tap-to-start")
		self.update(to: .RequestMatch)
	}
	
	@IBAction func exitButtonTapped(_ sender: Any) {
		if let mainVC = self.mainViewController {
			mainVC.endMatch()
		}
		
		UIApplication.shared.isIdleTimerDisabled = false
		self.stopFindingChats(forReason: "tap-to-start")
		self.update(to: .WaitingStart)
	}
	
	func beginMatchRequest() {
		guard self.matchRequestTimer == nil else {
			return
		}
		self.consumeMatchRequest()
		self.matchRequestTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(consumeMatchRequest), userInfo: nil, repeats: true)
	}
	
	func generateNewRequestID() {
		let characters = Array("abcdefghijklmnopqrstuvwxyz1234567890")
		var randomRequestID = ""
		
		for _ in 0...5 {
			let randomIndex = abs(Int.arc4random() % characters.count)
			randomRequestID.append(characters[randomIndex])
		}
		self.request_id = randomRequestID
		self.request_time = Date.init()
	}
	
	func consumeMatchRequest() {
		print("consume match request")
		
		if (self.chatRequest != nil || self.matchModel != nil) {
			print("Already finding because chatRequest or Retrieving new session before finished with old session.")
			return
		}
		
		self.generateNewRequestID()
		
		AnalyticsCenter.log(event: AnalyticEvent.matchRequestTotal)
		let parameters: [String: Any] = [
			"data": [
				"type": "chats",
				"attributes": [
					"matching_mode": MatchingMode.discover.rawValue,
					"match_mode": Achievements.shared.selectMatchMode?.rawValue ?? MatchMode.VideoMode.rawValue,
					"request_id": self.request_id!,
					"match_nearby": Achievements.shared.nearbyMatch,
				]
			]
		]
		
		RealmCall.request(url: RealmCall.common_request_path, method: .post, parameters: parameters) { (error) in
			print("Chat request completed with error = \(String(describing: error))")
			self.cancelMatchRequest()
			self.trackMatchRequest()
			LogManager.shared.addLog(type: .ApiRequest, subTitle: RealmCall.requst_subfix, info: [
				"error": "\(error.debugDescription)",
				"url": RealmCall.common_request_path,
				"method": HTTPMethod.post.rawValue,
				])
		}
	}
	
	func revokePrevMatchRequest(completion: (() -> Swift.Void)? = nil) {
		guard self.request_id == nil else {
			AnalyticsCenter.log(event: .matchCancel)
			
			self.request_id = nil
			self.cancelMatchRequest()
			if let authorization = APIController.authorization {
				JSONAPIRequest(url: "\(Environment.baseURL)/api/v1.3/match_cancel", method: .post, options: [
					.header("Authorization", authorization),
					]).addCompletionHandler { (_) in
						completion?()
				}
			}
			return
		}
		
		completion?()
	}
	
	func cancelMatchRequest() {
		if let chatRequest = self.chatRequest {
			chatRequest.cancel()
		}
		self.chatRequest = nil
	}
	
	func stopMatchRequest() {
		self.cancelMatchRequest()
		
		if self.matchRequestTimer != nil {
			self.matchRequestTimer?.invalidate()
			self.matchRequestTimer = nil
		}
	}
	
	func trackMatchRequest() {
		var commonParameters = self.commomParameters(for: AnalyticEvent.matchRequest)
		commonParameters["failure"] = "\(self.continuous_request_count)"
		
		AnalyticsCenter.add(amplitudeUserProperty: ["match_request": 1])
		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_request": 1])
		AnalyticsCenter.log(withEvent: AnalyticEvent.matchFirstRequest, andParameter: commonParameters)
		AnalyticsCenter.log(withEvent: AnalyticEvent.matchRequest, andParameter: commonParameters)
		
		self.continuous_request_count += 1;
	}
}

extension OnepMatchController {
	func showPopup(popup: UIView) {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hidePopup(popup:)), object: popup)
		popup.isHidden = false
		UIView.animate(withDuration: 0.2) {
			popup.alpha = 1
		}
		
		self.perform(#selector(hidePopup(popup:)), with: popup, afterDelay: 5)
	}
	
	func hidePopup(popup: UIView) {
		guard !popup.isHidden else {
			return
		}
		
		UIView.animate(withDuration: 0.2, animations: {
			popup.alpha = 0
		}) { ( _) in
			popup.isHidden = true
		}
	}
	
	func showRateAlert(reason: showRateAlertReason) {
		let rated = UserDefaults.standard.bool(forKey: "kHadRateBefore")
		if rated {return}
		UserDefaults.standard.set(true,forKey: "kHadRateBefore")
		if Configs.hadShowRateAlertToday() {return}
		
		self.stopFindingChats(forReason: "rateapp")
		let alert = UIAlertController(title: "Having fun with Monkey?", message: "🐒🐒🐒\nIf you like Monkey, plz give us a good review!", preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "I hate it", style: .cancel, handler: {
			(UIAlertAction) in
			AnalyticsCenter.log(withEvent: .ratePopClick, andParameter: [
				"entrance": reason.eventValue(),
				"type": "I hate it",
				])
			
			self.startFindingChats(forReason: "rateapp")
		}))
		
		alert.addAction(UIAlertAction(title: "Aight", style: .default, handler: {
			(UIAlertAction) in
			AnalyticsCenter.log(withEvent: .ratePopClick, andParameter: [
				"entrance": reason.eventValue(),
				"type": "Aight",
				])
			
			UserDefaults.standard.set(true, forKey: "kHadRateBefore")
			alert.dismiss(animated: true, completion: nil)
			self.startFindingChats(forReason: "rateapp")
			if UIApplication.shared.canOpenURL(NSURL.init(string: Environment.MonkeyAppRateURL)! as URL) {
				UIApplication.shared.openURL(NSURL.init(string: Environment.MonkeyAppRateURL)! as URL)
			}
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	func showAfterReportFriendAlert(userID: String) {
		if let realm = try? Realm(),
			let friendShip = realm.objects(RealmFriendship.self).filter("user.user_id = \"\(userID)\"").first {
			
			let alert = UIAlertController(title: nil, message: "Do you want to remove this user from your friend list?", preferredStyle: .alert)
			let remove = UIAlertAction.init(title: "Remove", style: .default, handler: { (action) in
				self.startFindingChats(forReason: "delete_report_friend")
				friendShip.delete(completion: { (error) in
					
				})
			})
			
			let cancel = UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
				self.startFindingChats(forReason: "delete_report_friend")
			})
			
			alert.addAction(remove)
			alert.addAction(cancel)
			
			self.stopFindingChats(forReason: "delete_report_friend")
			
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 1.0)) {
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
}

extension OnepMatchController: MatchObserver {
	func appMovedToBackground() {
		self.stopFindingChats(forReason: "application-status")
//		self.chatSession?.userTurnIntoBackground()
	}
	
	func appMovedToForeground() {
		self.startFindingChats(forReason: "application-status")
	}
	
	func appWillTerminate() {
		self.stopFindingChats(forReason: "application-status")
		
	}
}

extension OnepMatchController: TransationDelegate {
	func didMoveTo(screen: UIViewController) {
		self.stopFindingChats(forReason: "show-screen")
	}
	
	func didShowFrom(screen: UIViewController) {
		self.startFindingChats(forReason: "show-screen")
	}
}

