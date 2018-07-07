
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
import RealmSwift
import ObjectMapper
import UserNotifications
import Kingfisher
import Alamofire

/**
*	is_tap_setting: bool
*/
typealias UserAvatarTag = [String: Bool]

/**
*	user_id: UserAvatarTag
*/
public let AccessUserAvatarArrayTag = "AccessUserAvatarArray"

public let ScreenWidth = UIScreen.main.bounds.width
public let ScreenHeight = UIScreen.main.bounds.height

public let RemoteNotificationTag = "RemoteNotification" // 推送消息通知key
public let KillAppBananaNotificationTag = "KillAppBananaNotificationTag"
public let BananaAlertDataTag = "BananaAlertData" // Adjust promotion link下载，Bananas提醒tag

typealias MatchViewController = UIViewController & MatchViewControllerProtocol

class MainViewController: SwipeableViewController, ChatSessionLoadingDelegate {
	
	func webSocketDidRecieveVideoCall(videoCall: Any, data: [String : Any]) {
		guard IncomingCallManager.shared.chatSession == nil, let videoc = videoCall as? RealmVideoCall else {
			return
		}
		
		// present call view controller
		if let chatsession = IncomingCallManager.shared.createChatSession(fromVideoCall: videoc) {
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
		}
	}
	
	func webSocketDidRecieveVideoCallCancel(data: [String : Any]) {
		if let chatSession = IncomingCallManager.shared.chatSession, chatSession.isDialedCall == true {
			IncomingCallManager.shared.dismissShowingNotificationForChatSession(chatSession)
			if let currentChatSession = self.chatSession {
				currentChatSession.disconnect(.consumed)
			}
		}
	}
	
	func webSocketDidRecieveMatch(match: Any, data: [String : Any]) {
		AnalyticsCenter.log(event: AnalyticEvent.matchReceivedTotal)
		
		if let realmCall = match as? RealmCall {
			LogManager.shared.addLog(type: .ReceiveMatchMessage, subTitle: "video_service: \(realmCall.video_service ?? "") - notify_accept: \(realmCall.notify_accept.value ?? false)", info: data)
			if self.chatSession == nil, self.stopFindingReasons.count == 0 {
				self.progressMatch(call: realmCall, data: data)
			}
		}
	}
	
	func webScoketDidRecieveChatMessage(data: [String : Any]) {
		self.chatButton.imageView?.image = #imageLiteral(resourceName: "FriendsButtonNotification")
	}
	
	internal func showAlert(alert: UIAlertController) {
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBOutlet weak var loadingContentView: MakeUIViewGreatAgain!
	
	@IBOutlet weak var pageViewIndicator: UIPageControl!
	@IBOutlet weak var arrowButton: BigYellowButton!
	@IBOutlet weak var bottomArrowPadding: NSLayoutConstraint!
	
	@IBOutlet weak public var acceptButton: BigYellowButton!
	@IBOutlet weak public var rejectButton: BigYellowButton!
	@IBOutlet weak public var skipButton: UIButton!
	
	@IBOutlet weak public var settingsButton: BigYellowButton!
	@IBOutlet weak var chatButton: BigYellowButton!
	@IBOutlet weak var filterButton: BigYellowButton!
	
	@IBOutlet weak var twoPersonButton: BigYellowButton! // 2p按钮
	@IBOutlet weak var redDotLabel: UILabel! // 红点数量提示
	
	@IBOutlet weak var matchModeContainer: UIView!
	@IBOutlet weak var matchModeTip: UILabel!
	@IBOutlet weak var matchModeEmojiLeft: UILabel!
	@IBOutlet weak var matchModeEmojiRight: UILabel!
	
	@IBOutlet weak var channelUpdateRemindV: UIView!
	@IBOutlet weak public var loadingTextLabel: LoadingTextLabel!
	@IBOutlet var skippedTextBottomConstraint: NSLayoutConstraint!
	@IBOutlet var skippedText: UILabel!
	@IBOutlet var waitingText: UILabel!
	@IBOutlet weak var connectText: UILabel!
	
	@IBOutlet weak var matchModePopupTop: NSLayoutConstraint!
	@IBOutlet weak var matchModePopup: UIView!
	@IBOutlet weak var matchModeLabel: UILabel!
	
	@IBOutlet var matchModeSwitch: MatchModeSwitch!
	
	@IBOutlet var eventModePopup: SmallYellowButton!
	@IBOutlet weak var eventModeEmoji: UILabel!
	@IBOutlet weak var eventModeTitle: UILabel!
	@IBOutlet weak var eventModeSwitch: MonkeySwitch!
	@IBOutlet weak var eventModeDescription: UILabel!
	
	var match_event: RealmMatchEvent?
	
	@IBOutlet weak var bananaView: BigYellowButton!
	@IBOutlet weak var bananaCountLabel: UILabel!
	@IBOutlet weak var bananaViewWidthConstraint:NSLayoutConstraint!
	@IBOutlet weak var colorGradientView:UIView!
	
	weak var matchViewController: MatchViewController?
	
//	weak var callNotification: CallNotificationView?
	var incomingCallId: String?
	var incomingCallBio: String?
	var nextSessionToPresent: ChatSession?
	var channels: Results<RealmChannel>? {
		let realm = try? Realm()
		let channels = realm?.objects(RealmChannel.self).filter(NSPredicate(format: "is_active = true"))
		return channels
	}
	
	var responseTimeoutCount = 0
	var matchRequestTimer: Timer?
	var curCommonTree: RealmChannel?
	
	var yesterdayString: Int?
	var addTimeString: Int?
	var addFriendString: Int?
	var equivalentString: String?
	
	var profileImage : UIImage?
	
	var alertTextFieldString = ""
	
	var bananaNotificationToken: NotificationToken?
	var unreadMessageNotificationToken: NotificationToken?
	
	internal func statusChanged(isSkip: Bool) {
		if isSkip {
			// If user is able to accept/skip call, do not allow them to swipe between views
			self.isSwipingEnabled = false
		} else {
			// Conversely, enable swipe interaction under normal circumstances
			self.isSwipingEnabled = true
		}
	}
	
	// show channels list
	@IBAction func settingsButtonTapped(sender: Any) {
		self.present(self.swipableViewControllerToPresentOnRight!, animated: true, completion: nil)
	}
	
	@IBAction func chatButtonTapped(sender: Any) {
		self.present(self.swipableViewControllerToPresentOnLeft!, animated: true, completion: nil)
	}
	
	@IBAction func filterButtonTapped(_ sender: Any) {
		AnalyticsCenter.log(event: .videoFilterClick)
		self.present(self.swipableViewControllerToPresentOnTop!, animated: true, completion: nil)
	}
	
	@IBAction func arrowButtonTapped(sender: Any) {
		self.present(self.swipableViewControllerToPresentOnBottom!, animated: true, completion: nil)
		
		if let user_id = APIController.shared.currentUser?.user_id {
			var userAvatarTagInfo = UserDefaults.standard.dictionary(forKey: AccessUserAvatarArrayTag) as? [String: UserAvatarTag] ?? [String: UserAvatarTag]()
			var myAvatarTag = userAvatarTagInfo[user_id] ?? UserAvatarTag()
			myAvatarTag["is_tap_setting"] = true
			userAvatarTagInfo[user_id] = myAvatarTag
			UserDefaults.standard.setValue(userAvatarTagInfo, forKey: AccessUserAvatarArrayTag)
			self.handleAcceptButtonStateFunc(state: false)
		}
	}
	
	override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
		if viewControllerToPresent == self.swipableViewControllerToPresentOnRight {
			self.channelUpdateRemindV.alpha = 0
		}else if viewControllerToPresent == self.swipableViewControllerToPresentOnLeft {
			self.chatButton.imageView?.image = #imageLiteral(resourceName: "FriendsButton")
		}
		
		if self.presentedViewController != nil {
			var presentedVC = self.presentedViewController!
			while presentedVC.presentedViewController != nil {
				presentedVC = presentedVC.presentedViewController!
			}
			presentedVC.present(viewControllerToPresent, animated: true, completion: nil)
			
		}else {
			super.present(viewControllerToPresent, animated: flag, completion: completion)
		}
	}
	
	@IBOutlet var containerView: UIView!
	
	var lastChatSession: ChatSession?
	var chatSession: ChatSession?
	var nextFact = APIController.shared.currentExperiment?.initial_fact_discover ?? ""
	
	// 如果匹配到了人，则屏幕无法熄灭
	var isFindingChats = false {
		didSet {
			if self.isFindingChats {
				UIApplication.shared.isIdleTimerDisabled = true
			} else {
				UIApplication.shared.isIdleTimerDisabled = false
			}
		}
	}
	
	fileprivate var friendships: Results<RealmFriendship>?
	var isSkip: Bool = false {
		didSet {
			self.statusChanged(isSkip: isSkip)
			
			if isSkip {
				self.skipButton.isHidden = false
				self.rejectButton.isHidden = false
				self.acceptButton.isHidden = false
				self.matchModeContainer.isHidden = false
				self.arrowButton.isHidden = true
				self.settingsButton.isHidden = true
				self.chatButton.isHidden = true
				self.filterButton.isHidden = true
				self.pageViewIndicator.isHidden = true
				self.bananaView.isHidden = true
				self.matchModeSwitch.isHidden = true
				self.matchModePopup.isHidden = true
				self.eventModePopup.isHidden = true
				self.channelUpdateRemindV.isHidden = true
				self.loadingTextLabel.isHidden = true
				
				let matchMode = self.chatSession?.matchMode ?? .VideoMode
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
			} else {
				self.matchModeContainer.isHidden = true
				self.acceptButton.isHidden = true
				self.rejectButton.isHidden = true
				self.skipButton.isHidden = true
				self.arrowButton.isHidden = false
				self.settingsButton.isHidden = false
				self.chatButton.isHidden = false
				self.filterButton.isHidden = false
				self.pageViewIndicator.isHidden = false
				self.bananaView.isHidden = false
				self.channelUpdateRemindV.isHidden = false
				self.loadingTextLabel.isHidden = false
				
				if self.matchModeSwitch.isEnabled {
					self.matchModeSwitch.isHidden = false
				}
				
				self.refreshEventModeStatus()
			}
		}
	}
	@IBOutlet weak var commonTreeTip: UILabel!
	@IBOutlet weak var matchUserPhoto: UIImageView!
	
	@IBOutlet weak var startView: UIView!
	@IBOutlet weak var fingerLabel: UILabel!
	@IBOutlet weak var factTextBottom: NSLayoutConstraint!
	@IBOutlet var factTextView: UILabel!
	fileprivate let numberFormatter = NumberFormatter()
	
	// MARK: UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()
		Configs.signAsLogin()
		
		self.view.backgroundColor = Colors.purple
		self.matchModePopup.isHidden = true
		self.matchModePopup.layer.cornerRadius = 12
		self.matchModePopup.alpha = 0
		
		self.eventModePopup.isHidden = true
		self.eventModePopup.roundedSquare = true
		self.eventModePopup.layer.cornerRadius = 12
		self.eventModePopup.layer.masksToBounds = true
		self.eventModePopup.addTarget(self, action: #selector(changeEventMode), for: .touchUpInside)
		
		self.eventModeSwitch.backgroundColor = UIColor.clear
		self.eventModeSwitch.isEnabled = false
		self.eventModeSwitch.openEmoji = "🤩"
		self.eventModeSwitch.closeEmoji = "🤩"
		
		self.filterButton.layer.cornerRadius = 20
		self.filterButton.layer.masksToBounds = true
		
		self.matchModeContainer.layer.cornerRadius = 24
		self.matchModeContainer.layer.masksToBounds = true
		self.matchModeContainer.layer.borderWidth = 3;
		self.matchModeContainer.layer.borderColor = UIColor.clear.cgColor
		
		self.commonTreeTip.isHidden = true
		self.commonTreeTip.layer.cornerRadius = 24
		self.commonTreeTip.layer.masksToBounds = true
		
		self.matchUserPhoto.isHidden = true
		self.matchUserPhoto.layer.cornerRadius = 24
		self.matchUserPhoto.layer.masksToBounds = true
		self.matchUserPhoto.layer.shadowRadius = 4
		self.matchUserPhoto.layer.shadowColor = UIColor.init(white: 0, alpha: 0.25).cgColor
		
		self.factTextView.isHidden = true
		self.loadingTextLabel.isHidden = true
		
		// 如果 text chat mode 开关关闭，或者分配到实验 B
		if RemoteConfigManager.shared.text_chat_mode == false || Achievements.shared.textModeTestPlan == .text_chat_test_C {
			self.matchModeSwitch.isEnabled = false
			self.matchModeSwitch.isHidden = true
		}else {
			self.matchModeSwitch.isEnabled = true
			self.matchModeSwitch.isHidden = false
		}
		
//		NotificationManager.shared.viewManager = self
//		NotificationManager.shared.chatSessionLoadingDelegate = self
//		IncomingCallManager.shared.delegate = self
		self.swipableViewControllerToPresentOnRight = UIStoryboard(name: "Channels", bundle: .main).instantiateInitialViewController() as? SwipeableViewController
		self.swipableViewControllerToPresentOnLeft = UIStoryboard(name: "Chat", bundle: .main).instantiateInitialViewController() as? SwipeableViewController
		self.swipableViewControllerToPresentOnBottom = UIStoryboard(name: "Settings", bundle: .main).instantiateInitialViewController() as? SwipeableViewController
		self.swipableViewControllerToPresentOnTop = FilterViewController.init()
		
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
		
		self.pageViewIndicator.numberOfPages = 3
		self.pageViewIndicator.currentPage = 1
		self.pageViewIndicator.isUserInteractionEnabled = false
		
		self.startUpdatingLocation()
		
		self.resetFact()
		
		self.addPublisherToView()
		
		if self.channels.count == 0 {
			RealmChannel.fetchAll { (result: JSONAPIResult<[RealmChannel]>, hadUpdate: Bool) in
				switch result {
				case .success(_):
					if hadUpdate {
						self.channelUpdateRemindV.alpha = 1
					}
					break
				case .error(let error):
					error.log()
				}
			}
		}
		
		self.handleAccessUserAvatar()
		self.loadBananaData(isNotificationBool: false)
		self.handleBananaAlertFunc()
		self.setupBananas()
		self.updateBananas()
		self.setupFriendships()
		self.loadCurrentEventMode()
		self.handleTwopStatusFunc()
		
		MessageCenter.shared.addMessageObserver(observer: self)
		
		self.skippedText.layer.opacity = 0.0
		Socket.shared.isEnabled = true
//		Socket.shared.delegate = self
		
		//		Step 1: tap to start
		self.stopFindingChats(andDisconnect: true, forReason: "tap-to-start")
		let startGesture = UITapGestureRecognizer.init(target: self, action: #selector(startFindingMatch))
		startView.addGestureRecognizer(startGesture)
		
		//	    Step 2: check camera and micphone permission
		self.checkCamAccess()
		
		//		Step 3: update user location
		self.stopFindingChats(andDisconnect: true, forReason: "location-services")
		MainViewController.requestLocationPermissionIfUnavailable() // This will cause the thred to hang so we still need to toggle chat finding to cancel any existing requests.
		
		//		Step 4: Start finding chats
		self.startFindingChats(forReason: "location-services")
		NotificationCenter.default.addObserver(self, selector: #selector(handleRemoteNotificationFunc), name: NSNotification.Name(rawValue: RemoteNotificationTag), object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.handleFirstNameExistFunc()
	}
	
	func handleAccessUserAvatar() {
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
	
	func handleAcceptButtonStateFunc(state: Bool) {
		self.arrowButton?.setImage(UIImage(named: state ? "ArrowButtonSel" : "ArrowButton"), for: .normal)
	}
	
	func alertKeyAndVisibleFunc(alert:UIAlertController) {
		let alertWindow = UIWindow(frame: UIScreen.main.bounds)
		alertWindow.rootViewController = MonkeyViewController()
		alertWindow.windowLevel = UIWindowLevelAlert
		alertWindow.makeKeyAndVisible()
		alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
	}
	
	func handleFirstNameExistFunc() {
		if APIController.shared.currentUser?.first_name == nil {
			self.stopFindingChats(andDisconnect: true, forReason: "edit_profile")
			let alertController = UIAlertController(title: "⚠️ Name Change ⚠️", message: "yo keep it pg this time", preferredStyle: .alert)
			alertController.addTextField { (textField) in
				textField.placeholder = "Input"
				NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextDidChanged), name: NSNotification.Name.UITextFieldTextDidChange, object: textField)
			}
			
			let doneAction = UIAlertAction(title: "kk", style: .default, handler: { (alertAction) in
				APIController.shared.currentUser?.update(attributes: [.first_name(self.alertTextFieldString)], completion: { (error) in
					if let error = error {
						if error.status == "400" {
							return self.present(error.toAlert(onOK: { (UIAlertAction) in
								self.handleFirstNameExistFunc()
							}, title:"yo keep it pg", text:"try again"), animated: true, completion: nil)
						}
					}else {
						self.startFindingChats(forReason: "edit_profile")
					}
				})
			})
			
			doneAction.isEnabled = false
			alertController.addAction(doneAction)
			self.present(alertController, animated: true, completion: nil)
		}
	}
	
	func alertTextDidChanged(notification: NSNotification) {
		if let alertController = self.presentedViewController as? UIAlertController {
			let textField = alertController.textFields?.first
			let doneAction = alertController.actions.first
			doneAction?.isEnabled = (textField?.text?.count)! > 2
			self.alertTextFieldString = (textField?.text)!
		}
	}
	
	func refreshEventModeStatus() {
		guard let current_event = self.match_event, APIController.shared.currentUser != nil else {
			return
		}
		
		let currentMatchMode = Achievements.shared.selectMatchMode
		if current_event.isAvailable() {
			self.eventModePopup.isHidden = false
			
			//
			self.eventModeEmoji.text = current_event.emoji
			self.eventModeTitle.text = current_event.name
			self.eventModeDescription.text = current_event.event_bio
			
			if (currentMatchMode == .EventMode) {
				self.eventModeSwitch.open = true
			}else {
				self.eventModeSwitch.open = false
			}
		}else {
			// 如果当前时间不在活动开放时间内
			self.eventModePopup.isHidden = true
			
			if (currentMatchMode == .EventMode) {
				Achievements.shared.selectMatchMode = .VideoMode
			}
		}
		
		var matchTipPopupTop = self.eventModePopup.frame.maxY + 2
		if self.eventModePopup.isHidden {
			matchTipPopupTop = self.matchModeSwitch.frame.maxY + 2
			if self.matchModeSwitch.isHidden {
				matchTipPopupTop = self.bananaView.frame.maxY + 2
			}
		}
		self.matchModePopupTop.constant = matchTipPopupTop;
	}
	
	func loadCurrentEventMode() {
		if let realm = try? Realm() {
			self.match_event = realm.object(ofType: RealmMatchInfo.self, forPrimaryKey: RealmMatchInfo.type)?.events
			self.refreshEventModeStatus()
		}
		
		guard let authorization = APIController.authorization else {
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
						self.match_event = matchInfo.events
					}else {
						self.match_event = nil
					}
					self.refreshEventModeStatus()
				}
		}
	}
	
	func handleBananaAlertFunc() {
		if let bananaAlertData = UserDefaults.standard.dictionary(forKey: BananaAlertDataTag), let is_used = bananaAlertData["is_used"] as? Bool, is_used == true {
			let alertController = UIAlertController(title: bananaAlertData["text"] as? String ?? "", message: nil, preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "kk", style: .default, handler: nil))
			
			DispatchQueue.main.async {
				self.present(alertController, animated: true, completion: nil)
			}
		}
	}
	
	func loadBananaData(isNotificationBool: Bool) {
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
	
	func handleRemoteNotificationFunc(notification: NSNotification) {
		UserDefaults.standard.setValue("", forKey: KillAppBananaNotificationTag)
		self.loadBananaData(isNotificationBool: true)
	}
	
	var stopFindingReasons = [String]()
	func startFindingChats(forReason: String) {
		let prevReasonCount = self.stopFindingReasons.count
		let reason = self.stopFindingReasons.removeObject(object: forReason)
		print("Started finding \(forReason):  \(reason)")
		if prevReasonCount != 0 && self.stopFindingReasons.count == 0 {
			isFindingChats = true
			self.beginMatchRequest()
		} else {
			print("Still not finding because: \(stopFindingReasons.split(separator: ","))")
		}
	}
	
	func stopFindingChats(andDisconnect: Bool, forReason: String) {
		print("Stopped finding: \(forReason)")
		self.continuous_request_count = 0
		self.isFindingChats = false
		self.stopFindingReasons.append(forReason)
		if self.stopFindingReasons.count == 1 {
			self.stopMatchRequest()
		}
		
		if forReason == "is-swiping" {
			self.revokePrevMatchRequest()
		}
		
		if andDisconnect {
			self.chatSession?.disconnect(.consumed)
		}
	}
	
	var chatRequest: JSONAPIRequest? // use to know match request is running
	var continuous_request_count = 0
	var request_id: String?
	var request_time: Date!
	
	func startFindingMatch() {
		self.startFindingChats(forReason: "tap-to-start")
		self.factTextView.isHidden = false
		self.loadingTextLabel.isHidden = false
		self.startView.isHidden = true
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
		// log first match request event
		guard self.nextSessionToPresent == nil else {
			self.chatSession = self.nextSessionToPresent
			self.nextSessionToPresent = nil
			self.chatSession?.accept() // will trigger presentcallvc
			return
		}
		
		if (self.chatRequest != nil || self.chatSession != nil || APIController.authorization == nil) {
			print("Already finding because chatRequest or Retrieving new session before finished with old session.")
			return
		}
		
		self.curCommonTree = nil
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
			print("Chat request completed")
			self.cancelMatchRequest()
			self.trackMatchRequest()
			LogManager.shared.addLog(type: .ApiRequest, subTitle: RealmCall.requst_subfix, info: [
				"error": "\(error.debugDescription)",
				"url": RealmCall.common_request_path,
				"method": HTTPMethod.post.rawValue,
				])
			
			if let error = error {
				error.log(context:"Create (POST) a matched call")
				
				guard error.status != "401" else {
					self.stopFindingChats(andDisconnect: true, forReason: "log-out")
					self.signOut()
					return
				}
			}
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
						guard let completion = completion else {
							return
						}
						completion()
				}
			}
			return
		}
		
		guard let completion = completion else {
			return
		}
		completion()
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
	
	func commomParameters(for event: AnalyticEvent) -> [String: Any] {
		let currentUser = APIController.shared.currentUser
		let is_banned = currentUser?.is_banned.value ?? false
		var match_type = "video"
		if let match_mode = Achievements.shared.selectMatchMode, match_mode == .TextMode {
			match_type = "text"
		}
		
		var commonParameters = [String: Any]()
		commonParameters["user_gender"] = currentUser?.gender
		commonParameters["user_age"] = currentUser?.age.value
		commonParameters["user_country"] = currentUser?.location
		commonParameters["user_ban"] = is_banned ? "true" : "false"
		commonParameters["match_type"] = match_type
		commonParameters["trees"] = currentUser?.channels.first?.title
		return commonParameters
	}
	
	func incomingCallManager(_ incomingCallManager: IncomingCallManager, didDismissNotificatationFor chatSession: ChatSession) {
		self.startFindingChats(forReason: "incoming-call")
	}
	
	func incomingCallManager(_ incomingCallManager: IncomingCallManager, shouldShowNotificationFor chatSession: ChatSession) -> Bool {
		if self.presentedViewController == nil {
			self.stopFindingChats(andDisconnect: false, forReason: "incoming-call")
		}
		return true
	}
	
	func incomingCallManager(_ incomingCallManager: IncomingCallManager, transitionToChatSession chatSession: ChatSession) {
		chatSession.loadingDelegate = self
		guard self.chatSession == nil else {
			self.nextSessionToPresent = chatSession
			self.chatSession?.disconnect(.consumed)
			return
		}
		chatSession.accept()
	}
	
	func appMovedToBackground() {
		self.revokePrevMatchRequest()
		self.stopFindingChats(andDisconnect: false, forReason: "application-status")
		//      Socket.shared.isEnabled = false
		self.chatSession?.userTurnIntoBackground()
	}
	
	func appMovedToForeground() {
		Socket.shared.isEnabled = true
		self.checkCamAccess()
		self.startFindingChats(forReason: "application-status")
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.refreshEventModeStatus()
		self.checkNotifiPermission()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
	}
	
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
		if cameraAuthorizationStatus != .authorized || micPhoneAuthorizationStatus != .authorized {
			self.stopFindingChats(andDisconnect: true, forReason: "permission-access")
			
			if micPhoneAuthorizationStatus != .authorized {
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
			}else {
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
			}
		}
		HWCameraManager.shared().prepare()
	}
	
	private func resetFact() {
		self.setFactText(self.nextFact)
	}
	
	func presentToTwoPersonPlanVcFunc(isPlanB: Bool = false) {
		let vc = UIStoryboard(name: "TwoPerson", bundle: nil).instantiateInitialViewController() as! TwoPersonPlanViewController
		vc.modalPresentationStyle = .overFullScreen
		vc.isPlanBIsUnLockedTuple = (isPlanB, false)
		
		vc.backClosure = {
			self.twoPersonButton.backgroundColor = UIColor.yellow
			self.twoPersonButton.isHidden = false
		}
		
		vc.updateRedDotClosure = { (count) -> Void in
			if count > 0 {
				self.redDotLabel.isHidden = false
				self.redDotLabel.text = count.description
			} else {
				self.redDotLabel.isHidden = true
			}
		}
		
		self.present(vc, animated: true, completion: nil)
	}
	
	func presentToDashboardMainVcFunc() {
		let vc = UIStoryboard(name: "TwoPerson", bundle: nil).instantiateViewController(withIdentifier: "DashboardMainViewController") as! DashboardMainViewController
		vc.modalPresentationStyle = .overFullScreen
		vc.backClosure = {
			self.twoPersonButton.backgroundColor = UIColor.yellow
			self.twoPersonButton.isHidden = false
		}
		self.present(vc, animated: true, completion: nil)
	}
	
	func getUnhandledFriendsRequestCountFunc() {
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
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
							
							if models.count > 0 {
								self.redDotLabel.isHidden = false
								self.redDotLabel.text = models.count.description
							}
						} else {
							self.redDotLabel.isHidden = true
						}
					}
				}
		}
	}
	
	func handleTargetVcFunc() {
		
		let user = APIController.shared.currentUser!
		
		if user.unlocked_two_p.value! {
			self.presentToDashboardMainVcFunc()
		} else {
			if user.two_p_user_group_type.value! == 1 { // plan A
				self.presentToTwoPersonPlanVcFunc(isPlanB: false)
			} else {  // plan B
				self.presentToTwoPersonPlanVcFunc(isPlanB: true)
			}
		}
	}
	
	/**
	 2p相关状态
	*/
	func handleTwopStatusFunc() {
		
		let user = APIController.shared.currentUser!
		
		if user.enabled_two_p.value! {
			self.twoPersonButton.isHidden = false
			
			if user.match_type.value == 2 {
				self.handleTargetVcFunc()
			}
			
			// 请求friends request接口，判断status为0的请求个数
			self.getUnhandledFriendsRequestCountFunc()
		}
	}
	
	@IBAction func twoPersonBtnClickFunc(_ sender: BigYellowButton) {
		
		self.twoPersonButton.backgroundColor = UIColor.white
		
		let user = APIController.shared.currentUser!
		
		var attributes: [RealmUser.Attribute] = []
		
		attributes.append(.match_type(2))
		
		user.update(attributes: attributes) { (error) in
			print("\(error?.status ?? "user update success")")
		}
		
		self.handleTargetVcFunc()
		
//		self.presentToTwoPersonPlanVcFunc()
		
//		self.presentToDashboardMainVcFunc()
	}
	
	@IBAction func acceptButtonTapped(sender: Any) {
		let user_id: String = chatSession?.realmCall?.user?.user_id ?? ""
		let duration: TimeInterval = chatSession?.matchedTime ?? Date.init().timeIntervalSince1970 - request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Accept",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(withEvent: .matchSendAccept, andParameter: [
			"type": (sender is BigYellowButton) ? "btn accept" : "auto accept",
			])
		
		self.responseTimeoutCount = 0
		self.chatSession?.accept()
		self.skipButton.isHidden = true
		self.rejectButton.isHidden = true
		self.acceptButton.isHidden = true
		
		// 对方是否点击了 accept
		if let chatSessionReady = self.chatSession?.matchUserDidAccept {
			if chatSessionReady {
				self.connectText.isHidden = false
			}else {
				self.waitingText.isHidden = false
			}
		}
	}
	
	@IBAction func rejectButtonTapped(_ sender: Any) {
		let user_id: String = chatSession?.realmCall?.user?.user_id ?? ""
		let duration: TimeInterval = chatSession?.matchedTime ?? Date.init().timeIntervalSince1970 - request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Reject",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(event: .matchSendSkip)
		
		self.responseTimeoutCount = 0
		self.resetFact()
		self.chatSession?.response = .skipped
		self.chatSession?.chat?.skipped = true
		self.hideTreeLabels()
		self.start()
	}
	
	@IBAction func skipButtonTapped(_ sender: Any) {
		let user_id: String = chatSession?.realmCall?.user?.user_id ?? ""
		let duration: TimeInterval = chatSession?.matchedTime ?? Date.init().timeIntervalSince1970 - request_time.timeIntervalSince1970
		AnalyticsCenter.log(withEvent: .clickMatchSelect, andParameter: [
			"type": "Skip",
			"info": user_id,
			"match duration": duration,
			])
		
		AnalyticsCenter.log(event: .matchSendSkip)
		
		self.responseTimeoutCount = 0
		self.resetFact()
		self.chatSession?.response = .skipped
		self.chatSession?.chat?.skipped = true
		self.hideTreeLabels()
		self.start()
	}
	
	func changeEventMode() {
		self.stopFindingChats(andDisconnect: false, forReason: "switch match mode")
		self.revokePrevMatchRequest {
			self.startFindingChats(forReason: "switch match mode")
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
			matchModeLabel.text = "You can only choose 1 between event mode and text mode"
			showPopup(popup: matchModePopup)
		}
		
		print("eventModeOpen = \(eventModeOpen)")
	}
	
	func progressMatch(call: RealmCall, data: [String: Any]) {
		let jsonAPIDocument = JSONAPIDocument.init(json: data)
		
		if let meta = jsonAPIDocument.meta, let nextFact = meta["next_fact"] as? String {
			self.nextFact = nextFact
		}
		
		guard let chatId = call.chat_id, /*let received_id = call.request_id, self.request_id == received_id,*/ let sessionId = call.session_id else {
			print("Error: RealmCall object did not return with sufficient data to create a chatSession")
			return
		}
		if call.channelToken.count == 0 {
			return
		}
		
		self.stopFindingChats(andDisconnect: false, forReason: "receive-match")
		self.listTree(tree: call.user?.channels.first?.channel_id ?? "")
		self.matchUserPhoto.isHidden = false
		
		var imageName = "ProfileImageDefaultMale"
		if call.user?.gender == Gender.female.rawValue {
			imageName = "ProfileImageDefaultFemale"
		}
		let placeholder = UIImage.init(named: imageName)
		let profile_photo_url = URL.init(string: call.user?.profile_photo_url ?? "")
		self.matchUserPhoto.kf.setImage(with: profile_photo_url, placeholder: placeholder)

		var bio = "connecting"
		if let callBio = call.bio, let convertBio = callBio.removingPercentEncoding {
			bio = convertBio
			if RemoteConfigManager.shared.app_in_review == true {
				let user_age_str = convertBio.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
				//				print("match a user with age \(user_age_str)")
				if let age_range = convertBio.range(of: user_age_str), let user_age = Int(user_age_str), user_age < 19, user_age > 0 {
					let new_age = abs(Int.arc4random() % 5) + 19
					bio = convertBio.replacingCharacters(in: age_range, with: "\(new_age)")
				}
			}
		}
		
		if let match_distance = call.match_distance.value, match_distance > 0, Achievements.shared.nearbyMatch == true {
			bio = bio.appending("\n🏡\(match_distance)m")
		}
		
		self.chatSession = ChatSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId, chat: Chat(chat_id: chatId, first_name: call.user?.first_name, gender: call.user?.gender, age: call.user?.age.value, location: call.user?.location, profile_image_url: call.user?.profile_photo_url, user_id: call.user?.user_id, match_mode: call.match_mode), token: call.channelToken, loadingDelegate: self, isDialedCall: false)
		
		AnalyticsCenter.add(amplitudeUserProperty: ["match_receive": 1])
		AnalyticsCenter.add(firstdayAmplitudeUserProperty: ["match_receive": 1])
		
		self.chatSession?.track(matchEvent: .matchFirstRecieved)
		self.chatSession?.track(matchEvent: .matchReceived)
		self.start(fact: bio)
		
		if Achievements.shared.autoAcceptMatch {
			self.acceptButtonTapped(sender: self)
		}
	}
	
	func signOut() {
		guard APIController.authorization != nil else {
			return
		}
		
		RealmDataController.shared.deleteAllData() { (error) in
			guard error == nil else {
				error?.log()
				return
			}
			APIController.authorization = nil
//			Socket.shared.fetchCollection = false
			UserDefaults.standard.removeObject(forKey: "user_id")
			UserDefaults.standard.removeObject(forKey: "apns_token")
			
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	func presentCallViewController(for chatSession:ChatSession) {
		self.stopFindingChats(andDisconnect: false, forReason: "re-start")
		// This will do nothing if the current chat
		IncomingCallManager.shared.dismissShowingNotificationForChatSession(chatSession)
		self.waitingText.isHidden = true
		self.connectText.isHidden = true
		self.hideTreeLabels()
		var vcToPresentOn:UIViewController = self
		while vcToPresentOn.presentedViewController is SwipeableViewController {
			vcToPresentOn = vcToPresentOn.presentedViewController!
		}
		if let presentedViewController = vcToPresentOn.presentedViewController {
			presentedViewController.dismiss(animated: false) {
				self.presentCallViewControllerOn(self, for: chatSession)
			}
		} else {
			self.presentCallViewControllerOn(vcToPresentOn, for: chatSession)
		}
	}
	
	func presentCallViewControllerOn(_ viewController: UIViewController, for chatSession: ChatSession) {
		print("sh-1226- presentCallViewControllerOn")
		guard self.chatSession == chatSession || self.chatSession == nil else {
			print("Error: Refusing to dangerously present a chat session while another session is in progress")
			return
		}
		// We set the chat session again since incomingCallManager(_:transitionToChatSession:) wouldn't have set it yet.
		self.chatSession = chatSession
//		if self.callNotification != nil {
//			self.callNotification?.dismiss()
//			self.callNotification = nil
//		}
		
		UIView.animate(withDuration: 0.3, animations: {
			if !(viewController is MainViewController) {
				viewController.view.alpha = 0.0
			}
			self.colorGradientView.alpha = 0.0
		}) { (Bool) in
			var matchModeId = "callVC"
			if (self.chatSession?.chat?.match_room_mode == .TextMode) {
				matchModeId = "textModeVC"
				print("Get textModeVC")
			}else {
				print("Get videoModeVC")
			}
			
			let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: matchModeId) as! MatchViewController
			self.matchViewController = matchViewController
			matchViewController.chatSession = chatSession
			chatSession.callDelegate = matchViewController
			matchViewController.commonTree = self.curCommonTree
			
			Achievements.shared.totalChats += 1
			viewController.present(matchViewController, animated: false, completion: nil)
			if chatSession.friendMatched {
				matchViewController.friendMatched(in: nil)
			}
		}
	}
	
	/// Animateable property to show and hide navigation elements
	var elementsShouldHide: Bool? {
		didSet {
			guard let shouldHide = self.elementsShouldHide else {
				return
			}
			let alpha: CGFloat = shouldHide ? 0 : 1
			self.chatButton.alpha = alpha
			self.filterButton.alpha = alpha
			self.settingsButton.alpha = alpha
			self.bananaView.alpha = alpha
			self.arrowButton.alpha = alpha
			self.loadingTextLabel.alpha = alpha
			self.startView.alpha = alpha
			self.factTextView.alpha = alpha
			self.matchModeSwitch.alpha = alpha
			self.matchModePopup.alpha = alpha
			self.eventModePopup.alpha = alpha
			self.matchModeContainer.alpha = alpha
			
			if (self.presentedViewController == self.swipableViewControllerToPresentOnTop) {
				self.colorGradientView.alpha = alpha
			}else {
				self.colorGradientView.alpha = 1
			}
		}
	}
	
	func dismissCallViewController(for chatSession: ChatSession) {
		HWCameraManager.shared().removePixellate()
		HWCameraManager.shared().changeCameraPosition(to: .front)
		
		if chatSession.isReportedChat, chatSession.friendMatched, let userID = self.chatSession?.realmCall?.user?.user_id, chatSession.isReportedByOther == false {
			self.showAfterReportFriendAlert(userID: userID)
		}else if let realmVideoCall = chatSession.realmVideoCall, let userID = realmVideoCall.initiator?.user_id, chatSession.isReportedChat, chatSession.isReportedByOther == false {
			/// it is a video call
			self.showAfterReportFriendAlert(userID: userID)
		}
		
		guard self.matchViewController != nil else {
			self.skipped(show: false)
			return
		}
		
		self.waitingText.isHidden = true
		self.connectText.isHidden = true
		
		chatSession.chat?.update(callback: nil)
		
		if chatSession.wasSkippable {
			self.resetFact()
		}
		if chatSession.response != .skipped && !chatSession.didConnect {
			self.skipped(show: false)
		}
		if startView.isHidden == true {
			self.start()
		}
		
		print("Consumed")
		let presentingViewController = self.matchViewController?.presentingViewController
		self.factTextView.text = self.nextFact
		let callViewController = self.matchViewController
		
		if chatSession.matchMode == .VideoMode && chatSession.hadAddTime == false {
			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}else if chatSession.matchMode == .TextMode && chatSession.isUnMuteSound == false,
			let connectTime = chatSession.connectTime,
			(Date.init().timeIntervalSince1970 - connectTime) <= 30.0 {
			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}else if let connectTime = chatSession.connectTime,
			(Date.init().timeIntervalSince1970 - connectTime) <= 30.0 {
			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}
		
		UIView.animate(withDuration: 0.3, animations: {
			callViewController?.isPublisherViewEnlarged = true
			callViewController?.view.layoutIfNeeded()
		}) { [unowned self] (success) in
			presentingViewController?.dismiss(animated: false) {
				self.addPublisherToView()
				UIView.animate(withDuration: 0.2, animations: {
					self.colorGradientView.alpha = 1.0
					presentingViewController?.view.alpha = 1.0
				}) { (Bool) in
					self.containerView.setNeedsLayout()
					self.matchViewController = nil
					
					if chatSession.chat?.sharedSnapchat == true, chatSession.chat?.theySharedSnapchat == true, UserDefaults.standard.bool(forKey: showRateAlertReason.addFriendJust.rawValue) == false {
						UserDefaults.standard.set(true, forKey: showRateAlertReason.addFriendJust.rawValue)
						self.showRateAlert(reason: .addFriendJust)
					} else if Configs.contiLogTimes() == 3,
						UserDefaults.standard.bool(forKey: showRateAlertReason.contiLoginThreeDay.rawValue) == false {
						UserDefaults.standard.set(true,forKey: showRateAlertReason.contiLoginThreeDay.rawValue)
						self.showRateAlert(reason: .contiLoginThreeDay)
					}
				}
			}
		}
		
		self.startFindingChats(forReason: "re-start")
	}
	/// Inserts HWCameraManager.shared().localPreviewView at the back of the ViewController's view and sets it's constraints.
	private func addPublisherToView() {
		self.view.insertSubview(HWCameraManager.shared().localPreviewView, at: 0)
		let viewsDict = ["view": HWCameraManager.shared().localPreviewView,]
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
		HWCameraManager.shared().localPreviewView.translatesAutoresizingMaskIntoConstraints = false
	}
	
	func chatSession(_ chatSession: ChatSession, callEndedWithError error: Error?) {
		IncomingCallManager.shared.dismissShowingNotificationForChatSession(chatSession)
		var timeout = false;
		if (self.connectText.isHidden == false) {
			timeout = true;
		}
		
		self.waitingText.isHidden = true
		self.connectText.isHidden = true
		if !chatSession.didConnect {
			if timeout {
				self.timeOut(show: chatSession.response != nil)
			}else {
				self.skipped(show: chatSession.response != ChatSession.Response.skipped && chatSession.auto_skip == false)
			}
		}
		let isCurrentSession = chatSession == self.chatSession
		// 如果还没进到房间内
		if chatSession.wasSkippable == false {
			self.lastChatSession = chatSession
		}else {
			self.lastChatSession = nil
		}
		self.chatSession = nil
		
		if !isCurrentSession {
			print("Error: It's strange for a session to be ending that we don't own.")
		}
		if error != nil {
			print("Error: Uh, oh! Unknown error occurred.")
		}
		
		self.startFindingChats(forReason: "receive-match")
	}
	
	func shouldShowConnectingStatus(in chatSession: ChatSession) {
		if self.presentedViewController == nil {
			self.waitingText.isHidden = true
			self.connectText.isHidden = false
		}
	}
	
	@IBAction func matchModeChanged(_ sender: MatchModeSwitch) {
		self.stopFindingChats(andDisconnect: false, forReason: "switch match mode")
		self.revokePrevMatchRequest {
			self.startFindingChats(forReason: "switch match mode")
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
	
	@IBAction func bananaButtonTapped(sender: Any) {
		self.showBananaDescription(isNotificationBool: false)
	}
	
	private func showBananaDescription(isNotificationBool: Bool) {
		guard let yesterdayString = self.yesterdayString, let addTimeString = self.addTimeString, let addFriendString = self.addFriendString, let equivalentString = self.equivalentString else {
			return
		}
		if isNotificationBool == false {
			UserDefaults.standard.setValue("", forKey: KillAppBananaNotificationTag)
		}
		
		self.stopFindingChats(andDisconnect: false, forReason: "show-banana-description")
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
		
		alert.addAction(UIAlertAction(title: "Cool", style: .cancel, handler: { [weak self]
			(UIAlertAction) in
			self?.startFindingChats(forReason: "show-banana-description")
		}))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func warnConnectionTimeout(in chatSession: ChatSession) {
		self.responseTimeoutCount = self.responseTimeoutCount + 1
		if self.responseTimeoutCount >= RemoteConfigManager.shared.match_autoskip_warncount {
			self.responseTimeoutCount = 0
			
			self.stopFindingChats(andDisconnect: false, forReason: "ignoring")
			let alert = UIAlertController(title: "👮‍♀️ Don't ignore people", message: "Make sure to skip or accept chats.", preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction(title: "Soz officer", style: .cancel, handler: {
				(UIAlertAction) in
				alert.dismiss(animated: true, completion: nil)
				self.startFindingChats(forReason: "ignoring")
			}))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func showRateAlert(reason: showRateAlertReason) {
		let rated = UserDefaults.standard.bool(forKey: "kHadRateBefore")
		if rated {return}
		UserDefaults.standard.set(true,forKey: "kHadRateBefore")
		if Configs.hadShowRateAlertToday() {return}
		
		self.stopFindingChats(andDisconnect: false, forReason: "rateapp")
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
	
	deinit {
		NotificationCenter.default.removeObserver(self)
		self.stopMatchRequest()
		self.bananaNotificationToken?.invalidate()
		self.unreadMessageNotificationToken?.invalidate()
		Socket.shared.isEnabled = false
	}
}

extension MainViewController : MessageObserver {
	
	func didReceiveTwopDefault(message: [String : Any]) {
		print("*** message = \(message)")
		
		let twopSocketModel = TwopSocketModel.twopSocketModel(dict: message as [String : AnyObject])
		
		switch twopSocketModel.msgTypeInt {
		case SocketDefaultMsgTypeEnum.unlock2p.rawValue: // unlock2p
			let currentUser = UserManager.shared.currentUser
			currentUser?.reload(completion: { (error) in
			})
		case SocketDefaultMsgTypeEnum.friendInvite.rawValue: // friendInvite
			let currentUser = UserManager.shared.currentUser
			currentUser?.reload(completion: { (error) in
			})
			
			self.getUnhandledFriendsRequestCountFunc() // 更新红点的值
		default:
			break
		}
	}
}

extension MainViewController {
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
}

// MARK: - loading view logic
extension MainViewController {
	
	func setupBananas() {
		self.numberFormatter.numberStyle = .decimal
		self.bananaNotificationToken = APIController.shared.currentUser?.observe { [weak self] (changes) in
			DispatchQueue.main.async {
				self?.updateBananas()
			}
		}
	}
	
	func setupFriendships() {
		// Predicates restricting which users come back (we don't want friendships as a result from blocks)
		let userId = APIController.shared.currentUser?.user_id ?? ""
		let isNotCurrentUser = NSPredicate(format: "user.user_id != \"\(userId)\"")
		let isInConversation = NSPredicate(format: "last_message_at != nil")
		let isNotBlocker = NSPredicate(format: "is_blocker == NO")
		let isNotBlocking = NSPredicate(format: "is_blocking == NO")
		let isUnreadConversation = NSPredicate(format: "last_message_read_at < last_message_received_at")
		
		let realm = try? Realm()
		self.friendships = realm?.objects(RealmFriendship.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
			isNotBlocker,
			isNotBlocking,
			isNotCurrentUser,
			isInConversation,
			isUnreadConversation
			]))
		self.updateFriendshipCount()
		
		self.unreadMessageNotificationToken = self.friendships?.observe { [weak self] (changes) in
			DispatchQueue.main.async {
				self?.updateFriendshipCount()
			}
		}
	}
	
	func updateFriendshipCount() {
		guard let unreadFriendships = self.friendships else {
			return
		}
		
		if unreadFriendships.count > 0 {
			self.chatButton.imageView?.image = #imageLiteral(resourceName: "FriendsButtonNotification")
		} else {
			self.chatButton.imageView?.image = #imageLiteral(resourceName: "FriendsButton")
		}
	}
	
	func updateBananas() {
		
		let bananaCount = APIController.shared.currentUser?.bananas.value ?? 0
		let formattedNumber = numberFormatter.string(from: NSNumber(value:bananaCount))
		self.bananaCountLabel.text = formattedNumber
		AnalyticsCenter.update(userProperty: ["current_banana": bananaCount])
		
		let bananaRect = formattedNumber?.boundingRect(forFont: self.bananaCountLabel.font, constrainedTo: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bananaCountLabel.frame.size.height))
		let bananaViewWidth = (bananaRect?.size.width)! + 64 // padding
		
		self.bananaViewWidthConstraint.constant = bananaViewWidth
		self.view.setNeedsLayout()
	}
	
	func setFactText(_ text: String) {
		self.factTextView.text = text
	}
	
	func start(fact: String) {
		self.isSkip = true
		self.setFactText(fact)
	}
	
	func listTree(tree: String) {
		if let curTree = APIController.shared.currentUser?.channels.first, tree == curTree.channel_id {
			self.chatSession?.common_tree = curTree.title!
			self.curCommonTree = curTree
			self.commonTreeTip.text = curTree.emoji
			self.commonTreeTip.isHidden = false
		}
	}
	
	func hideTreeLabels() {
		self.matchUserPhoto.isHidden = true
		self.commonTreeTip.isHidden = true
		self.loadingTextLabel.setDefaultTicks()
	}
	
	func timeOut(show: Bool = true) {
		DispatchQueue.main.async {
			self.start()
			if show {
				self.skippedText.layer.opacity = 1.0
			}
			self.skippedText.text = "Time out!!"
			self.factTextView.text = self.nextFact
			UIView.animate(withDuration: 1.5, animations: {
				self.skippedText.layer.opacity = 0.0
			})
			self.hideTreeLabels()
		}
	}
	
	func skipped(show: Bool = true) {
		DispatchQueue.main.async {
			self.start()
			if show {
				self.skippedText.layer.opacity = 1.0
			}
			self.skippedText.text = "Skipped!!"
			self.factTextView.text = self.nextFact
			UIView.animate(withDuration: 1.5, animations: {
				self.skippedText.layer.opacity = 0.0
			})
			self.hideTreeLabels()
		}
	}
	
	func start() {
		if let onboardingFactText = APIController.shared.currentExperiment?.onboarding_fact_text, Achievements.shared.minuteMatches == 0, APIController.shared.currentExperiment?.onboarding_video.value == true {
			self.setFactText(onboardingFactText)
		}
		
		self.isSkip = false
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
			
			self.stopFindingChats(andDisconnect: false, forReason: "delete_report_friend")
			
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 1.0)) {
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
}

//extension MainViewController: SlideViewManager {
//	func shouldShowNotification() -> Bool {
//		return (self.presentedViewController?.presentedViewController as? ChatViewController) == nil
//	}
//
//	func shouldExecuteNotification() -> Bool {
//		return self.chatSession?.status != .connected
//	}
//}
