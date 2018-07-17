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

typealias MatchHandler = UIViewController & MatchServiceObserver

protocol MatchMessageObserver {
	func handleReceivedMessage(message: MatchMessage)
	func present(from matchHandler: MatchHandler, with matchModel: ChannelModel, complete: CompletionHandler?)
	func dismiss(complete: CompletionHandler?)
}

class OnepMatchController: MonkeyViewController {
	
	// match manager
	fileprivate let matchManager = OnepMatchManager.default
	fileprivate var nextFact = APIController.shared.currentExperiment?.initial_fact_discover ?? ""
	
	// tap to start
	@IBOutlet weak var startView: UIView!
	@IBOutlet weak var fingerLabel: UILabel!
	@IBOutlet weak var exitButton: BigYellowButton!
	
	// content
	@IBOutlet weak var loadingContentView: MakeUIViewGreatAgain!
	// match tips
	@IBOutlet weak var loadingTextLabel: LoadingTextLabel!
	
	// user info
	@IBOutlet weak var commonTreeTip: UILabel!
	@IBOutlet weak var matchUserPhoto: UIImageView!
	
	@IBOutlet weak var leftPhoto: UIImageView!
	@IBOutlet weak var leftBio: UILabel!
	
	
	@IBOutlet weak var rightPhoto: UIImageView!
	@IBOutlet weak var rightBio: UILabel!
	
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
		
//		Step 2: if show state 1
		self.configureTapToStart()
	}
	
	private func configureApperance() {
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
		
		// user icon
		self.leftBio.isHidden = true
		self.leftPhoto.isHidden = true
		self.leftPhoto.layer.cornerRadius = 27
		self.leftPhoto.layer.masksToBounds = true
		self.leftPhoto.layer.shadowRadius = 4
		
		// user icon
		self.rightBio.isHidden = true
		self.rightPhoto.isHidden = true
		self.rightPhoto.layer.cornerRadius = 27
		self.rightPhoto.layer.masksToBounds = true
		self.rightPhoto.layer.shadowRadius = 4
		
		// fact
		self.acceptButton.isHidden = true
		self.rejectButton.isHidden = true
		self.skipButton.isHidden = true
		
		// tip
		self.update(tip: nil)
	}
	
	private func configureTapToStart() {
		let showStateReady = (2 < 1)
		if showStateReady {
			let startGesture = UITapGestureRecognizer.init(target: self, action: #selector(startFindingMatch))
			self.startView.addGestureRecognizer(startGesture)
		}else {
			self.exitButton.isHidden = true
			self.startView.isHidden = true
			self.startFindingMatch()
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.refreshMatchModeStatus()
	}
	
	fileprivate func refreshMatchModeStatus() {
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
	
	fileprivate func loadCurrentEventMode() {
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
		
//		self.startView.isHidden = (newStatus != .WaitingStart)
//		self.exitButton.isHidden = (newStatus != .RequestMatch)
		self.factTextView.isHidden = (newStatus == .WaitingStart || newStatus == .Chating)
		self.loadingContentView.isHidden = (newStatus == .WaitingStart || newStatus == .Chating)
		self.loadingTextLabel.isHidden = (newStatus != .RequestMatch)
		self.matchModeContainer.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.leftPhoto.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.leftBio.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.rightPhoto.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.rightBio.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.matchUserPhoto.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.commonTreeTip.isHidden = (newStatus != .WaitingResponse && newStatus != .Connecting)
		self.skippedText.isHidden = (newStatus == .WaitingStart || newStatus == .Chating)
		self.acceptButton.isHidden = (newStatus != .WaitingResponse)
		self.rejectButton.isHidden = (newStatus != .WaitingResponse)
		self.skipButton.isHidden = (newStatus != .WaitingResponse)
		self.refreshMatchModeStatus()
		
		switch oldStatus {
		case .WaitingStart:
			break
		case .RequestMatch:
			break
		case .WaitingResponse:
			break
		case .Connecting:
			break
		case .Chating:
			self.startFindingChats(forReason: "chating")
		}
		
		switch newStatus {
		case .WaitingStart:
			// 回到状态1
			self.stopFindingChats(forReason: "tap-to-start")
		case .RequestMatch:
			if oldStatus == .WaitingStart {
				// 从状态1过来
				self.startFindingChats(forReason: "tap-to-start")
			}else {
				// 从其他状态过来
				self.startFindingChats(forReason: "receive-match")
				mainVC.endMatchProcess()
			}
			self.resetFact()
		case .WaitingResponse:
			mainVC.beginMatchProcess()
			self.stopFindingChats(forReason: "receive-match")
			self.showMatchInfo()
		case .Connecting:
			self.tryChating()
		case .Chating:
			self.stopFindingChats(forReason: "chating")
		}
	}
	
	fileprivate var responseTimeoutCount = 0
	fileprivate var matchRequestTimer: Timer?
	fileprivate var chatRequest: JSONAPIRequest? // use to know match request is running
	fileprivate var continuous_request_count = 0
	fileprivate var request_id: String?
	fileprivate var request_time: Date!
	fileprivate var isFindingMatch: Bool = false
	fileprivate var stopFindingReasons = ["tap-to-start"]
	
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
		self.acceptMatch(auto: false)
	}
	
	private func acceptMatch(auto: Bool) {
		self.responseTimeoutCount = 0
		self.acceptButton.isHidden = true
		self.skipButton.isHidden = true
		self.rejectButton.isHidden = true
		
		guard let matchModel = self.matchModel else { return }
		
		let user_id: Int = matchModel.left.user_id
		let duration: TimeInterval = matchModel.beginTime.timeIntervalSince1970 - self.request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Accept",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(withEvent: .matchSendAccept, andParameter: [
			"type": auto ? "auto accept" : "btn accept",
			])
		matchModel.accept = true
		self.matchManager.accept(auto: false)
		self.update(tip: "Waiting...")
		self.tryConnecting()
	}
	
	@IBAction func rejectButtonTapped(_ sender: Any) {
		self.skipMatch(auto: false, reject: true)
	}
	
	@IBAction func skipButtonTapped(_ sender: Any) {
		self.skipMatch(auto: false, reject: false)
	}
	
	private func skipMatch(auto: Bool, reject: Bool) {
		self.responseTimeoutCount = 0
		guard let matchModel = self.matchModel else { return }
		
		let user_id: Int = matchModel.left.user_id
		let duration: TimeInterval = matchModel.beginTime.timeIntervalSince1970 - self.request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": reject ? "Reject" : "Skip",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(event: .matchSendSkip)
		matchModel.skip = true
		self.matchManager.skip(auto: auto)
		// 如果不是 auto skip，需要继续处理
		if auto == false {
			self.handleMatchError(error: .MySkip)
		}
	}
	
	fileprivate func handleReceivedMatch(match: MatchModel) {
//		AnalyticsCenter.add(amplitudeUserProperty: ["match_receive": 1])
//		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_receive": 1])
//		self.chatSession?.track(matchEvent: .matchFirstRecieved)
//		self.chatSession?.track(matchEvent: .matchReceived)
		self.matchModel = match
		self.update(to: .WaitingResponse)
		self.matchManager.match(with: match)
		
		// auto accept
		if Achievements.shared.autoAcceptMatch && match.matched_pair() == false {
			self.acceptMatch(auto: true)
		}
	}
	
	fileprivate func handleMatchError(error: MatchError) {
		guard self.onepStatus.processMatch() else { return }
		
		// auto skip
		if self.onepStatus == .WaitingResponse {
			self.skipMatch(auto: true, reject: false)
		}
		
		// 显示错误文案
		if self.onepStatus == .Connecting, error.shouldShowTimeOut() {
			self.update(tip: "Time out!!", autoDismiss: true)
		}else if self.onepStatus == .WaitingResponse, error.shouldShowSkip() {
			self.update(tip: "Skipped!!", autoDismiss: true)
		}else {
			self.update(tip: nil)
		}
		
		// dismiss chat controller
		self.dismissMatchedView()
		
		// 断开连接
		self.matchManager.disconnect()
		
		// 服务器上报配对结果，必须在上一步记录检测结果之后
		self.reportMatchEnd()
		
		// 更新状态
		self.update(to: .RequestMatch)
	}
	
	private func showMatchInfo() {
		guard let matchModel = self.matchModel else { return }
		
		if matchModel.matched_pair() {
			matchModel.left.accept = true
			matchModel.right?.accept = true
			
			self.commonTreeTip.isHidden = true
			self.matchUserPhoto.isHidden = true
			self.factTextView.isHidden = true
			
			self.leftBio.isHidden = false
			self.leftPhoto.isHidden = false
			self.rightBio.isHidden = false
			self.rightPhoto.isHidden = false
			
			let leftPlaceholder = UIImage.init(named: matchModel.left.defaultAvatar)
			let left_profile_photo_url = URL.init(string: matchModel.left.photo_read_url ?? "")
			self.leftPhoto.kf.setImage(with: left_profile_photo_url, placeholder: leftPlaceholder)
			self.leftBio.text = matchModel.left.showedBio()
			
			if let right = matchModel.right {
				let rightPlaceholder = UIImage.init(named: right.defaultAvatar)
				let right_profile_photo_url = URL.init(string: right.photo_read_url ?? "")
				self.rightPhoto.kf.setImage(with: right_profile_photo_url, placeholder: rightPlaceholder)
				self.rightBio.text = right.showedBio()
			}
			
		}else {
			self.leftBio.isHidden = true
			self.leftPhoto.isHidden = true
			self.rightBio.isHidden = true
			self.rightPhoto.isHidden = true
			
			if let commonChannel = matchModel.left.commonChannel() {
				self.commonTreeTip.text = commonChannel.emoji
				self.commonTreeTip.isHidden = false
			}else {
				self.commonTreeTip.isHidden = true
			}
			
			self.matchUserPhoto.isHidden = false
			let placeholder = UIImage.init(named: matchModel.left.defaultAvatar)
			let profile_photo_url = URL.init(string: matchModel.left.photo_read_url ?? "")
			self.matchUserPhoto.kf.setImage(with: profile_photo_url, placeholder: placeholder)
			self.setFactText(matchModel.showedBio(for: matchModel.left.user_id))
		}
		
		let matchMode = matchModel.match_room_mode
		self.acceptButton.backgroundColor = matchMode.backgroundColor
		self.matchModeEmojiLeft.text = matchMode.emoji
		self.matchModeEmojiRight.text = matchMode.emoji
		self.matchModeTip.text = matchMode.title
		self.factTextBottom.constant = matchMode.pedding
		self.matchModeContainer.layer.borderColor = matchMode.borderColor
		self.matchModeTip.textColor = matchMode.titleColor
		
		self.update(tip: nil)
	}
	
	fileprivate func tryConnecting() {
		guard self.onepStatus == .WaitingResponse else { return }
		guard let matchModel = self.matchModel else { return }
		
		// 如果都 accept 了
		if matchModel.accept && matchModel.allUserAccepted() {
			self.update(tip: "Connecting...")
			self.matchManager.connect()
			self.update(to: .Connecting)
			if matchModel.matched_pair() {
				self.matchUserPhoto.isHidden = true
				self.commonTreeTip.isHidden = true
				self.factTextView.isHidden = true
			}else {
				self.leftBio.isHidden = true
				self.leftPhoto.isHidden = true
				self.rightBio.isHidden = true
				self.rightPhoto.isHidden = true
				
				if let commonChannel = matchModel.left.commonChannel() {
					self.commonTreeTip.text = commonChannel.emoji
					self.commonTreeTip.isHidden = false
				}else {
					self.commonTreeTip.isHidden = true
				}
			}
		}
	}
	
	fileprivate func tryChating() {
		guard self.onepStatus == .Connecting else { return }
		guard let matchModel = self.matchModel else { return }
		
		// 如果已经收到所有人的流
		if matchModel.allUserConnected() {
			// present
			self.showMatchedView()
			// stop timer
			self.matchManager.beginChat()
			// update status
			self.update(to: .Chating)
		}
	}
	
	var matchViewController: MatchMessageObserver?
	func showMatchedView() {
		guard let matchModel = self.matchModel else { return }
		
		Achievements.shared.totalChats += 1
		var matchModeId = "callVC"
		if matchModel.matched_pair() {
			matchModeId = "OnepPair"
		}else if (matchModel.match_room_mode == .TextMode) {
			matchModeId = "textModeVC"
		}
		
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: matchModeId) as! MatchMessageObserver
		self.matchViewController = matchViewController
		matchViewController.present(from: self, with: matchModel, complete: nil)
	}
	
	func dismissMatchedView(complete: (() -> Void)? = nil) {
		guard let matchViewController = self.matchViewController else {
			complete?()
			return
		}
		
		self.matchViewController = nil
		matchViewController.dismiss(complete: { [weak self] in
			if let complete = complete {
				complete()
				return
			}
			guard self?.onepStatus == .RequestMatch else { return }
			// should show unfriend
			self?.processEndMatch()
		})
	}
	
	func processEndMatch() {
		guard let matchModel = self.matchModel else { return }
		
		// unfriend
		if matchModel.isReportPeople(), matchModel.friendAdded() {
//			self.showAfterReportFriendAlert(userID: userID)
		}
		
		// screen shot when disconnect
		if matchModel.match_room_mode == .VideoMode && matchModel.addTimeCount() == 0 {
//			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}else if matchModel.match_room_mode == .TextMode && matchModel.isUnmuted() == false, matchModel.chatDuration > 30 {
//			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}else if matchModel.chatDuration <= 30.0 {
//			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}
		
		// show rating
		if matchModel.friendAdded(), UserDefaults.standard.bool(forKey: showRateAlertReason.addFriendJust.rawValue) == false {
			UserDefaults.standard.set(true, forKey: showRateAlertReason.addFriendJust.rawValue)
			self.showRateAlert(reason: .addFriendJust)
		} else if Configs.contiLogTimes() == 3,
			UserDefaults.standard.bool(forKey: showRateAlertReason.contiLoginThreeDay.rawValue) == false {
			UserDefaults.standard.set(true,forKey: showRateAlertReason.contiLoginThreeDay.rawValue)
			self.showRateAlert(reason: .contiLoginThreeDay)
		}
	}
	
	func reportMatchEnd() {
		self.matchModel = nil
	}
}

// MARK: - loading view logic
extension OnepMatchController {
	fileprivate func setFactText(_ text: String) {
		self.factTextView.text = text
	}
	
	fileprivate func resetFact() {
		self.setFactText(self.nextFact)
	}
	
	fileprivate func update(tip: String?, autoDismiss: Bool = false) {
		if let tip = tip {
			self.skippedText.alpha = 1.0
			self.skippedText.text = tip
			self.skippedText.layer.opacity = 1.0
			if autoDismiss {
				UIView.animate(withDuration: 1.5, animations: {
					self.skippedText.layer.opacity = 0.0
				})
			}
		}else {
			self.skippedText.alpha = 0.0
		}
	}
}

// request match
extension OnepMatchController {
	func startFindingChats(forReason: String) {
		let oldReasonCount: Int = self.stopFindingReasons.count
		let reason = self.stopFindingReasons.removeObject(object: forReason)
		print("Started finding: \(reason)")
		if self.stopFindingReasons.count == 0 {
			self.isFindingMatch = true
			if oldReasonCount != 0 {
				self.beginMatchRequest()
			}
		} else {
			print("Still not finding because: \(self.stopFindingReasons.split(separator: ","))")
		}
	}
	
	func stopFindingChats(forReason: String) {
		print("Stopped finding: \(forReason)")
		self.continuous_request_count = 0
		self.isFindingMatch = false
		
		let oldReasonsCount = stopFindingReasons.count
		self.stopFindingReasons.append(forReason)
		if oldReasonsCount == 0 {
			self.stopMatchRequest()
		}
		
		if oldReasonsCount == 0 && (forReason == "show-screen" || forReason == "tap-to-start") {
			self.revokePrevMatchRequest()
		}
	}
	
	func startFindingMatch() {
		UIApplication.shared.isIdleTimerDisabled = true
		self.update(to: .RequestMatch)
	}
	
	@IBAction func exitButtonTapped(_ sender: Any) {
		UIApplication.shared.isIdleTimerDisabled = false
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
		
		if (self.chatRequest != nil || self.isFindingMatch == false) {
			print("Already finding because chatRequest or Retrieving new session before finished with old session.")
			return
		}
		
		self.generateNewRequestID()
		AnalyticsCenter.log(event: AnalyticEvent.matchRequestTotal)
		let matchMode: MatchMode = Achievements.shared.selectMatchMode ?? MatchMode.VideoMode
		let parameters: [String: Any] = [
			"match_mode": matchMode.rawValue,
			"request_id": self.request_id!,
			"enable_nearby": Achievements.shared.nearbyMatch,
			]
		
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/request/onep", parameters: parameters) { (_) in
			self.cancelMatchRequest()
			self.trackMatchRequest()
		}
	}
	
	func revokePrevMatchRequest(completion: (() -> Swift.Void)? = nil) {
		if self.request_id != nil {
			self.request_id = nil
			self.cancelMatchRequest()
			AnalyticsCenter.log(event: .matchCancel)
			
			MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/cancel/onep", method: .post) { (_) in
				completion?()
			}
		}else {
			completion?()
		}
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
	
	func trackMatchReceive() {
		var commonParameters = self.commomParameters(for: AnalyticEvent.matchRequest)
		commonParameters["failure"] = "\(self.continuous_request_count)"
		
		AnalyticsCenter.add(amplitudeUserProperty: ["match_request": 1])
		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_request": 1])
		AnalyticsCenter.log(withEvent: AnalyticEvent.matchFirstRequest, andParameter: commonParameters)
		AnalyticsCenter.log(withEvent: AnalyticEvent.matchRequest, andParameter: commonParameters)
		
		self.continuous_request_count += 1;
	}
	
	func trackMatchSuccess() {
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

extension OnepMatchController {
	func handleReceivedMessage(message: MatchMessage) {
		let type = MessageType.init(type: message.type)
		switch type {
		case .Skip:
			self.receiveSkip()
		case .Accept:
			self.receiveAccept()
		case .PceOut:
			self.receivePceOut(message: message)
		case .Report:
			self.receiveReport(message: message)
		default:
			self.matchViewController?.handleReceivedMessage(message: message)
		}
	}
	
	fileprivate func receiveSkip() {
		self.matchModel?.left.skip = true
		self.handleMatchError(error: .OtherSkip)
	}
	
	fileprivate func receiveAccept() {
		self.matchModel?.left.accept = true
		self.tryConnecting()
	}
	
	fileprivate func receivePceOut(message: MatchMessage) {
		if let sender = message.sender, self.matchModel?.matchedUser(with: sender) != nil {
			self.handleMatchError(error: .OtherSkip)
		}
	}
	
	fileprivate func receiveReport(message: MatchMessage) {
		
	}
}

extension OnepMatchController: MatchServiceObserver {
	func disconnect(reason: MatchError) {
		self.handleMatchError(error: reason)
	}
	
	func remoteVideoReceived(user user_id: Int) {
		// 收到对方的视频流
		self.tryChating()
	}
	
	func channelMessageReceived(message: MatchMessage) {
		self.handleReceivedMessage(message: message)
	}
}

extension OnepMatchController: MatchObserver {
	func didReceiveOnepMatch(match: MatchModel) {
		
		if let nextFact = match.fact {
			self.nextFact = nextFact
		}
		
		guard match.request_id == self.request_id else {
			print("Error: match message object did not return with sufficient data to create a chatSession")
			return
		}
		
		guard self.isFindingMatch == true else {
			print("Error: error state to receive match")
			return
		}
		
		self.handleReceivedMatch(match: match)
	}
	
	func didReceiveMessage(type: String, in chat: String) {
		guard let matchModel = self.matchModel else { return }
		guard matchModel.match_id == chat else {
			return
		}
		let messageJson = [
			"type": type,
			"match_id": chat,
		]
		
		if let matchMessage = Mapper<MatchMessage>().map(JSON: messageJson) {
			self.handleReceivedMessage(message: matchMessage)
		}
	}
	
	func matchTypeChanged(newType: MatchType) {
		if newType == .Onep {
			self.matchManager.delegate = self
			self.startFindingChats(forReason: "switch-twop")
		}else {
			self.matchManager.delegate = nil
			self.stopFindingChats(forReason: "switch-twop")
		}
	}
	
	func appMovedToBackground() {
		self.stopFindingChats(forReason: "application-status")
//		self.chatSession?.userTurnIntoBackground()
	}
	
	func appMovedToForeground() {
		self.startFindingChats(forReason: "application-status")
	}
	
	func appWillTerminate() {
		self.stopFindingChats(forReason: "application-status")
		self.disconnect(reason: .MyQuit)
	}
	
	func presentVideoCall(after completion: @escaping () -> Void) {
		self.stopFindingChats(forReason: "receive-videocall")
		self.dismissMatchedView {
			self.disconnect(reason: .MyQuit)
			completion()
		}
	}
	
	func willPresentVideoCall(call: VideoCallModel) {
		self.disconnect(reason: .MyQuit)
	}
	
	func didDismissVideoCall(call: VideoCallModel) {
		self.startFindingChats(forReason: "receive-videocall")
	}
}

extension OnepMatchController: TransationDelegate {
	func didMoveTo(screen: UIViewController) {
		self.stopFindingChats(forReason: "show-screen")
		self.update(tip: nil)
	}
	
	func didShowFrom(screen: UIViewController) {
		self.startFindingChats(forReason: "show-screen")
	}
}

