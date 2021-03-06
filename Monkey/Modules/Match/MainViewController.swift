//  MainViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/14/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

//| $$      /$$  /$$$$$$  /$$   /$$ /$$   /$$ /$$$$$$$$ /$$     /$$
//| $$$    /$$$ /$$__  $$| $$$ | $$| $$  /$$/| $$_____/|  $$   /$$/
//| $$$$  /$$$$| $$  \ $$| $$$$| $$| $$ /$$/ | $$       \  $$ /$$/
//| $$ $$/$$ $$| $$  | $$| $$ $$ $$| $$$$$/  | $$$$$     \  $$$$/
//| $$  $$$| $$| $$  | $$| $$  $$$$| $$  $$  | $$__/      \  $$/
//| $$\  $ | $$| $$  | $$| $$\  $$$| $$\  $$ | $$          | $$
//| $$ \/  | $$|  $$$$$$/| $$ \  $$| $$ \  $$| $$$$$$$$    | $$
//|__/     |__/ \______/ |__/  \__/|__/  \__/|________/    |__/

import UIKit
import Alamofire
import RealmSwift
import ObjectMapper
import UserNotifications
import Hero

/**
*	user_id: UserAvatarTag
*/
public let AccessUserAvatarArrayTag = "AccessUserAvatarArray"
/**
*	is_tap_setting: bool
*/
typealias UserAvatarTag = [String: Bool]

typealias MatchContainer = MatchObserver & MonkeyViewController & TransationDelegate

@objc protocol TransationDelegate: NSObjectProtocol {
	@objc optional func disappear(animated flag: Bool, complete: (() -> Void)?)
	@objc optional func appear(animated flag: Bool, complete: (() -> Void)?)
	
	func didMoveTo(screen: UIViewController)
	func didShowFrom(screen: UIViewController)
}

@objc protocol MatchObserver: NSObjectProtocol {
	@objc optional func appMovedToBackground()
	
	@objc optional func appMovedToForeground()
	
	@objc optional func appWillTerminate()
	
	@objc optional func didReceiveOnepMatch(match: MatchModel)
	
	@objc optional func didReceiveTwopMatch(match: MatchModel)
	
	func presentVideoCall(after completion: @escaping () -> Void)
	
	@objc optional func didDismissVideoCall(call: VideoCallModel)
	
	func didReceiveMessage(type: String, in chat: String)
	
	func matchTypeChanged(newType: MatchType)
}

class MainViewController: SwipeableViewController {
	
	fileprivate var onepMatchDiscovery: OnepMatchController?
	fileprivate var twopMatchDiscovery: TwopMatchController?
	fileprivate var topMatchDiscovery: MatchContainer!
	fileprivate var matchType: MatchType? {
		didSet(oldValue) {
			if oldValue == nil {
				if self.matchType == .Onep {
					if self.twopMatchDiscovery == nil {
						self.onepMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "oneP") as! OnepMatchController)
					}
					self.topMatchDiscovery = self.onepMatchDiscovery
				}else if self.matchType == .Twop {
					if self.twopMatchDiscovery == nil {
						self.twopMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "twoP") as! TwopMatchController)
					}
					self.topMatchDiscovery = self.twopMatchDiscovery
				}
			}
			
			if let newType = self.matchType {
				self.matchTypeChanged(newType: newType)
			}
		}
	}
	
	@IBOutlet weak var colorGradientView: UIView!
	@IBOutlet weak var localPreview: LocalPreviewContainer!
	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var contentTopMargin: NSLayoutConstraint!
	@IBOutlet weak var contentBottomMagrin: NSLayoutConstraint!
	override var transitionContent: UIView {
		if self.panningTowardsSide == .bottom || (self.panningTowardsSide == nil && self.presentedViewController == self.swipableViewControllerPresentFromTop) {
			return self.colorGradientView
		}else {
			return self.contentView
		}
	}
	
	@IBOutlet weak var pageViewIndicator: UIPageControl!
	@IBOutlet weak var settingsButton: BigYellowButton!
	@IBOutlet weak var channelsButton: BigYellowButton!
	@IBOutlet weak var friendsButton: BigYellowButton!
	@IBOutlet weak var filtersButton: BigYellowButton!
	
	@IBOutlet weak var matchModeSwitch: BigYellowButton! // 2p按钮
	@IBOutlet weak var twoPTipLabel: UILabel! // 红点数量提示
	var tipNumber = 0
	
	@IBOutlet weak var bananaView: BigYellowButton!
	@IBOutlet weak var bananaCountLabel: UILabel!
	
	@IBOutlet weak var channelUpdateRemindV: UIView!
	
	var bananas = Bananas()
	fileprivate var isMatchStart: Bool = false
	
	// MARK: UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// UI Apperance
		self.configureApperance()
		// left\right\top\bottom
		self.configureSwipableVC()
		
		// add observer
		self.addObserver()
		
		// check camera and micphone permission
		self.checkCamAccess()
		// check notification permission
		self.checkNotifiPermission()
		// update location
		self.startUpdatingLocation()
		
		// load channels
		self.loadChannels()
		
		// load bananas
		self.loadBananas()
		
		// red point
		self.handleRedPointStatus()
	}
	
	private func configureApperance() {
		self.view.backgroundColor = Colors.purple
		self.settingsButton.hero.modifiers = [.timingFunction(.linear)]
		
		self.filtersButton.layer.cornerRadius = 20
		self.filtersButton.layer.masksToBounds = true
		
		self.pageViewIndicator.numberOfPages = 3
		self.pageViewIndicator.currentPage = 1
		self.pageViewIndicator.isUserInteractionEnabled = false
		
		if Environment.isIphoneX {
			self.contentTopMargin.constant = 34.0
			self.contentBottomMagrin.constant = 24.0
		}else {
			self.contentTopMargin.constant = 20.0
			self.contentBottomMagrin.constant = 0
		}
		
		// check user avatar
		self.handleAccessUserAvatar()
		// refresh match type
		self.initialMatchTypeStatus()
	}
	
	private func initialMatchTypeStatus() {
		var matchType = MatchType.Onep
		if let currentUser = UserManager.shared.currentUser {
			// if user enable twop
			if currentUser.cached_enable_two_p {
				// if user has select twop
				if currentUser.cached_match_type == MatchType.Twop.rawValue {
					matchType = MatchType.Twop
				}
			}
		}
		
		self.matchType = matchType
	}
	
	private func configureSwipableVC() {
		// initial child view controller
		self.swipableViewControllerPresentFromRight = (UIStoryboard(name: "Channels", bundle: .main).instantiateInitialViewController() as! SwipeableViewController)
		self.swipableViewControllerPresentFromRight?.modalPresentationStyle = .overFullScreen
		self.swipableViewControllerPresentFromLeft = (UIStoryboard(name: "Chat", bundle: .main).instantiateInitialViewController() as! SwipeableViewController)
		self.swipableViewControllerPresentFromLeft?.modalPresentationStyle = .overFullScreen
		self.swipableViewControllerPresentFromBottom = (UIStoryboard(name: "Settings", bundle: .main).instantiateInitialViewController() as! SwipeableViewController)
		self.swipableViewControllerPresentFromBottom?.modalPresentationStyle = .overFullScreen
		self.swipableViewControllerPresentFromTop = FilterViewController.init()
		self.swipableViewControllerPresentFromTop?.modalPresentationStyle = .overFullScreen
	}
	
	func beginMatchProcess() {
		self.isMatchStart = true
		self.refreshIcon()
	}
	
	func endMatchProcess() {
		self.isMatchStart = false
		self.refreshIcon()
	}
	
	func refreshIcon() {
		if self.isMatchStart {
			self.isSwipingEnabled = false
			
			self.bananaView.isHidden = true
			self.pageViewIndicator.isHidden = true
			
			self.filtersButton.isHidden = true
			self.friendsButton.isHidden = true
			self.settingsButton.isHidden = true
			self.channelsButton.isHidden = true
		}else {
			self.bananaView.isHidden = false
			self.pageViewIndicator.isHidden = false
			
			if self.matchType == .Onep {
				self.isSwipingEnabled = true
				
				self.filtersButton.isHidden = false
				self.friendsButton.isHidden = false
				self.settingsButton.isHidden = false
				self.channelsButton.isHidden = false
			}else {
				self.isSwipingEnabled = false
				
				self.filtersButton.isHidden = true
				self.friendsButton.isHidden = true
				self.settingsButton.isHidden = true
				self.channelsButton.isHidden = true
			}
		}
		
		self.refreshModeSwitch()
	}
	
	private func refreshModeSwitch() {
		guard let currentUser = UserManager.shared.currentUser, currentUser.cached_enable_two_p == true, self.isMatchStart == false else {
			self.twoPTipLabel.isHidden = true
			self.matchModeSwitch.isHidden = true
			return
		}
		
		self.matchModeSwitch.isHidden = false
		if self.matchType == .Onep {
			self.matchModeSwitch.backgroundColor = UIColor.init(red: 1, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1)
			if self.tipNumber > 0 {
				self.twoPTipLabel.isHidden = false
				self.twoPTipLabel.text = String(self.tipNumber)
			}else {
				self.twoPTipLabel.isHidden = true
			}
		}else {
			self.matchModeSwitch.backgroundColor = UIColor.white
			self.twoPTipLabel.isHidden = true
		}
	}
	
	fileprivate func switchTo(mode: MatchType, completion: (() -> Void)? = nil) {
		if mode == self.matchType {
			return
		}
		
		if mode == .Onep {
			self.switchToOnep(completion: completion)
		}else {
			self.switchToTwop(completion: completion)
		}
		self.matchType = mode
		
		let realm = try? Realm()
		do {
			try realm?.write {
				UserManager.shared.currentUser?.cached_match_type = mode.rawValue
			}
		} catch(let error) {
			print("Error: ", error)
		}
		
		let attributes: [RealmUser.Attribute] = [
			.match_type(mode.rawValue)
			]
		
		UserManager.shared.currentUser?.update(attributes: attributes, completion: { (_) in
			
		})
	}
	
	private func switchToOnep(completion: (() -> Void)? = nil) {
		if self.onepMatchDiscovery == nil {
			self.onepMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "oneP") as! OnepMatchController)
		}
		self.exchange(topMatchVC: self.onepMatchDiscovery!, completion: completion)
	}
	
	private func switchToTwop(completion: (() -> Void)? = nil) {
		if self.twopMatchDiscovery == nil {
			self.twopMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "twoP") as! TwopMatchController)
		}
		self.exchange(topMatchVC: self.twopMatchDiscovery!, completion: completion)
	}
	
	private func exchange(topMatchVC: MatchContainer, completion: (() -> Void)? = nil) {
		var oldTopVC: MatchContainer? = nil
		if self.matchType == .Onep {
			oldTopVC = self.onepMatchDiscovery
		}else if self.matchType == .Twop {
			oldTopVC = self.twopMatchDiscovery
		}
		self.hide(old: oldTopVC)
		
		self.show(new: topMatchVC, from: oldTopVC, completion: completion)
		self.topMatchDiscovery = topMatchVC
	}
	
	private func hide(old topMatchVC: MatchContainer? = nil, completion: (() -> Void)? = nil) {
		guard let topMatchVC = topMatchVC else {
			completion?()
			return
		}
		topMatchVC.willMove(toParentViewController: nil)
		topMatchVC.beginAppearanceTransition(false, animated: true)
		
		let hideComplete = {
			topMatchVC.view.removeFromSuperview()
			topMatchVC.endAppearanceTransition()
			topMatchVC.removeFromParentViewController()
			completion?()
		}
		if topMatchVC.responds(to: #selector(MatchContainer.disappear(animated:complete:))) {
			topMatchVC.disappear!(animated: true, complete: hideComplete)
		}else {
			hideComplete()
		}
	}
	
	private func show(new topMatchVC: MatchContainer, from: MatchContainer? = nil, completion: (() -> Void)? = nil) {
		// disable first
		self.matchModeSwitch.isUserInteractionEnabled = false
		
		self.addChildViewController(topMatchVC)
		if from == nil {
			topMatchVC.beginAppearanceTransition(true, animated: true)
		}
		self.contentView.insertSubview(topMatchVC.view, at: 0)
		topMatchVC.view.frame = self.contentView.bounds
		topMatchVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		let showComplete = {
//			topMatchVC.endAppearanceTransition()
			topMatchVC.didMove(toParentViewController: self)
			completion?()
			// enable
			self.matchModeSwitch.isUserInteractionEnabled = true
		}
		if topMatchVC.responds(to: #selector(MatchContainer.appear(animated:complete:))) {
			topMatchVC.appear!(animated: true, complete: showComplete)
		}else {
			showComplete()
		}
	}
	
	fileprivate var matchViewController: MatchMessageObserver?
	fileprivate var videoCall: VideoCallModel?
	fileprivate var videoCallManager: VideoCallManager = VideoCallManager.default
	@IBAction func presentVideoMode(_ sender: Any) {
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: "OnepPair")
		self.present(matchViewController!, animated: false, completion: nil)
	}
	
	@IBAction func presentTextMode(_ sender: Any) {
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: "PairMatch")
		self.present(matchViewController!, animated: false, completion: nil)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// reset local color Gradient
		UIView.animate(withDuration: 0.3) {
			self.contentView.alpha = 0
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// show current match view controller
		self.showCurrentDiscovery()
		
		// check first name
		self.checkEmptyName()
		
		// if should show banana tip
		self.notifyBananaTip()
		
		// should present banana
		self.refreshBananas()
		
		// add local preview
		self.localPreview.addLocalPreview()
		
		if self.matchType == .Onep {
			self.isSwipingEnabled = true
		}else {
			self.isSwipingEnabled = false
		}
		
		UIView.animate(withDuration: 0.3) {
			self.contentView.alpha = 1.0
		}
		
		// mainview controller 已经显示
		NotificationCenter.default.post(name: .MonkeyMatchDidReady, object: nil)
	}
	
	private func showCurrentDiscovery() {
		guard self.topMatchDiscovery.parent == nil else { return }
		
		self.show(new: self.topMatchDiscovery)
	}
	
	fileprivate func refreshBananas() {
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = .decimal
		let bananaCount = UserManager.shared.currentUser?.bananas ?? 0
		let formattedNumber = numberFormatter.string(from: NSNumber(value:bananaCount))
		self.bananaCountLabel.text = formattedNumber
	}
	
	private func loadChannels() {
		RealmChannel.fetchAll { (result: JSONAPIResult<[RealmChannel]>, hadUpdate: Bool) in
			switch result {
			case .success(_):
				if hadUpdate {
					self.channelUpdateRemindV.isHidden = false
				}
				break
			case .error(let error):
				error.log()
			}
		}
	}
	
	private func handleAccessUserAvatar() {
		if APIController.shared.currentUser?.profile_photo_url == nil, let user_id = APIController.shared.currentUser?.user_id {
			var userAvatarTagInfo = UserDefaults.standard.dictionary(forKey: AccessUserAvatarArrayTag) as? [String: UserAvatarTag] ?? [String: UserAvatarTag]()
			var is_tap_setting = false
			if let myAvatarTag = userAvatarTagInfo[user_id] {
				is_tap_setting = myAvatarTag["is_tap_setting"] ?? false
			}else {
				let myAvatarTag = [
					"is_tap_setting": false,
					]
				userAvatarTagInfo[user_id] = myAvatarTag
				UserDefaults.standard.setValue(userAvatarTagInfo, forKey: AccessUserAvatarArrayTag)
			}
			self.handleAcceptButtonStateFunc(state: is_tap_setting == false)
		}
	}
	
	private func handleAcceptButtonStateFunc(state: Bool) {
		self.settingsButton.setImage(UIImage(named: state ? "ArrowButtonSel" : "ArrowButton"), for: .normal)
	}
	
	private func handleRedPointStatus() {
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/", method: .get, options: [
			.header("Authorization", UserManager.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(let error):
					print("*** error : = \(error.message)")
				case .success(let jsonAPIDocument):
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						
						var models : [FriendsRequestModel] = []
						
						array.forEach({ (dict) in
							
							let userId = APIController.shared.currentUser!.user_id
							
							let friendsRequestModel = FriendsRequestModel.friendsRequestModel(dict: dict)
							
							// 被邀请人为自己，并且未操作
							if userId == friendsRequestModel.inviteeIdInt?.description && TwopChatRequestsStatusEnum.unhandle.rawValue == friendsRequestModel.statusInt {
								models.append(friendsRequestModel)
							}
						})
						self.tipNumber = models.count
						self.refreshIcon()
					}
				}
		}
	}
	
	// show channels list
	@IBAction func channelsButtonTapped(_ sender: Any) {
		self.present(self.swipableViewControllerPresentFromRight!, animated: true, completion: nil)
	}
	
	@IBAction func friendsButtonTapped(_ sender: Any) {
		self.present(self.swipableViewControllerPresentFromLeft!, animated: true, completion: nil)
	}
	
	@IBAction func filtersButtonTapped(_ sender: Any) {
		AnalyticsCenter.log(event: .videoFilterClick)
		self.present(self.swipableViewControllerPresentFromTop!, animated: true, completion: nil)
	}
	
	@IBAction func settingsButtonTapped(_ sender: Any) {
		self.present(self.swipableViewControllerPresentFromBottom!, animated: true, completion: nil)
	}
	
	override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
		if viewControllerToPresent == self.swipableViewControllerPresentFromRight {
			self.channelUpdateRemindV.isHidden = true
		}else if viewControllerToPresent == self.swipableViewControllerPresentFromLeft {
			self.friendsButton.imageView?.image = #imageLiteral(resourceName: "FriendsButton")
		}else if viewControllerToPresent == self.swipableViewControllerPresentFromBottom {
			if let user_id = UserManager.shared.currentUser?.user_id {
				var userAvatarTagInfo = UserDefaults.standard.dictionary(forKey: AccessUserAvatarArrayTag) as? [String: UserAvatarTag] ?? [String: UserAvatarTag]()
				var myAvatarTag = userAvatarTagInfo[user_id] ?? UserAvatarTag()
				myAvatarTag["is_tap_setting"] = true
				userAvatarTagInfo[user_id] = myAvatarTag
				UserDefaults.standard.setValue(userAvatarTagInfo, forKey: AccessUserAvatarArrayTag)
				self.handleAcceptButtonStateFunc(state: false)
			}
		}
		
		super.present(viewControllerToPresent, animated: flag, completion: completion)
	}
	
	@IBAction func matchModeSwitchClick(_ sender: BigYellowButton) {
		let newMatchType = self.matchType!.reverse()
		self.switchTo(mode: newMatchType)
	}
	
	@IBAction func bananaButtonTapped(_ sender: Any) {
		self.showBananaDescription()
	}
	
	deinit {
		self.removeObserver()
	}
}

// application status notify
extension MainViewController: MatchObserver {
	fileprivate func addObserver() {
		UserManager.shared.addMessageObserver(observer: self)
		MessageCenter.shared.addMessageObserver(observer: self)
		NotificationManager.shared.actionDelegate = self
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appMovedToBackground),
			name: Notification.Name.UIApplicationDidEnterBackground,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appMovedToForeground),
			name: Notification.Name.UIApplicationWillEnterForeground,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appWillTerminate),
			name: Notification.Name.UIApplicationWillTerminate,
			object: nil)
	}
	
	fileprivate func removeObserver() {
		NotificationCenter.default.removeObserver(self)
		UserManager.shared.delMessageObserver(observer: self)
		MessageCenter.shared.delMessageObserver(observer: self)
		NotificationManager.shared.actionDelegate = nil
	}
	
	func appMovedToBackground() {
		self.topMatchDiscovery.appMovedToBackground?()
	}
	
	func appMovedToForeground() {
		self.topMatchDiscovery.appMovedToForeground?()
	}
	
	func appWillTerminate() {
		self.topMatchDiscovery.appWillTerminate?()
	}
	
	func presentVideoCall(after completion: @escaping () -> Void) {
		self.topMatchDiscovery.presentVideoCall(after: completion)
	}
	
	func didDismissVideoCall(call: VideoCallModel) {
		self.topMatchDiscovery.didDismissVideoCall?(call: call)
	}
	
	func didReceiveMessage(type: String, in chat: String) {
		self.topMatchDiscovery.didReceiveMessage(type: type, in: chat)
	}
	
	func matchTypeChanged(newType: MatchType) {
		self.refreshIcon()
		self.onepMatchDiscovery?.matchTypeChanged(newType: newType)
		self.twopMatchDiscovery?.matchTypeChanged(newType: newType)
	}
}

// app permission check
extension MainViewController {
	
	func checkNotifiPermission(){
		if #available(iOS 10.0, *) {
			let center = UNUserNotificationCenter.current()
			DispatchQueue.main.async {
				center.getNotificationSettings(completionHandler: { (setting) in
					if setting.authorizationStatus == UNAuthorizationStatus.authorized {
						DispatchQueue.main.async {
							UIApplication.shared.registerForRemoteNotifications()
						}
					}
				})
			}
		}else if UIApplication.shared.isRegisteredForRemoteNotifications {
			UIApplication.shared.registerForRemoteNotifications()
		}
	}
	
	func checkCamAccess() {
		let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
		let micPhoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
		guard cameraAuthorizationStatus != .authorized || micPhoneAuthorizationStatus != .authorized else {
			HWCameraManager.shared().prepare()
			return
		}
		
		if cameraAuthorizationStatus != .authorized {
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
				if (!granted) {
					let alert = UIAlertController(title: "Monkey needs access to camera", message: "Please give Monkey access to camera in the Settings app.", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Sure", style: .cancel, handler: {
						(UIAlertAction) in
						guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
							return
						}
						
						if UIApplication.shared.canOpenURL(settingsUrl) {
							UIApplication.shared.openURL(settingsUrl)
						}
					}))
					DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 0.5)) {
						self.present(alert, animated: true, completion: nil)
					}
				}
			})
		}else {
			HWCameraManager.shared().prepare()
			AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
				if (!granted) {
					let alert = UIAlertController(title: "Monkey needs access to microphone", message: "Please give Monkey access to microphone in the Settings app.", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Sure", style: .cancel, handler: {
						(UIAlertAction) in
						guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
							return
						}
						
						if UIApplication.shared.canOpenURL(settingsUrl) {
							UIApplication.shared.openURL(settingsUrl)
						}
					}))
					
					DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 0.5)) {
						self.present(alert, animated: true, completion: nil)
					}
				}
			})
		}
	}
}

extension MainViewController: MessageObserver {
	
	// 收到对 match 的操作
	func didReceiveMatchSkip(in chat: String) {
		self.topMatchDiscovery.didReceiveMessage(type: MessageType.Skip.rawValue, in: chat)
	}
	func didReceiveMatchAccept(in chat: String) {
		self.topMatchDiscovery.didReceiveMessage(type: MessageType.Accept.rawValue, in: chat)
	}
	
	func didReceiveOnepMatch(match: MatchModel) {
		if self.topMatchDiscovery is OnepMatchController {
			self.topMatchDiscovery.didReceiveOnepMatch!(match: match)
		}
	}
	
	func didReceiveTwopInvite(from friend: String) {
		self.tipNumber += 1
		self.refreshIcon()
	}
	
	func didClickBananaNotification() {
		self.loadBananas(isNotificationBool: true)
	}
	
	func didReceiveTwopMatch(match: MatchModel) {
		if self.topMatchDiscovery is TwopMatchController {
			self.topMatchDiscovery.didReceiveTwopMatch!(match: match)
		}
	}
	
	func didReceivePairAccept(acceptedPair: PairGroup) {
		if self.isMatchStart {
			return
		}
		
		if self.matchType == MatchType.Twop {
	 		self.twopMatchDiscovery?.didReceivePairAccept(acceptedPair: acceptedPair)
		}
	}
	
	func didReceiveFriendAdded() {
		guard self.presentedViewController is FriendsViewController else {
			return
		}
		self.friendsButton.imageView?.image = #imageLiteral(resourceName: "FriendsButtonNotification")
	}
	
	func didReceiveConversationMessage() {
		guard self.presentedViewController is FriendsViewController else {
			return
		}
		self.friendsButton.imageView?.image = #imageLiteral(resourceName: "FriendsButtonNotification")
	}
}

extension MainViewController: UserObserver {
	func currentUserInfomationChanged() {
		self.refreshBananas()
		self.refreshIcon()
	}
}

extension UIViewController {
	var mainViewController: MainViewController? {
		
		if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
			if rootViewController is MainViewController {
				return (rootViewController as? MainViewController)
			}else if let presentingVC = rootViewController.presentedViewController as? MainViewController {
				return presentingVC
			}
		}
		
		var parentVC = self.parent
		
		repeat {
			if parentVC is MainViewController {
				return parentVC as? MainViewController
			}else {
				parentVC = parentVC?.parent
			}
		} while parentVC != nil
		
		return nil
	}
}

extension MainViewController {
	func heroDidEndAnimatingTo(viewController: UIViewController) {
		self.topMatchDiscovery.didMoveTo(screen: viewController)
		
	}
	func heroDidEndAnimatingFrom(viewController: UIViewController) {
		self.topMatchDiscovery.didShowFrom(screen: viewController)
	}
}

extension MainViewController: MatchServiceObserver {
	fileprivate func handleMatchError(error: MatchError) {
		guard self.videoCall != nil else { return }
		
		// 服务器上报配对结果，必须在上一步记录检测结果之后
		self.reportCallEnd()
		
		// dismiss chat controller
		self.dismissVideoCall()
		
		// 断开连接
		self.videoCallManager.disconnect()
	}
	
	fileprivate func reportCallEnd() {
		
	}
	
	fileprivate func tryChating() {
		guard let videoCall = self.videoCall else { return }
		guard self.matchViewController == nil else {
			return
		}
		
		// 如果已经收到所有人的流
		if videoCall.allUserConnected() {
			// dismiss all bar
			NotificationManager.shared.dismissAllNotificationBar()
			// stop timer
			self.videoCallManager.beginChat()
			// present
			self.showVideoCall()
		}
	}
	
	func disconnect(reason: MatchError) {
		self.handleMatchError(error: reason)
	}
	
	func remoteVideoReceived(user user_id: Int) {
		// 收到对方的视频流
		self.tryChating()
	}
	
	// match message
	func handleReceivedMessage(message: MatchMessage) {
		let type = MessageType.init(type: message.type)
		switch type {
		case .PceOut:
			self.receivePceOut(message: message)
		default:
			self.matchViewController?.handleReceivedMessage(message: message)
		}
	}
	
	fileprivate func receivePceOut(message: MatchMessage) {
		if let sender = message.sender, self.videoCall?.matchedUser(with: sender) != nil {
			self.handleMatchError(error: .OtherSkip)
		}
	}
	
	func channelMessageReceived(message: MatchMessage) {
		self.handleReceivedMessage(message: message)
	}
	
	func showVideoCall() {
		guard let videoCall = self.videoCall else { return }
		
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: "callVC") as! CallViewController
		self.matchViewController = matchViewController
		
		var presentingVC: UIViewController = self
		while let presentedVC = presentingVC.presentedViewController {
			presentingVC = presentedVC
		}
		matchViewController.present(from: presentingVC, from: self, with: videoCall, complete: nil)
	}
	
	func dismissVideoCall() {
		guard let videoCall = self.videoCall else { return }
		self.videoCall = nil
		
		guard let matchViewController = self.matchViewController else {
			self.videoCallManager.sendResponse(type: .Skip, to: videoCall)
			NotificationManager.shared.dismissAllNotificationBar()
			self.didDismissVideoCall(call: videoCall)
			return
		}
		
		self.matchViewController = nil
		matchViewController.dismiss(complete: { [weak self] in
			self?.didDismissVideoCall(call: videoCall)
			self?.localPreview.addLocalPreview()
		})
	}
}

extension MainViewController: InAppNotificationActionDelegate {
	
	func videoCallDidAccept(videoCall: VideoCallModel, from bar: InAppNotificationBar?) {
		// didmiss other
		videoCall.accept = true
		self.videoCall = videoCall
		self.videoCallManager.delegate = self
		if videoCall.call_out == false {
			self.videoCallManager.sendResponse(type: .Accept, to: videoCall)
		}
		
		self.presentVideoCall {
			self.videoCallManager.connect(with: videoCall)
		}
	}
	
	func videoCallDidReject(videoCall: VideoCallModel, from bar: InAppNotificationBar?) {
		self.videoCallManager.sendResponse(type: .Skip, to: videoCall)
	}
	
	func twopInviteDidAccept(from friend: Int) {
		self.tipNumber -= 1
		self.refreshIcon()
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/2pinvitations/accept/\(friend)", method: .post) { (_) in
			
		}
	}
	
	func twopInviteDidReject(from friend: Int) {
		self.tipNumber -= 1
		self.refreshIcon()
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/2pinvitations/ignore/\(friend)", method: .post) { (_) in
			
		}
	}
	
	func pairRequestDidAccept(invitePair: InvitedPair, from bar: InAppNotificationBar?) {
		if self.matchType == .Onep {
			self.switchTo(mode: .Twop) {
				self.twopMatchDiscovery?.didAcceptPairInvite(friend: invitePair.friend_id)
			}
		}else {
			self.twopMatchDiscovery?.didAcceptPairInvite(friend: invitePair.friend_id)
		}
	}
	
	func pairRequestDidReject(invitePair: InvitedPair, from bar: InAppNotificationBar?) {
		
	}
}
