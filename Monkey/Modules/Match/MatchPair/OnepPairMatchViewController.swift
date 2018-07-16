//
//  OnepPairMatchViewController.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/11.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import UIKit

class OnepPairMatchViewController: MonkeyViewController {
	// MARK: Interface Elements
	/// The orange view behind the clock label, animated on addMinute
	@IBOutlet weak var clockLabelBackgroundView: UIView!
	@IBOutlet weak var clockTimeIcon: UILabel!
	@IBOutlet weak var clockLabel: CountingLabel!
	
	@IBOutlet weak var publisherContainerViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerView: LocalPreviewContainer!
	
	@IBOutlet weak var remotePairView: RemotePairInfo!
	// add time
	@IBOutlet weak var addMinuteButton: BigYellowButton!
	
	// end call for friend
	@IBOutlet weak var endCallButton: BigYellowButton!
	// match model
	weak var matchModel: MatchModel!
	// match matchHandler
	weak var matchHandler: MatchHandler!
	
	// for click animate
	var clockTime: Int = 15000
	var ticker: Timer?
	var isAnimatingMinuteAdd = false
	var animator: UIDynamicAnimator!
	var soundPlayer = SoundPlayer.shared
	var isAnimatingDismiss = false
	
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
				publisherContainerViewHeightConstraint.constant = self.view.frame.size.height
			} else {
				publisherContainerViewHeightConstraint.constant = self.view.frame.size.height / 2
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureLocalPreview()
		self.configureRemotePreview()
	}
	
	func switchClock(open: Bool) {
		if open {
			// should show clock
			self.clockLabel.delegate = self
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
	
	func stopClockTimer() {
		self.ticker?.invalidate()
		self.ticker = nil
	}
	
	func configureLocalPreview() {
		// add local preview
		self.publisherContainerView.layer.cornerRadius = 0
		self.publisherContainerView.addLocalPreview()
		self.enlargedPublisherView(duration: 0)

		self.clockLabelBackgroundView.layer.cornerRadius = 20
		self.clockLabelBackgroundView.layer.masksToBounds = true

		self.animator = UIDynamicAnimator(referenceView: self.view)
	}
	
	func configureRemotePreview() {
		self.remotePairView.alpha = 0
		self.remotePairView.actionDelegate = self
		self.remotePairView.beginChat(with: self.matchModel)
		
		self.checkFriendStatus()
	}
	
	func refresh(with friendStatus: Bool) {
		self.publisherContainerView.showSwitchCamera(show: friendStatus)
		if friendStatus {
			// hide addtime\clock
			self.addMinuteButton.isEnabled = false
			self.addMinuteButton.isHidden = true
			
			self.endCallButton.isEnabled = true
			self.endCallButton.isHidden = false
			
		}else {
			// 不是好友
			self.addMinuteButton.isEnabled = true
			self.addMinuteButton.isHidden = false
			
			self.endCallButton.isEnabled = false
			self.endCallButton.isHidden = true
		}
		
		// refresh clock
		self.switchClock(open: !friendStatus)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.enlargedPublisherView(enlarged: false)
	}
	
	@IBAction func endCall(_ sender: BigYellowButton) {
		self.endCallButton.isEnabled = false
		self.endCallButton.layer.opacity = 0.5
		self.dismiss(complete: nil)
	}
}

extension OnepPairMatchViewController: RemoteActionDelegate {
	func friendTapped(to user: MatchUser) {
		OnepMatchManager.default.sendMatchMessage(type: .AddFriend, to: user)
		if user.friendRequested {
			user.friendAccept = true
			self.addFriendSuccess()
			self.remotePairView.addFriend(user: user)
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
		OnepMatchManager.default.sendMatchMessage(type: .AddTime)
		self.matchModel.addTimeRequestCount += 1
		if self.matchModel.addTimeRequestCount == self.matchModel.left.addTimeCount {
			self.minuteAdded()
		}
	}
}

extension OnepPairMatchViewController: MatchMessageObserver {
	func present(from matchHandler: MatchHandler, with matchModel: ChannelModel, complete: CompletionHandler?) {
		self.matchModel = matchModel as! MatchModel
		self.matchHandler = matchHandler
		
		matchHandler.present(self, animated: false, completion: complete)
	}
	
	func dismiss(complete: CompletionHandler? = nil) {
		guard self.isAnimatingDismiss == false else {
			complete?()
			return
		}
		
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
	
	fileprivate func enlargedPublisherView(enlarged: Bool = true, duration: TimeInterval = 0.3, complete: CompletionHandler? = nil) {
		self.isPublisherViewEnlarged = enlarged
		UIView.animate(withDuration: duration, animations: {
			self.remotePairView.alpha = enlarged ? 0 : 1
			self.view.layoutIfNeeded()
		}) { (_) in
			complete?()
		}
	}
	
	func handleReceivedMessage(message: MatchMessage) {
		let type = MessageType.init(type: message.type)
		switch type {
		case .AddTime:
			self.receivedAddTime(message: message)
		case .AddFriend:
			self.receivedAddSnapchat(message: message)
		case .Report:
			self.receivedReport(message: message)
		case .Background:
			self.receivedTurnBackground(message: message)
		default:
			break
		}
	}
}
