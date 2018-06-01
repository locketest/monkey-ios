//
//  CallViewController.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import AudioToolbox
import RealmSwift
import DeviceKit

protocol CallViewControllerDelegate: class {
    func stopFindingChats(andDisconnect:Bool, forReason:String)
    func startFindingChats(forReason:String)
}

class CallViewController: MonkeyViewController, TruthOrDareDelegate, ChatSessionCallDelegate, MatchViewControllerProtocol {
    var commonTree: RealmChannel?

    // MARK: Interface Elements
    @IBOutlet var addTimeHorizontalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var publisherContainerViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var publisherContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var publisherContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var publisherContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addMinuteButton: BigYellowButton!
    @IBOutlet weak var clockLabel: CountingLabel!
    @IBOutlet weak var clockTimeIcon: UILabel!
    @IBOutlet weak var policeButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var policeButton: BigYellowButton!
    @IBOutlet weak var snapchatButton: BigYellowButton!
	@IBOutlet weak var filterButton: BigYellowButton!
	@IBOutlet weak var skipButton: BigYellowButton!
	@IBOutlet weak var skipButtonContainerView: UIView!
	@IBOutlet var endCallButton: BigYellowButton!
    @IBOutlet weak var instagramPopupButton: BigYellowButton!
    @IBOutlet weak var statusCornerView: UIView!
    @IBOutlet weak var publisherContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var commonTreeContainV: UIView!
    @IBOutlet weak var commonTreeEmojiLabel: UILabel!
    @IBOutlet weak var commonTreeLabel: UILabel!
    
    @IBOutlet weak var clockTop: NSLayoutConstraint!
    @IBOutlet weak var clockViewBottom: NSLayoutConstraint!
    
	weak var filterBackground: UIView?
    /// The orange view behind the clock label, animated on addMinute
    @IBOutlet var clockLabelBackgroundView: UIView!

    @IBOutlet weak var cameraPositionButton: UIButton!
    var currentMatchPastTime:TimeInterval = 0
    
	var isLinkInstagramBool: Bool {
		return chatSession?.videoCall?.matchedFriendship?.user?.instagram_account != nil
	}
    
    var clocks = "🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕜🕝🕞🕟🕠🕡🕢🕣🕤🕥🕦🕧"
    let truthOrDareView = TruthOrDareView.instanceFromNib()
    var soundPlayer = SoundPlayer.shared
    weak var callDelegate:CallViewControllerDelegate?
    let throttleFunction = throttle(delay: 0.25, queue: DispatchQueue.main) {
		TapticFeedback.impact(style: .heavy)
    }

    var chatSession: ChatSession? {
        didSet {
            guard self.chatSession?.remoteView != nil else {
                guard let oldSubView = oldValue?.remoteView else {
                    return
                }
                oldSubView.removeFromSuperview()
                return
            }

            chatSession?.add(messageHandler: self.effectsCoordinator)
            chatSession?.toggleFrontCamera(front: true)
            if chatSession?.isDialedCall == true || chatSession?.matchMode == .EventMode {
                self.clockTime = 0
            }
        }
    }

    var clockTime:Int = 15000
    var effectsCoordinator = EffectsCoordinator()
    var ticker:Timer?
    var isAnimatingMinuteAdd = false
    var animator: UIDynamicAnimator!

    /**
     When true, sets constraints to make the publisher camera view fill the screen.

     When false, sets constraints to pin to top right corner for a call.
     */
    var isPublisherViewEnlarged = true { // true when skip button,
        didSet {
            updatePublisherViewConstraints()
        }
    }

    func togglePublisherEffects() {
        if HWCameraManager.shared().pixellated == false {
			HWCameraManager.shared().addPixellate()
        } else {
			HWCameraManager.shared().removePixellate()
        }
    }

    func updatePublisherViewConstraints() {
        if isPublisherViewEnlarged {
            statusCornerView.layer.cornerRadius = 0
            publisherContainerViewLeftConstraint.constant = 0
            publisherContainerViewTopConstraint.constant = -22

            publisherContainerViewHeightConstraint.constant = self.topLayoutGuide.length + self.containerView.frame.size.height + 43 + 22
            publisherContainerViewWidthConstraint.constant = self.containerView.frame.size.width
        } else {
            statusCornerView.layer.cornerRadius = 6
            publisherContainerViewLeftConstraint.constant = 20
            publisherContainerViewTopConstraint.constant = 34

            publisherContainerViewHeightConstraint.constant = 179
            publisherContainerViewWidthConstraint.constant = 103
        }
        self.view.setNeedsLayout()
    }
    
    var hideStatusBarForScreenshot = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if hideStatusBarForScreenshot {
            return .none
        }
        return .slide
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("sh-1226- \(self) callVC init...")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("sh-1226- \(self) callVC init...")
        
       // self.cameraPositionButton.hidde
    }

    deinit {
        print("sh-1226- \(self) callVC deinit...")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]

        // Step 1: As the view is loaded initialize a new instance of OTSession
        statusCornerView.layer.cornerRadius = 6
        Socket.shared.isEnabled = true
        self.clockLabel.font = UIFont.monospacedDigitSystemFont(ofSize: self.clockLabel.font.pointSize, weight: UIFontWeightMedium)
        animator = UIDynamicAnimator(referenceView: self.containerView)
        self.ticker = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil,   repeats: true)
//        // make sure timer always runs correctly
        RunLoop.main.add(self.ticker!, forMode: .commonModes)
        self.endCallButton.isHidden = true
		self.skipButton.isHidden = true
		self.skipButtonContainerView.isHidden = true
        self.handleInstagramPopupBtnHiddenFunc(isHidden: self.endCallButton.isHidden)
		
        self.clockLabel.delegate = self
		self.clockLabelBackgroundView.layer.cornerRadius = 20
		self.clockLabelBackgroundView.layer.masksToBounds = true

        if self.chatSession?.isDialedCall == true {
            self.endCallButton.isEnabled = true
            self.snapchatButton.isEnabled = false
            self.addMinuteButton.isEnabled = false
			self.skipButton.isEnabled = false
            self.addMinuteButton.isHidden = true
            self.snapchatButton.isHidden = true
            self.endCallButton.isHidden = false
            self.handleInstagramPopupBtnHiddenFunc(isHidden: self.endCallButton.isHidden)
        }
		
		if self.chatSession?.matchMode == .EventMode {
			self.snapchatButton.isEnabled = true
			self.addMinuteButton.isEnabled = false
			self.endCallButton.isEnabled = false
			self.snapchatButton.isHidden = false
			self.addMinuteButton.isHidden = true
			self.skipButton.isHidden = false
			self.skipButton.isEnabled = true
			self.skipButtonContainerView.isUserInteractionEnabled = false
			self.skipButtonContainerView.alpha = 0
			self.skipButtonContainerView.isHidden = false
		}
		
        self.statusCornerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePublisherEffects)))

        if let subView = self.chatSession?.remoteView {
            self.containerView.insertSubview(subView, at: 0)
            subView.frame = UIScreen.main.bounds
        }

        statusCornerView.layer.cornerRadius = 0
        publisherContainerViewLeftConstraint.constant = 0
        publisherContainerViewTopConstraint.constant = -22

        publisherContainerViewHeightConstraint.constant = self.topLayoutGuide.length + self.containerView.frame.size.height + 43 + 22
        publisherContainerViewWidthConstraint.constant = self.containerView.frame.size.width
		
		self.cameraPositionButton.isHidden = true
		self.cameraPositionButton.backgroundColor = UIColor.clear
		
        if chatSession?.friendMatched == true {
			self.cameraPositionButton.isHidden = false
			self.clockLabel.isHidden = true
			self.clockTimeIcon.isHidden = true
        }
		
		if chatSession?.matchMode == .EventMode {
			self.clockLabel.isHidden = true
			self.clockTimeIcon.isHidden = true
			self.clockLabelBackgroundView.isHidden = true
		}
    }
    
    func handleInstagramPopupBtnHiddenFunc(isHidden:Bool) {
        self.instagramPopupButton.isHidden = self.isLinkInstagramBool ? isHidden : true
    }

    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.isPublisherViewEnlarged = false
            self.view.layoutIfNeeded()
            self.setupCommonTree()
        }
		
		if self.chatSession?.matchMode == .EventMode {
			UIView.animate(withDuration: TimeInterval(RemoteConfigManager.shared.event_mode_next_show), animations: {
				self.skipButtonContainerView.alpha = 1
			}) {[weak self] (finished) in
				guard let `self` = self else { return }
				if finished == true {
					self.skipButtonContainerView.isUserInteractionEnabled = true
				}
			}
		}
    }

    override func viewWillAppear(_ animated: Bool) {
		let localPreviewView = HWCameraManager.shared().localPreviewView
        self.publisherContainerView.addSubview(localPreviewView)
		
        let viewsDict = ["view": HWCameraManager.shared().localPreviewView]
        self.publisherContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
        self.publisherContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))


        let path = UIBezierPath(roundedRect:clockLabelBackgroundView.bounds, byRoundingCorners:[.bottomRight, .bottomLeft], cornerRadii: CGSize(width: 20, height:  20))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        clockLabelBackgroundView.layer.mask = maskLayer
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.ticker?.invalidate()
        self.ticker = nil
    }

    func requestPresentation(of alertController: UIAlertController, from view: UIView) {
        self.present(alertController, animated: true, completion: nil)
    }
	
	func showFilterCollection() {
		let backView = UIView.init(frame: CGRect.init(x: 0, y: 100 - self.view.frame.size.height, width: self.view.frame.size.width, height: self.view.frame.size.height))
		backView.backgroundColor = UIColor.init(white: 0, alpha: 0)
		backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.view.addSubview(backView)
		let iPhoneBottomEdge: CGFloat = (Device() == Device.iPhoneX) ? 38 : 0
		
		let filterCollection = FilterCollectionView.init(frame: CGRect.init(x: 5, y: backView.frame.size.height - 100 - 107 - iPhoneBottomEdge, width: backView.frame.size.width - 10, height: 107))
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
    
	@IBAction func filterButtonClick(_ sender: Any) {
		if self.filterBackground == nil {
			self.showFilterCollection()
		}
	}
	
	@IBAction func skipButtonClick(_ sender: UIButton) {
		self.skipButton.isEnabled = false
		self.skipButton.layer.opacity = 0.5
		self.chatSession?.disconnect(.consumed)
	}
	@IBAction func cameraPositionButtonClick(_ sender: Any) {
        self.chatSession?.toggleCameraPosition()
    }
    
    func setupCommonTree(){
        if let curcommonTree = self.commonTree {
            self.commonTreeLabel.adjustsFontSizeToFitWidth = true
            self.commonTreeLabel.minimumScaleFactor = 0.5
            self.commonTreeEmojiLabel.text = curcommonTree.emoji
            self.commonTreeLabel.text = curcommonTree.title

        }else {
            self.commonTreeContainV.isHidden = true
        }
		
		if (self.chatSession?.friendMatched == true || self.chatSession?.matchMode == .EventMode || self.chatSession?.isDialedCall == true) {
			self.clockLabel.isHidden = true
			self.clockTimeIcon.isHidden = true
		}else {
			self.clockLabel.isHidden = false
			self.clockTimeIcon.isHidden = false
		}
    }
	
    // MARK: Snapchat Button
    @IBAction func addSnapchat(_ sender: BigYellowButton) {
		// add friend
		sender.isEnabled = false
		sender.layer.opacity = 0.5
		
		if Achievements.shared.addFirstSnapchat == false {
			let addFirstSnapchatAlert = UIAlertController(title: nil, message: "To successfully add friends, both users have to tap the button", preferredStyle: .alert)
			addFirstSnapchatAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: {[weak self] (UIAlertAction) in
				Achievements.shared.addFirstSnapchat = true
				guard let `self` = self else { return }
				if let chatSession = self.chatSession, chatSession.status == .connected {
					self.chatSession?.sendSnapchat(username: APIController.shared.currentUser!.snapchat_username!)
				}
			}))
			let mainVC = self.presentingViewController as? MainViewController
			mainVC?.showAlert(alert: addFirstSnapchatAlert)
		}else {
			self.chatSession?.sendSnapchat(username: APIController.shared.currentUser!.snapchat_username!)
		}
    }
	
    @IBAction func alertInstagramPopupVcFunc(_ sender: BigYellowButton) {
        
        let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as! InstagramPopupViewController
        
        instagramVC.userId = self.chatSession?.videoCall?.user?.user_id ?? self.chatSession?.videoCall?.initiator?.user_id
        instagramVC.followMyIGTagBool = false
        
        self.present(instagramVC, animated: true)
    }
    
    @IBAction func endCall(_ sender: BigYellowButton) {
        self.endCallButton.isEnabled = false
        self.endCallButton.layer.opacity = 0.5
        self.chatSession?.disconnect(.consumed)
    }
    var winEmojis = "🎉👻🌟😀💎♥️🎊🎁🐬🙉🔥"

    var reportedLabel: UILabel?

	func received(textMessage: TextMessage, in chatSession: ChatSession) {

	}
    
    func opponentDidTurnToBackground(in chatSession: ChatSession) {
        self.autoScreenShotUpload(source: .opponent_background)
    }

    internal func friendMatched(in chatSession: ChatSession?) {
		// friend added
		Achievements.shared.snapchatMatches += 1
		if let currentChatSession = chatSession {
			soundPlayer.play(sound: .win)
			animator.removeAllBehaviors()
			let gravityBehaviour = UIGravityBehavior()
			gravityBehaviour.gravityDirection = CGVector(dx: 0.0, dy: 1.6)
			animator.addBehavior(gravityBehaviour)
			var emojiLabels = Array<UILabel>()
			TapticFeedback.impact(style: .medium)

			for _ in 1...130 {
				let emojiLabel = UILabel()
				emojiLabel.text = String(winEmojis[clocks.index(winEmojis.startIndex, offsetBy: (Int(arc4random_uniform(UInt32(winEmojis.count)))))])
				emojiLabel.font = UIFont.systemFont(ofSize: 39.0)
				emojiLabel.frame = CGRect(x: self.snapchatButton.frame.origin.x + 30, y: self.snapchatButton.frame.origin.y, width: 50, height: 50)
				self.containerView.insertSubview(emojiLabel, belowSubview: self.snapchatButton)

				gravityBehaviour.addItem(emojiLabel)

				// This behaviour is included so that the alert view tilts when it falls, otherwise it will go straight down
				let itemBehaviour: UIDynamicItemBehavior = UIDynamicItemBehavior(items: [emojiLabel])
				itemBehaviour.addAngularVelocity(-(CGFloat.pi / 2), for: emojiLabel)
				animator.addBehavior(itemBehaviour)

				let pushBehavior: UIPushBehavior = UIPushBehavior(items: [emojiLabel], mode: .instantaneous)
				pushBehavior.pushDirection = CGVector(dx: self.randomBetweenNumbers(firstNum: -200, secondNum: 100), dy: -self.randomBetweenNumbers(firstNum: 0, secondNum: self.containerView.frame.size.height))
				pushBehavior.magnitude = self.randomBetweenNumbers(firstNum: 1.0, secondNum: 4.0)
				animator.addBehavior(pushBehavior)
				emojiLabels.append(emojiLabel)
			}

			// Animate out the overlay, remove the alert view from its superview and set it to nil
			// If you don't set it to nil, it keeps falling off the screen and when Show Alert button is
			// tapped again, it will snap into view from below. It won't have the location settings we defined in createAlert()
			// And the more it 'falls' off the screen, the longer it takes to come back into view, so when the Show Alert button
			// is tapped again after a considerable time passes, the app seems unresponsive for a bit of time as the alert view
			// comes back up to the screen
			let when = DispatchTime.now() + (Double(4.0))
			DispatchQueue.main.asyncAfter(deadline: when) {
				for emojiLabel in emojiLabels {
					emojiLabel.removeFromSuperview()
				}
			}
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                if currentChatSession.status == .connected {
					self.endCallButton.isEnabled = true
					self.snapchatButton.isEnabled = false
					self.addMinuteButton.isEnabled = false
					self.addMinuteButton.isHidden = true
					self.snapchatButton.isHidden = true
					self.endCallButton.isHidden = false
					self.skipButton.isHidden = true
					self.skipButton.isEnabled = false
                    self.handleInstagramPopupBtnHiddenFunc(isHidden: self.endCallButton.isHidden)
				}
			}
		}else {
			self.endCallButton.isEnabled = true
			self.snapchatButton.isEnabled = false
			self.addMinuteButton.isEnabled = false
			self.addMinuteButton.isHidden = true
			self.snapchatButton.isHidden = true
			self.endCallButton.isHidden = false
			self.skipButton.isHidden = true
			self.skipButton.isEnabled = false
            self.handleInstagramPopupBtnHiddenFunc(isHidden: self.endCallButton.isHidden)
		}
		self.clockLabelBackgroundView.isHidden = false
        self.cameraPositionButton.isHidden = false
		self.clockTimeIcon.isHidden = true
        self.clockLabel.isHidden = true
		self.clockTime = -1// (6 * 1000)
		self.disableAddMinute()
    }

    // MARK: - Helpers
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
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

