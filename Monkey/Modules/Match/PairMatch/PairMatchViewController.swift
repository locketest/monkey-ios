//
//  PairMatchViewController.swift
//  Release
//
//  Created by 王广威 on 2018/7/12.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper
import UIKit

class PairMatchViewController: MonkeyViewController {
	
	// match manager
	let matchManager = TwopMatchManager.default
	var matchHandler: MatchHandler!
	var matchModel: MatchModel? = nil
	var friendPairModel: FriendPairModel!
	
	fileprivate var nextFact = APIController.shared.currentExperiment?.initial_fact_discover ?? ""
	
	@IBOutlet weak var colorGradient: ColorGradientView!
	@IBOutlet weak var localPreview: LocalPreviewContainer!
	
	@IBOutlet weak var localPreviewHeightConstraints: NSLayoutConstraint!
	@IBOutlet weak var localPreviewWidthConstraints: NSLayoutConstraint!
	
	@IBOutlet weak var pairPreviewWidthConstaints: NSLayoutConstraint!
	@IBOutlet weak var pairPreviewHeightConstraints: NSLayoutConstraint!
	// pair info
	@IBOutlet weak var pairInstagramView: BigYellowButton!
	@IBOutlet weak var pairInfoView: UIView!
	
	@IBOutlet weak var remoteContainer: UIView!
	@IBOutlet weak var loadingTextLabel: LoadingTextLabel!
	@IBOutlet weak var factTextView: UILabel!
	
	@IBOutlet weak var closeButton: BigYellowButton!
	@IBOutlet weak var endCallButton: BigYellowButton!
	@IBOutlet weak var addTimeButton: BigYellowButton!
	
	@IBOutlet weak var clockLabelBackgroundView: UIView!
	@IBOutlet weak var clockLabel: CountingLabel!
	@IBOutlet weak var clockTimeIcon: UILabel!
	
	@IBOutlet weak var transationView: MatchPairTransation!
	@IBOutlet weak var statusLabel: UILabel!
	
	var remoteInfo: RemotePairInfo?
	
	// for click animate
	var currentMatchPastTime = 0
	var clockTime: Int = 15000
	var ticker: Timer?
	var isAnimatingMinuteAdd = false
	var animator: UIDynamicAnimator!
	var soundPlayer = SoundPlayer.shared
	
	var winEmojis = "🎉👻🌟😀💎♥️🎊🎁🐬🙉🔥"
	var clocks = "🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕜🕝🕞🕟🕠🕡🕢🕣🕤🕥🕦🕧"
	let throttleFunction = throttle(delay: 0.25, queue: DispatchQueue.main) {
		TapticFeedback.impact(style: .heavy)
	}
	
	/**
	When true, sets constraints to make the publisher camera view fill the screen.
	
	When false, sets constraints to pin to top right corner for a call.
	*/
	var isPublisherViewEnlarged = true { // true when skip button,
		didSet {
			if self.isPublisherViewEnlarged {
				localPreviewWidthConstraints.constant = self.view.frame.size.width
				localPreviewHeightConstraints.constant = self.view.frame.size.height
			} else {
				localPreviewWidthConstraints.constant = self.view.frame.size.width / 2
				localPreviewHeightConstraints.constant = self.view.frame.size.height / 2
			}
		}
	}
	var isAnimatingDismiss = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureApperance()
		self.configureLocalPreview()
		self.configurePairInfo()
		
		self.matchManager.delegate = self
		self.view.backgroundColor = UIColor.clear
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		UIApplication.shared.isIdleTimerDisabled = true
		self.enlargedPublisherView(enlarged: false)
		pairPreviewWidthConstaints.constant = self.view.frame.size.width / 2
		pairPreviewHeightConstraints.constant = self.view.frame.size.height / 2
		self.view.layoutIfNeeded()
		self.update(to: .RequestMatch)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	private func configureApperance() {
		
		self.clockLabelBackgroundView.layer.cornerRadius = 20
		self.clockLabelBackgroundView.layer.masksToBounds = true
		// initial status
		self.update(to: .PairConnecting)
		// tip
		self.update(tip: nil)
	}
	
	private func configureLocalPreview() {
		// add local preview
		self.localPreview.layer.cornerRadius = 0
		self.localPreview.addLocalPreview()
		self.enlargedPublisherView(duration: 0)
		self.animator = UIDynamicAnimator(referenceView: self.view)
	}
	
	func configurePairInfo(show: Bool = true) {
		let remotePreview = self.friendPairModel.left.renderContainer
		if show {
			self.pairInfoView.insertSubview(remotePreview, at: 0)
			remotePreview.frame = self.pairInfoView.bounds
			remotePreview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			remotePreview.backgroundColor = UIColor.purple
		}else {
			remotePreview.removeFromSuperview()
		}
	}
	
	func switchClock(open: Bool) {
		if open {
			guard self.ticker == nil else { return }
			
			// should show clock
			self.clockTime = 15000
			self.clockLabel.isHidden = false
			self.clockTimeIcon.isHidden = false
			self.clockLabel.delegate = self
			self.clockLabelBackgroundView.isHidden = false
			self.clockLabel.font = UIFont.monospacedDigitSystemFont(ofSize: self.clockLabel.font.pointSize, weight: UIFontWeightMedium)
			self.ticker = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
			// make sure timer always runs correctly
			RunLoop.main.add(self.ticker!, forMode: .commonModes)
		}else {
			self.stopClockTimer()
			
			self.clockTime = 0
			self.clockLabel.isHidden = true
			self.clockTimeIcon.isHidden = true
			self.clockLabelBackgroundView.isHidden = true
		}
	}
	
	func refresh(with friendStatus: Bool) {
		// disable clock
		self.switchClock(open: !friendStatus)
		self.localPreview.showSwitchCamera(show: friendStatus)
		if friendStatus {
			self.addTimeButton.isEnabled = false
			self.addTimeButton.isHidden = true
			
			self.endCallButton.isEnabled = true
			self.endCallButton.isHidden = false
		}else {
			self.addTimeButton.isEnabled = true
			self.addTimeButton.isHidden = false
			
			self.endCallButton.isEnabled = false
			self.endCallButton.isHidden = true
		}
	}
	
	func stopClockTimer() {
		self.ticker?.invalidate()
		self.ticker = nil
	}
	
	fileprivate var twopStatus: TwopStatus = .DashboardReady
	fileprivate func update(to newStatus: TwopStatus) {
		if newStatus == self.twopStatus {
			return
		}
		let oldStatus = self.twopStatus
		self.twopStatus = newStatus
		
		self.statusLabel.isHidden = (newStatus != .Connecting && newStatus != .Reconnecting)
//		self.transationView.isHidden = (newStatus != .Connecting && newStatus != .Reconnecting)
		self.remoteContainer.isHidden = (newStatus == .Reconnecting)
		self.localPreview.isHidden = (newStatus == .Reconnecting)
		self.pairInfoView.isHidden = (newStatus == .Reconnecting)
		self.closeButton.isHidden = (newStatus != .RequestMatch && newStatus != .WaitingConfirm)
		self.factTextView.isHidden = (newStatus != .RequestMatch && newStatus != .WaitingConfirm)
		self.loadingTextLabel.isHidden = (newStatus != .RequestMatch && newStatus != .WaitingConfirm)
		self.colorGradient.isHidden = (newStatus == .Chating)
		self.pairInstagramView.isHidden = (newStatus != .Chating)
		
		if newStatus != .Chating {
			self.endCallButton.isHidden = true
			self.clockLabelBackgroundView.isHidden = true
			self.addTimeButton.isHidden = true
			self.localPreview.showSwitchCamera(show: false)
		}
		
		switch oldStatus {
		case .DashboardReady:
			break
		case .PairConnecting:
			self.startFindingChats(forReason: "ready-to-start")
		case .RequestMatch:
			break
		case .WaitingConfirm:
			break
		case .WaitingResponse:
			break
		case .Connecting:
			break
		case .Chating:
//			self.disMiss
			break
		case .Reconnecting:
			break
		}
		
		switch newStatus {
		case .DashboardReady:
			// 回到 dashboard
			self.dismiss(complete: nil)
			break
		case .PairConnecting:
			// pair connecting
			break
		case .RequestMatch:
			self.startFindingChats(forReason: "receive-match")
			self.resetFact()
		case .WaitingConfirm:
			break
		case .WaitingResponse:
			self.showOneMatchInfo()
		case .Connecting:
			self.tryChating()
		case .Chating:
			self.refreshChating()
		case .Reconnecting:
			break
		}
	}
	
	fileprivate var matchRequestTimer: Timer?
	fileprivate var chatRequest: JSONAPIRequest? // use to know match request is running
	fileprivate var continuous_request_count = 0
	fileprivate var request_id: String?
	fileprivate var request_time: Date!
	fileprivate var isFindingMatch: Bool = false
	fileprivate var stopFindingReasons = ["ready-to-start"]
	
	fileprivate func handleReceivedMatch(match: MatchModel) {
		
		guard self.isFindingMatch == true else {
			print("Error: error state to receive match")
			return
		}
		
//		AnalyticsCenter.add(amplitudeUserProperty: ["match_receive": 1])
//		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_receive": 1])
//		self.chatSession?.track(matchEvent: .matchFirstRecieved)
//		self.chatSession?.track(matchEvent: .matchReceived)
		self.stopFindingChats(forReason: "receive-match")
		self.matchModel = match
		if match.matched_pair() {
			self.friendPairModel.myConfirmPair = match.match_id
			self.update(to: .WaitingConfirm)
		}else {
			// 如果是 1p，等别人操作
			self.update(to: .WaitingResponse)
		}
		self.matchManager.match(with: match)
	}
	
	fileprivate func handleMatchError(error: MatchError) {
		var convertError = error
		if error == .PairQuit {
			if self.twopStatus == .WaitingConfirm {
				let confirmJson: [String: Any] = [
					"type": MessageType.Confirm.rawValue,
					"sender": self.friendPairModel.left.user_id,
					"match_id": self.matchModel?.match_id ?? "",
					]
				
				// json to model
				if let message = Mapper<MatchMessage>().map(JSON: confirmJson) {
					self.receiveConfirm(message: message)
				}
				return
			}else if self.twopStatus == .Connecting || self.twopStatus == .Chating {
				convertError = .PairSkip
				return
			}
		}
		
		// 显示错误文案
		if self.twopStatus == .WaitingResponse, convertError.shouldShowTimeOut() {
			self.update(tip: "Time out!!", autoDismiss: true)
		}else if self.twopStatus == .WaitingResponse, convertError.shouldShowSkip() {
			self.update(tip: "Skipped!!", autoDismiss: true)
		}else {
			self.update(tip: nil)
		}
		// reset confirm
		self.friendPairModel.resetConfirm()
		// dismiss chat controller
		self.dismissMatchedView()
		//
		
		switch convertError {
		case .ReConnectTimeOut:
			fallthrough
		case .PairQuit:
			fallthrough
		case .MyQuit:
			// 退出，与好友断开连接
			self.stopFindingChats(forReason: "ready-to-start")
			self.matchManager.stopConnect(with: self.friendPairModel)
			self.update(to: .DashboardReady)
		case .MySkip:
			self.matchManager.sendMatchMessage(type: .PceOut)
			fallthrough
		default:
			// 断开连接
			self.matchManager.endChat()
			if self.matchModel?.matched_pair() == true && self.twopStatus.connectMatch() {
				// 与好友重连
				self.transationView.startReconnect()
				self.matchManager.reconnect(with: self.friendPairModel)
				self.update(tip: "Connecting...")
				self.update(to: .Reconnecting)
			}else if self.twopStatus.processMatch() {
				// 请求新的配对
				self.update(to: .RequestMatch)
			}
		}
		// reset local preview
		self.localPreview.reset()
		// 服务器上报配对结果，必须在上一步记录检测结果之后
		self.reportMatchEnd()
	}
	
	private func showOneMatchInfo() {
		guard let matchModel = self.matchModel else { return }
		self.update(tip: nil)
		
		if matchModel.matched_pair() == false {
			let remoteInfo = RemotePairInfo.init(frame: self.remoteContainer.bounds)
			self.remoteContainer.addSubview(remoteInfo)
			remoteInfo.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			remoteInfo.actionDelegate = self
			remoteInfo.show(with: matchModel)
			self.remoteInfo = remoteInfo
		}
	}
	
	private func showPairMatchInfo() {
		guard let matchModel = self.matchModel else { return }
		self.update(tip: nil)
		
		if matchModel.matched_pair() {
			let remoteInfo = RemotePairInfo.init(frame: self.view.bounds)
			self.view.insertSubview(remoteInfo, belowSubview: self.statusLabel)
			remoteInfo.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			remoteInfo.actionDelegate = self
			remoteInfo.show(with: matchModel)
			self.remoteInfo = remoteInfo
		}
	}
	
	fileprivate func tryConnecting() {
		guard let match = self.matchModel else { return }
		
		if match.matched_pair() {
			guard self.twopStatus == .WaitingConfirm else { return }
			self.showPairMatchInfo()
			self.remoteContainer.isHidden = true
			self.localPreview.isHidden = true
			self.pairInfoView.isHidden = true
			self.transationView.startConnect()
		}else {
			self.transationView.isHidden = true
			guard self.twopStatus == .WaitingResponse else { return }
		}
		self.update(tip: "Connecting...")
		self.matchManager.connect(with: match)
		self.update(to: .Connecting)
	}
	
	fileprivate func tryChating() {
		if self.twopStatus == .Connecting, let match = self.matchModel {
			// 如果已经收到所有人的流
			if match.allUserConnected() && friendPairModel.left.connected {
				// present
				self.showMatchedView()
				// stop timer
				self.matchManager.beginChat()
				// update status
				self.update(to: .Chating)
			}
		}else if self.twopStatus == .Reconnecting, friendPairModel.left.connected {
			// reconnect success
			self.matchManager.pairSuccess(with: self.friendPairModel)
			self.transationView.reconnectSuccess()
			self.update(to: .RequestMatch)
		}
	}
	
	func showMatchedView() {
		guard let match = self.matchModel else { return }
		guard let remoteInfo = self.remoteInfo else { return }
		
		remoteInfo.beginChat(with: match)
		if match.matched_pair() {
			self.transationView.connectSuccess()
			UIView.animate(withDuration: 0.25, animations: {
				remoteInfo.frame = self.remoteContainer.bounds
			}) { (_) in
				self.remoteContainer.addSubview(remoteInfo)
				self.checkFriendStatus()
			}
		}else {
			self.checkFriendStatus()
		}
	}
	
	func refreshChating() {
		if self.friendPairModel.left.instagram_id != nil {
			self.pairInstagramView.isHidden = false
		}else {
			self.pairInstagramView.isHidden = true
		}
	}
	
	func dismissMatchedView() {
		self.remoteInfo?.removeFromSuperview()
		self.remoteInfo = nil
	}
	
	func reportMatchEnd() {
		self.matchModel = nil
		self.stopClockTimer()
	}
	
	@IBAction func closeButtonClick(_ sender: Any) {
		let alert = UIAlertController(title: nil, message: "Are you sure you want to stop matching?😢", preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self]
			(UIAlertAction) in
			self?.handleMatchError(error: .MyQuit)
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBAction func pairInstagramClick(_ sender: Any) {
		self.insgramTapped(to: self.friendPairModel.left)
	}
	@IBAction func endCallClick(_ sender: Any) {
		self.matchManager.sendMatchMessage(type: .PceOut)
		self.handleMatchError(error: .MySkip)
	}
	
	@IBAction func addTimeClick(_ sender: Any) {
		self.addTimeTapped()
	}
}

// MARK: - loading view logic
extension PairMatchViewController {
	fileprivate func setFactText(_ text: String) {
		self.factTextView.text = text
	}
	
	fileprivate func resetFact() {
		self.setFactText(self.nextFact)
		self.friendPairModel.left.addTimeCount = 0
		self.friendPairModel.resetConfirm()
	}
	
	fileprivate func update(tip: String?, autoDismiss: Bool = false) {
		if let tip = tip {
			self.statusLabel.alpha = 1.0
			self.statusLabel.text = tip
			self.statusLabel.layer.opacity = 1.0
			if autoDismiss {
				UIView.animate(withDuration: 1.5, animations: {
					self.statusLabel.layer.opacity = 0.0
				})
			}
		}else {
			self.statusLabel.alpha = 0.0
		}
	}
}

// request match
extension PairMatchViewController {
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
		
		if oldReasonsCount == 0 && forReason == "ready-to-start" {
			self.revokePrevMatchRequest()
		}
	}
	
	func beginMatchRequest() {
		guard self.matchRequestTimer == nil, let currentUserID = Int(UserManager.UserID ?? "0"), currentUserID > self.friendPairModel.left.user_id else {
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
		let parameters = [
			"request_id": self.request_id!,
			"pair_id": self.friendPairModel.pair_id,
		]
		
		self.chatRequest = MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/request/twop", parameters: parameters, jsonCompletion: { (_) in
			self.cancelMatchRequest()
			self.trackMatchRequest()
		})
	}
	
	func revokePrevMatchRequest(completion: (() -> Swift.Void)? = nil) {
		guard self.request_id == nil else {
			AnalyticsCenter.log(event: .matchCancel)
			
			self.request_id = nil
			self.cancelMatchRequest()
			self.chatRequest = MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/cancel/twop", jsonCompletion: { (_) in
				
			})
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
//		var commonParameters = self.commomParameters(for: AnalyticEvent.matchRequest)
//		commonParameters["failure"] = "\(self.continuous_request_count)"
//
//		AnalyticsCenter.add(amplitudeUserProperty: ["match_request": 1])
//		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_request": 1])
//		AnalyticsCenter.log(withEvent: AnalyticEvent.matchFirstRequest, andParameter: commonParameters)
//		AnalyticsCenter.log(withEvent: AnalyticEvent.matchRequest, andParameter: commonParameters)
//
//		self.continuous_request_count += 1;
	}
	
	func trackMatchReceive() {
//		var commonParameters = self.commomParameters(for: AnalyticEvent.matchRequest)
//		commonParameters["failure"] = "\(self.continuous_request_count)"
//
//		AnalyticsCenter.add(amplitudeUserProperty: ["match_request": 1])
//		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_request": 1])
//		AnalyticsCenter.log(withEvent: AnalyticEvent.matchFirstRequest, andParameter: commonParameters)
//		AnalyticsCenter.log(withEvent: AnalyticEvent.matchRequest, andParameter: commonParameters)
//
//		self.continuous_request_count += 1;
	}
	
	func trackMatchSuccess() {
//		var commonParameters = self.commomParameters(for: AnalyticEvent.matchRequest)
//		commonParameters["failure"] = "\(self.continuous_request_count)"
//
//		AnalyticsCenter.add(amplitudeUserProperty: ["match_request": 1])
//		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_request": 1])
//		AnalyticsCenter.log(withEvent: AnalyticEvent.matchFirstRequest, andParameter: commonParameters)
//		AnalyticsCenter.log(withEvent: AnalyticEvent.matchRequest, andParameter: commonParameters)
//
//		self.continuous_request_count += 1;
	}
}

extension PairMatchViewController: RemoteActionDelegate {
	func friendTapped(to user: MatchUser) {
		OnepMatchManager.default.sendMatchMessage(type: .AddFriend, to: user)
		if user.friendRequested {
			user.friendAccept = true
			self.addFriendSuccess()
			self.remoteInfo?.addFriend(user: user)
		}else {
			user.friendRequest = true
		}
	}
	func reportTapped(to user: MatchUser) {
		self.report(user: user)
	}
	func insgramTapped(to user: MatchUser) {
		let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as! InstagramPopupViewController
		instagramVC.userId = String(user.user_id)
		instagramVC.followMyIGTagBool = false
		self.present(instagramVC, animated: true)
	}
	func addTimeTapped() {
		guard let match = self.matchModel else { return }
		
		OnepMatchManager.default.sendMatchMessage(type: .AddTime)
		if match.addTimeRequestCount == self.friendPairModel.left.addTimeCount {
			match.addTimeRequestCount += 1
			self.friendPairModel.left.addTimeCount += 1
		}
		if match.addTimeRequestCount == match.left.addTimeCount {
			self.minuteAdded()
		}else {
			self.disableAddMinute()
		}
	}
}

extension PairMatchViewController: MessageObserver {
	func handleReceivedMessage(message: MatchMessage) {
		let type = MessageType.init(type: message.type)
		switch type {
		case .AddTime:
			self.receivedAddTime(message: message)
		case .Skip:
			self.receiveSkip(message: message)
		case .Accept:
			self.receiveAccept(message: message)
		case .Confirm:
			self.receiveConfirm(message: message)
		case .Report:
			self.receivedReport(message: message)
		case .AddFriend:
			self.receivedAddSnapchat(message: message)
		default:
			break
		}
	}
	
	fileprivate func receiveConfirm(message: MatchMessage) {
		if self.twopStatus == .WaitingConfirm {
			self.friendPairModel.friendConfirmPair = message.match_id
			if self.friendPairModel.confirmMatch() {
				self.tryConnecting()
			}else {
				self.friendPairModel.resetConfirm()
				self.update(to: .RequestMatch)
			}
		}else {
			self.friendPairModel.resetConfirm()
		}
	}
	
	fileprivate func receiveSkip(message: MatchMessage) {
		guard let matchModel = self.matchModel else { return }
		
		if message.match_id == matchModel.match_id {
			if message.sender == friendPairModel.friend.user_id {
				self.handleMatchError(error: .PairSkip)
			}else if let sender = message.sender, let matchedUser = matchModel.matchedUser(with: sender) {
				matchedUser.skip = true
				self.handleMatchError(error: .OtherSkip)
			}
		}
	}
	
	fileprivate func receiveAccept(message: MatchMessage) {
		guard let matchModel = self.matchModel else { return }
		
		if message.match_id == matchModel.match_id {
			if let sender = message.sender, let matchedUser = matchModel.matchedUser(with: sender) {
				matchedUser.accept = true
				self.tryConnecting()
			}
		}
	}
	
	func didReceiveTwopMatch(match: MatchModel) {
		if let nextFact = match.fact {
			self.nextFact = nextFact
		}
		
		self.handleReceivedMatch(match: match)
	}
}

extension PairMatchViewController: MatchServiceObserver {
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

extension PairMatchViewController: MatchObserver {
	func presentVideoCall(after completion: @escaping () -> Void) {
		self.stopFindingChats(forReason: "receive-videocall")
		self.disconnect(reason: .MySkip)
		self.dismiss(complete: completion)
	}
	
	func didDismissVideoCall(call: VideoCallModel) {
		self.startFindingChats(forReason: "receive-videocall")
	}
	
	func didReceiveMessage(type: String, in chat: String) {
		
	}
	
	func matchTypeChanged(newType: MatchType) {
		
	}
	
	func appMovedToBackground() {
		
	}
	
	func appMovedToForeground() {
		
	}
	
	func appWillTerminate() {
		self.startFindingChats(forReason: "app-die")
		self.disconnect(reason: .MyQuit)
	}
}

extension PairMatchViewController: MatchMessageObserver {
	
	fileprivate func enlargedPublisherView(enlarged: Bool = true, duration: TimeInterval = 0.3, complete: CompletionHandler? = nil) {
		self.isPublisherViewEnlarged = enlarged
		UIView.animate(withDuration: duration, animations: {
			self.view.layoutIfNeeded()
		}) { (_) in
			complete?()
		}
	}
	
	func present(from matchHandler: MatchHandler, with matchModel: ChannelModel, complete: CompletionHandler?) {
		self.friendPairModel = matchModel as! FriendPairModel
		self.matchHandler = matchHandler
		matchHandler.present(self, animated: false, completion: complete)
	}
	
	func dismiss(complete: CompletionHandler?) {
		guard self.isAnimatingDismiss == false else {
			complete?()
			return
		}
		
		self.revokePrevMatchRequest()
		self.stopClockTimer()
		self.isAnimatingDismiss = true
		self.view.isUserInteractionEnabled = false
		self.enlargedPublisherView(enlarged: true) { [weak self] in
			self?.dismiss(animated: false, completion: {
				complete?()
				self?.matchHandler.disconnect(reason: .MyQuit)
			})
		}
	}
}
