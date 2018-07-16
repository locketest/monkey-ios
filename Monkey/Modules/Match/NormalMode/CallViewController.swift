//
//  CallViewController.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class CallViewController: MonkeyViewController {
	// MARK: Interface Elements
	/// The orange view behind the clock label, animated on addMinute
	@IBOutlet weak var clockLabelBackgroundView: UIView!
	@IBOutlet weak var clockLabel: CountingLabel!
	@IBOutlet weak var clockTimeIcon: UILabel!
	
	@IBOutlet weak var commonTreeContainV: UIView!
	@IBOutlet weak var commonTreeEmojiLabel: UILabel!
	@IBOutlet weak var commonTreeLabel: UILabel!
	
	@IBOutlet weak var publisherContainerViewLeftConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerView: LocalPreviewContainer!
	@IBOutlet weak var statusCornerView: UIView!
	
	@IBOutlet weak var filterButton: BigYellowButton!
	@IBOutlet weak var cameraPositionButton: UIButton!
	@IBOutlet weak var policeButtonWidth: NSLayoutConstraint!
	@IBOutlet weak var policeButton: BigYellowButton!
	var reportedLabel: UILabel?
	
	@IBOutlet weak var instagramPopupButton: BigYellowButton!
	
	// add time
	@IBOutlet weak var addMinuteButton: BigYellowButton!
	// add friend
	@IBOutlet weak var snapchatButton: BigYellowButton!
	
	// skip for event mode
	@IBOutlet weak var skipButton: BigYellowButton!
	@IBOutlet weak var skipButtonContainerView: UIView!
	
	// end call for friend
	@IBOutlet weak var endCallButton: BigYellowButton!
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var containerViewTopConstraint: NSLayoutConstraint!
	
	// filter background
	fileprivate weak var filterBackground: UIView?
	// match model
	weak var matchModel: ChannelModel!
	// match matchHandler
	weak var matchHandler: MatchHandler!
	
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
				publisherContainerViewLeftConstraint.constant = 0.0
				publisherContainerViewTopConstraint.constant = 0.0
				
				publisherContainerViewHeightConstraint.constant = self.view.frame.size.height
				publisherContainerViewWidthConstraint.constant = self.view.frame.size.width
			} else {
				publisherContainerViewLeftConstraint.constant = 20.0
				publisherContainerViewTopConstraint.constant = 34.0
				
				publisherContainerViewHeightConstraint.constant = 179.0
				publisherContainerViewWidthConstraint.constant = 103.0
			}
		}
	}
	var isAnimatingDismiss = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureRemotePreview()
		self.configureLocalPreview()
		self.configureReportStatus()
		
		// refresh friend
		let isFriend = self.matchModel.left.friendMatched
		self.refresh(with: isFriend)
	}
	
	func configureReportStatus() {
		if self.matchModel.isVideoCall {
			// disable report
			self.policeButton.isHidden = true
			self.policeButton.isEnabled = false
		}
	}
	
	func setupCommonTree() {
		if let commonTree = self.matchModel.left.commonChannel() {
			self.commonTreeLabel.adjustsFontSizeToFitWidth = true
			self.commonTreeLabel.minimumScaleFactor = 0.5
			self.commonTreeLabel.text = commonTree.title
			self.commonTreeEmojiLabel.text = commonTree.emoji
		}else {
			self.commonTreeContainV.isHidden = true
		}
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
		}
	}
	
	func stopClockTimer() {
		self.ticker?.invalidate()
		self.ticker = nil
	}
	
	func configureLocalPreview() {
		self.statusCornerView.layer.cornerRadius = 6.0
		
		// add local preview
		self.publisherContainerView.addLocalPreview()
		self.publisherContainerView.pixellateable = true
		self.enlargedPublisherView(duration: 0)
		self.setupCommonTree()
		
		self.clockLabelBackgroundView.layer.cornerRadius = 20
		self.clockLabelBackgroundView.layer.masksToBounds = true
		
		self.animator = UIDynamicAnimator(referenceView: self.containerView)
	}
	
	func configureRemotePreview() {
		self.setupCommonTree()
		let remotePreview = self.matchModel.left.renderContainer
		self.view.insertSubview(remotePreview, at: 0)
		remotePreview.frame = self.view.bounds
		remotePreview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		if Environment.isIphoneX {
			self.containerViewTopConstraint.constant = 14.0
			self.containerViewBottomConstraint.constant = 24.0
		}
	}
	
	func refresh(with friendStatus: Bool) {
		if friendStatus {
			// hide skip\addtime\addfriend
			self.snapchatButton.isEnabled = false
			self.snapchatButton.isHidden = true
			
			let linkedInstagram = (self.matchModel.left.instagram_id != nil)
			self.instagramPopupButton.isEnabled = linkedInstagram
			self.instagramPopupButton.isHidden = !linkedInstagram
			
			self.addMinuteButton.isEnabled = false
			self.addMinuteButton.isHidden = true
			
			self.skipButton.isEnabled = false
			self.skipButton.isHidden = true
			
			self.skipButtonContainerView.isUserInteractionEnabled = false
			self.skipButtonContainerView.isHidden = true
			
			// show endcall\switch camera
			self.cameraPositionButton.isEnabled = true
			self.cameraPositionButton.isHidden = false
			self.cameraPositionButton.backgroundColor = UIColor.clear
			self.clockLabelBackgroundView.isHidden = false
			
			self.endCallButton.isEnabled = true
			self.endCallButton.isHidden = false
			
			// disable clock
			self.switchClock(open: false)
		}else {
			self.snapchatButton.isEnabled = true
			self.snapchatButton.isHidden = false
			
			self.instagramPopupButton.isEnabled = false
			self.instagramPopupButton.isHidden = true
			
			self.endCallButton.isEnabled = false
			self.endCallButton.isHidden = true
			
			self.cameraPositionButton.isEnabled = false
			self.cameraPositionButton.isHidden = true
			
			// event mode
			if self.matchModel.match_room_mode == .EventMode {

				self.addMinuteButton.isEnabled = false
				self.addMinuteButton.isHidden = true

				self.skipButtonContainerView.isUserInteractionEnabled = false
				self.skipButtonContainerView.alpha = 0

				self.clockLabelBackgroundView.isHidden = true
				// disable clock
				self.switchClock(open: false)
			}else {
				self.skipButtonContainerView.isHidden = true
				self.skipButton.isEnabled = false
				self.skipButton.isHidden = true

				// 不是好友，也不是 event mode
				self.addMinuteButton.isEnabled = true
				self.addMinuteButton.isHidden = false

				self.switchClock(open: true)
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.enlargedPublisherView(enlarged: false)
		
		// event mode 中不是好友
		if self.matchModel.match_room_mode == .EventMode && self.matchModel.left.friendMatched == false {
			let event_mode_next_show = TimeInterval(RemoteConfigManager.shared.event_mode_next_show)
			UIView.animate(withDuration: event_mode_next_show, animations: {
				self.skipButtonContainerView.alpha = 1.0
			}) {[weak self] (finished) in
				guard let `self` = self else { return }
				guard finished else { return }

				self.skipButtonContainerView.isUserInteractionEnabled = true
			}
		}
	}
	
	@IBAction func filterButtonClick(_ sender: Any) {
		if self.filterBackground == nil {
			self.showFilterCollection()
		}
	}
	
	@IBAction func skipButtonClick(_ sender: UIButton) {
		self.skipButton.isEnabled = false
		self.skipButton.layer.opacity = 0.5
		self.dismiss(complete: nil)
	}
	
	@IBAction func endCall(_ sender: BigYellowButton) {
		self.endCallButton.isEnabled = false
		self.endCallButton.layer.opacity = 0.5
		self.dismiss(complete: nil)
	}
	
	@IBAction func cameraPositionButtonClick(_ sender: Any) {
		HWCameraManager.shared().rotateCameraPosition()
	}
	
	@IBAction func alertInstagramPopupVcFunc(_ sender: BigYellowButton) {
		let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as! InstagramPopupViewController
		instagramVC.userId = String(self.matchModel.left.user_id)
		instagramVC.followMyIGTagBool = false
		self.present(instagramVC, animated: true)
	}
}

extension CallViewController: MatchMessageObserver {
	func present(from matchHandler: MatchHandler, with matchModel: ChannelModel, complete: CompletionHandler?) {
		self.matchModel = matchModel
		self.matchHandler = matchHandler
		
		matchHandler.present(self, animated: false, completion: complete)
	}
	
	func present(from vc: UIViewController? = nil, from matchHandler: MatchHandler, with matchModel: ChannelModel, complete: CompletionHandler?) {
		self.matchModel = matchModel
		self.matchHandler = matchHandler
		
		let presentedVC = vc ?? matchHandler
		presentedVC.present(self, animated: false, completion: complete)
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

extension CallViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		
		var touchView: UIView? = touch.view
		while touchView != nil {
			if (touchView is FilterCollectionView) {
				return false
			}
			touchView = touchView?.superview
		}
		
		return true
	}
}

extension CallViewController {
	fileprivate func showFilterCollection() {
		let backViewY: CGFloat = 100 - self.view.frame.size.height
		let backView = UIView.init(frame: CGRect.init(x: 0, y: backViewY, width: self.view.frame.size.width, height: self.view.frame.size.height))
		backView.backgroundColor = UIColor.init(white: 0, alpha: 0)
		backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.view.addSubview(backView)
		
		let iPhoneBottomEdge: CGFloat = Environment.isIphoneX ? 38 : 0
		let filterHeight: CGFloat = 107
		let filterWidth: CGFloat = backView.frame.size.width - 10
		let filterY: CGFloat = backView.frame.size.height - 100 - filterHeight - iPhoneBottomEdge
		let filterCollection = FilterCollectionView.init(frame: CGRect.init(x: 5, y: filterY, width: filterWidth, height: filterHeight))
		filterCollection.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		backView.addSubview(filterCollection)
		self.filterBackground = backView
		
		let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(closeFilterCollection))
		backView.addGestureRecognizer(tapGesture)
		tapGesture.delegate = self
		
		let swipeUp = UISwipeGestureRecognizer.init(target: self, action: #selector(closeFilterCollection))
		swipeUp.direction = .up
		swipeUp.delegate = self;
		backView.addGestureRecognizer(swipeUp)
		
		UIView.animate(withDuration: 0.2, animations: {
			backView.frame = self.view.bounds
		}, completion: nil)
	}
	
	func closeFilterCollection() {
		if let filterBackground = self.filterBackground {
			var frame = filterBackground.frame
			frame.origin.y = 100 - self.view.frame.size.height
			UIView.animate(withDuration: 0.2, animations: {
				filterBackground.frame = frame
			}, completion: { (_) in
				filterBackground.removeFromSuperview()
			})
		}
	}
}

