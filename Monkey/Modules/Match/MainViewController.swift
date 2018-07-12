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

/**
*	user_id: UserAvatarTag
*/
public let AccessUserAvatarArrayTag = "AccessUserAvatarArray"
/**
*	is_tap_setting: bool
*/
typealias UserAvatarTag = [String: Bool]

public let RemoteNotificationTag = "RemoteNotification" // 推送消息通知key
public let KillAppBananaNotificationTag = "KillAppBananaNotificationTag"
public let BananaAlertDataTag = "BananaAlertData" // Adjust promotion link下载，Bananas提醒tag


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
	
	func didReceiveMessage(type: String, in chat: String)
	
	func matchTypeChanged(newType: MatchType)
}

class MainViewController: SwipeableViewController {
	
	private var onepMatchDiscovery: MatchContainer?
	private var twopMatchDiscovery: MatchContainer?
	fileprivate var topMatchDiscovery: MatchContainer!
	fileprivate var matchType: MatchType? {
		didSet(oldValue) {
			if oldValue == nil {
				if self.matchType == .Onep {
					if self.twopMatchDiscovery == nil {
						self.onepMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "oneP") as! MatchContainer)
					}
					self.topMatchDiscovery = self.onepMatchDiscovery
				}else if self.matchType == .Twop {
					if self.twopMatchDiscovery == nil {
						self.twopMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "twoP") as! MatchContainer)
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
	
	@IBOutlet weak var bananaView: BigYellowButton!
	@IBOutlet weak var bananaCountLabel: UILabel!
	
	@IBOutlet weak var channelUpdateRemindV: UIView!
	var isMatchStart: Bool = false
	
	var yesterdayString: Int?
	var addTimeString: Int?
	var addFriendString: Int?
	var equivalentString: String?
	var alertTextFieldString: String = ""
	
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
		self.loadBananaData(isNotificationBool: false)
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
		self.refreshMatchTypeStatus()
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
	
	func startMatch() {
		self.isMatchStart = true
		self.twoPTipLabel.isHidden = true
		self.filtersButton.isHidden = true
		self.matchModeSwitch.isHidden = true
	}
	
	func beginMatchProcess() {
		self.bananaView.isHidden = true
		self.friendsButton.isHidden = true
		self.settingsButton.isHidden = true
		self.pageViewIndicator.isHidden = true
		self.channelsButton.isHidden = true
		self.isSwipingEnabled = false
	}
	
	func endMatchProcess() {
		self.bananaView.isHidden = false
		if self.matchType == .Onep {
			self.friendsButton.isHidden = false
			self.settingsButton.isHidden = false
			self.pageViewIndicator.isHidden = false
			self.channelsButton.isHidden = false
			self.isSwipingEnabled = true
		}
	}
	
	func endMatch() {
		self.isMatchStart = false
		self.matchModeSwitch.isHidden = false
		if self.matchType == .Onep {
			self.filtersButton.isHidden = false
			self.refreshRemindTip()
		}
	}
	
	func reloadIcon() {
		var hideButton = false
		if self.matchType == .Twop {
			hideButton = true
		}
		
		self.twoPTipLabel.isHidden = hideButton
		self.filtersButton.isHidden = hideButton
		self.friendsButton.isHidden = hideButton
		self.settingsButton.isHidden = hideButton
		self.channelsButton.isHidden = hideButton
	}
	
	private func switchTo(mode: MatchType) {
		if mode == self.matchType {
			return
		}
		
		if mode == .Onep {
			self.switchToOnep()
		}else {
			self.switchToTwop()
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
	
	private func switchToOnep() {
		if self.onepMatchDiscovery == nil {
			self.onepMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "oneP") as! MatchContainer)
		}
		self.exchange(topMatchVC: self.onepMatchDiscovery!)
	}
	
	private func switchToTwop() {
		if self.twopMatchDiscovery == nil {
			self.twopMatchDiscovery = (UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "twoP") as! MatchContainer)
		}
		self.exchange(topMatchVC: self.twopMatchDiscovery!)
	}
	
	private func exchange(topMatchVC: MatchContainer) {
		var oldTopVC: MatchContainer? = nil
		if self.matchType == .Onep {
			oldTopVC = self.onepMatchDiscovery
		}else if self.matchType == .Twop {
			oldTopVC = self.twopMatchDiscovery
		}
		self.hide(old: oldTopVC)
		
		self.show(new: topMatchVC, from: oldTopVC)
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
	
	var matchViewController: UIViewController?
	@IBAction func presentVideoMode(_ sender: Any) {
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: "OnepPair")
		self.present(matchViewController!, animated: false, completion: nil)
	}
	
	@IBAction func presentTextMode(_ sender: Any) {
		let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: "TwopPair")
		self.present(matchViewController!, animated: false, completion: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
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
		self.handleFirstNameExistFunc()
		
		// should present banana
		self.refreshBananas()
		self.handleBananaAlertFunc()
		
		// add local preview
		self.localPreview.addLocalPreview()
		UIView.animate(withDuration: 0.3) {
			self.contentView.alpha = 1.0
		}
	}
	
	private func showCurrentDiscovery() {
		guard self.topMatchDiscovery.parent == nil else { return }
		
		self.show(new: self.topMatchDiscovery)
	}
	
	private func refreshMatchTypeStatus() {
		var matchType = MatchType.Onep
		if let currentUser = UserManager.shared.currentUser, self.matchType == nil {
			// if user enable twop
			if currentUser.cached_enable_two_p {
				self.matchModeSwitch.isHidden = false
				// if user has select twop
				if currentUser.cached_match_type == MatchType.Twop.rawValue {
					matchType = MatchType.Twop
				}
			}else {
//				self.matchModeSwitch.isHidden = true
			}
		}
		
		self.matchType = matchType
	}
	
	fileprivate func refreshRemindTip() {
		if self.matchModeSwitch.isHidden == false, self.matchType == .Onep, self.isMatchStart == false {
			// refresh count
			self.twoPTipLabel.isHidden = false
		}else {
			self.twoPTipLabel.isHidden = true
		}
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
	
	private func handleFirstNameExistFunc() {
		guard let currentUser = UserManager.shared.currentUser else { return }
		if currentUser.hasName() { return }
		
		let alertController = UIAlertController(title: "⚠️ Name Change ⚠️", message: "yo keep it pg this time", preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.placeholder = "Input"
			NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextDidChanged), name: NSNotification.Name.UITextFieldTextDidChange, object: textField)
		}
		
		let doneAction = UIAlertAction(title: "kk", style: .default, handler: { (alertAction) in
			currentUser.update(attributes: [.first_name(self.alertTextFieldString)], completion: { (error) in
				if let error = error {
					if error.status == "400" {
						return self.present(error.toAlert(onOK: { (UIAlertAction) in
							self.handleFirstNameExistFunc()
						}, title:"yo keep it pg", text:"try again"), animated: true, completion: nil)
					}
				}
			})
		})
		
		doneAction.isEnabled = false
		alertController.addAction(doneAction)
		self.present(alertController, animated: true, completion: nil)
	}
	
	func alertTextDidChanged(notification: NSNotification) {
		if let alertController = self.presentedViewController as? UIAlertController,
			let textField = alertController.textFields?.first,
			let doneAction = alertController.actions.first
		{
			doneAction.isEnabled = textField.charactersCount > 2
			self.alertTextFieldString = textField.text ?? ""
		}
	}
	
	private func handleBananaAlertFunc() {
		if let bananaAlertData = UserDefaults.standard.dictionary(forKey: BananaAlertDataTag), let is_used = bananaAlertData["is_used"] as? Bool, is_used == true {
			let alertController = UIAlertController(title: bananaAlertData["text"] as? String ?? "", message: nil, preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "kk", style: .default, handler: nil))
			
			DispatchQueue.main.async {
				self.present(alertController, animated: true, completion: nil)
			}
		}
	}
	
	private func loadBananaData(isNotificationBool: Bool) {
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v1.3/bananas", options: [
			.header("Authorization", UserManager.authorization),
			]).addCompletionHandler { (result) in
				switch result {
				case .error(let error):
					error.log()
				case .success(let jsonAPIDocument):
					
					let json = jsonAPIDocument.dataResource?.json
					if let me = json?["me"] as? [String: Int] {
						self.yesterdayString = me["yesterday"]
					}
					
					if let redeem = json?["redeem"] as? [String: Int] {
						self.addTimeString = redeem["add_time"]
						self.addFriendString = redeem["add_friend"]
					}
					
					self.equivalentString = json?["promotion"] as? String
					
					let savedBananaNotificationTag = UserDefaults.standard.string(forKey: KillAppBananaNotificationTag) ?? ""
					if isNotificationBool || savedBananaNotificationTag.count > 0 {
						self.showBananaDescription(isNotificationBool: isNotificationBool)
					}
				}
		}
	}
	
	func getUnhandledFriendsRequestCountFunc() {
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { [weak self] (response) in
				switch response {
				case .error(let error):
					print("*** error : = \(error.message)")
				case .success(let jsonAPIDocument):
					print("*** jsonAPIDocument = \(jsonAPIDocument.json)")
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						if array.count > 0 {
							
							var models : [FriendsRequestModel] = []
							
							array.forEach({ (contact) in
								let userId = APIController.shared.currentUser!.user_id
								let friendsRequestModel = FriendsRequestModel.friendsRequestModel(dict: contact)
								
								if userId == friendsRequestModel.inviteeIdInt?.description && TwopChatRequestsStatusEnum.unhandle.rawValue == friendsRequestModel.statusInt {
									models.append(friendsRequestModel)
								}
							})
						}
					}
				}
				self?.refreshRemindTip()
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
		self.showBananaDescription(isNotificationBool: false)
	}
	
	private func showBananaDescription(isNotificationBool: Bool) {
		guard let yesterdayString = self.yesterdayString, let addTimeString = self.addTimeString, let addFriendString = self.addFriendString, let equivalentString = self.equivalentString else {
			return
		}
		if isNotificationBool == false {
			UserDefaults.standard.setValue("", forKey: KillAppBananaNotificationTag)
		}
		
		AnalyticsCenter.log(withEvent: .bananaPopupEnter, andParameter: ["source": isNotificationBool ? "push" : "discovery"])
		let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.lineSpacing = 9
		paragraph.alignment = .center
		
		let string = "📲Yesterday: 🍌\(yesterdayString) \n 🕑 Time added = 🍌\(addTimeString) \n 🎉 Friend added = 🍌\(addFriendString) \n\n \(equivalentString)"
		
		let attributedString = NSAttributedString(
			string: string,
			attributes: [
				NSParagraphStyleAttributeName: paragraph,
				NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)
			]
		)
		
		alert.setValue(attributedString, forKey: "attributedMessage")
		alert.addAction(UIAlertAction(title: "Cool", style: .cancel, handler: nil))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	deinit {
		self.removeObserver()
	}
}

// MARK: - loading view logic
extension MainViewController {
	
	func setupFriendships() {
		// Predicates restricting which users come back (we don't want friendships as a result from blocks)
		let userId = APIController.shared.currentUser?.user_id ?? ""
		let isNotCurrentUser = NSPredicate(format: "user.user_id != \"\(userId)\"")
		let isInConversation = NSPredicate(format: "last_message_at != nil")
		let isNotBlocker = NSPredicate(format: "is_blocker == NO")
		let isNotBlocking = NSPredicate(format: "is_blocking == NO")
		let isUnreadConversation = NSPredicate(format: "last_message_read_at < last_message_received_at")
		
		let realm = try? Realm()
		let friendships = realm?.objects(RealmFriendship.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
			isNotBlocker,
			isNotBlocking,
			isNotCurrentUser,
			isInConversation,
			isUnreadConversation
			]))
		
		if friendships.count > 0 {
			self.friendsButton.imageView?.image = #imageLiteral(resourceName: "FriendsButtonNotification")
		} else {
			self.friendsButton.imageView?.image = #imageLiteral(resourceName: "FriendsButton")
		}
	}
	
	func refreshBananas() {
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = .decimal
		let bananaCount = APIController.shared.currentUser?.bananas ?? 0
		let formattedNumber = numberFormatter.string(from: NSNumber(value:bananaCount))
		self.bananaCountLabel.text = formattedNumber
	}
}

// application status notify
extension MainViewController: MatchObserver {
	fileprivate func addObserver() {
		UserManager.shared.addMessageObserver(observer: self)
		MessageCenter.shared.addMessageObserver(observer: self)
		
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
	}
	
	func appMovedToBackground() {
		
	}
	
	func appMovedToForeground() {
		
	}
	
	func appWillTerminate() {
		
	}
	
	func didReceiveMessage(type: String, in chat: String) {
		
	}
	
	func matchTypeChanged(newType: MatchType) {
		if self.matchModeSwitch.isHidden == false {
			if newType == .Onep {
				self.matchModeSwitch.backgroundColor = UIColor.init(red: 1, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1)
				self.isSwipingEnabled = true
			}else {
				self.matchModeSwitch.backgroundColor = UIColor.white
				self.isSwipingEnabled = false
			}
			self.reloadIcon()
			self.refreshRemindTip()
		}
		
		self.topMatchDiscovery.matchTypeChanged(newType: newType)
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
	func didReceiveSkip(in chat: String) {
		self.topMatchDiscovery.didReceiveMessage(type: MessageType.Skip.rawValue, in: chat)
	}
	func didReceiveAccept(in chat: String) {
		self.topMatchDiscovery.didReceiveMessage(type: MessageType.Accept.rawValue, in: chat)
	}
	
	func webSocketDidRecieveVideoCall(videoCall: Any, data: [String : Any]) {
		// present call view controller
//		if let chatsession = IncomingCallManager.shared.createChatSession(fromVideoCall: videoc) {
//			let callnoti = NotificationManager.shared.showCallNotification(chatSession: chatsession, completion: { (callResponse) in
//				switch callResponse {
//				case .accepted:
//					if self.chatSession != nil {
//						self.chatSession?.disconnect(.consumed)
//					}
//					self.chatSession = chatsession
//					chatsession.loadingDelegate = self
//					chatsession.accept()
//				case .declined:
//					//					IncomingCallManager.shared.cancelVideoCall(chatsession: chatsession)
//					chatsession.disconnect(.consumed)
//				}
//			})
//
//			chatsession.didReceiveAccept()
//			IncomingCallManager.shared.showingNotification = callnoti
//			self.callNotification = callnoti
//		}
	}
	
	func didReceiveOnepMatch(match: MatchModel) {
		if self.topMatchDiscovery is OnepMatchController {
			self.topMatchDiscovery.didReceiveOnepMatch!(match: match)
		}
	}
	
	func didReceiveTwopMatch(match: MatchModel) {
		if self.topMatchDiscovery is TwopMatchController {
			self.topMatchDiscovery.didReceiveTwopMatch!(match: match)
		}
	}
}

extension MainViewController: UserObserver {
	
	//	var bananaNotificationToken: NotificationToken?
}

extension UIViewController {
	var mainViewController: MainViewController? {
		
		if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
			if rootViewController is MainViewController {
				return (rootViewController as? MainViewController)
			}else if let presentingVC = rootViewController as? MainViewController {
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

