
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
import Social
import MediaPlayer
import RealmSwift
import MessageUI
import CoreLocation
import UserNotifications

enum ReportType: Int {
	case mean = 9
	case nudity = 10
	case violence = 11
	case meanOrBully = 12
	case drugsOrWeapon = 13
	case ageOrGender = 14
	case other = 15
}

enum AutoScreenShotType: String {
	case match_5s = "match_5s"
	case match_disconnec = "match_disconnec"
}

let treeLabelWidth:CGFloat = 48.0

typealias MatchViewController = UIViewController & MatchViewControllerProtocol

class MainViewController: SwipeableViewController, UITextFieldDelegate, SettingsHashtagCellDelegate, CLLocationManagerDelegate, MFMessageComposeViewControllerDelegate, CallViewControllerDelegate, ChatSessionLoadingDelegate, IncomingCallManagerDelegate, FacebookViewControllerDelegate {
	
	internal func showAlert(alert: UIAlertController) {
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBOutlet var bonusBananasButton: BigYellowButton!
	@IBOutlet weak public var acceptButton: BigYellowButton?
	
	@IBOutlet weak var loadingContentView: MakeUIViewGreatAgain!
     
     
	@IBOutlet weak var pageViewIndicator: UIPageControl!
	@IBOutlet weak var arrowButton: BigYellowButton!
	@IBOutlet weak var bottomArrowPadding: NSLayoutConstraint!
	
	@IBOutlet weak public var skipButton: BigYellowButton!
	
	@IBOutlet var inviteFriendsView: UIView!
	@IBOutlet weak public var settingsButton: BigYellowButton!
	@IBOutlet weak var chatButton: BigYellowButton!
	
	@IBOutlet weak var matchModeContainer: UIView!
	@IBOutlet weak var matchModeTip: UILabel!
	@IBOutlet weak var matchModeEmojiLeft: UILabel!
	@IBOutlet weak var matchModeEmojiRight: UILabel!
	@IBOutlet weak public var loadingTextLabel: LoadingTextLabel!
	@IBOutlet var skippedTextBottomConstraint: NSLayoutConstraint!
	@IBOutlet var skippedText: UILabel!
	@IBOutlet var waitingText: UILabel!
    @IBOutlet weak var connectText: UILabel!
    
	@IBOutlet weak var matchModePopup: UIView!
	@IBOutlet weak var matchModeLabel: UILabel!
	@IBOutlet weak var matchModeSwitch: MatchModeSwitch!
	@IBOutlet weak var bananaView: BigYellowButton!
	@IBOutlet weak var bananaCountLabel: UILabel!
	@IBOutlet weak var bananaViewWidthConstraint:NSLayoutConstraint!
	@IBOutlet weak var colorGradientView:UIView!
	
	weak var matchViewController: MatchViewController?
	var incomingCallNotificationToken:NotificationToken?
	var callNotification:CallNotificationView?
	var signedOut = false
	var hadRegiNoti = false
	var mySkip = false
	var incomingCallId:String?
	var incomingCallBio:String?
	var nextSessionToPresent:ChatSession?
	var currentUserNotifcationToken:NotificationToken?
	var currentExperimentNotifcationToken:NotificationToken?
	var channels: Results<RealmChannel>?
	
	var waitingForFriendToken:NotificationToken?
	/// After a friendship is made, if there is no snapchat name, we wait for the user id to come down from the socket and push to their chat page
	var waitingForFriendUserId:String? {
		didSet {
			guard let friendUserId = self.waitingForFriendUserId, friendUserId != oldValue else {
				return
			}
			if oldValue != nil {
				// Clear old attempt.
				stopWaitingForFriend()
			}
			self.stopFindingChats(andDisconnect: false, forReason: "waiting-friend")
			let realm = try? Realm()
			var didFindFriend = false
			
			DispatchQueue.main.asyncAfter(deadline: .after(seconds: 5)) {
				if !didFindFriend {
					self.stopWaitingForFriend()
				}
			}
			
			self.waitingForFriendToken = realm?.objects(RealmFriendship.self).filter("user.user_id = \"\(friendUserId)\"").addNotificationBlock({ [weak self] (changes) in
				guard let friendship = realm?.objects(RealmFriendship.self).filter("user.user_id = \"\(friendUserId)\"").first, let friendshipId = friendship.friendship_id else {
					return
				}
				didFindFriend = true
				(self?.swipableViewControllerToPresentOnLeft as? FriendsViewController)?.initialConversation = friendshipId
				self?.swipableViewControllerToPresentOnLeft.then { self?.present($0, animated: true, completion: nil) }
				self?.stopWaitingForFriend()
				self?.startFindingChats(forReason: "waiting-friend")
			})
		}
	}
	private func stopWaitingForFriend() {
		self.waitingForFriendToken?.stop()
		self.waitingForFriendToken = nil
		self.startFindingChats(forReason: "waiting-friend")
	}
	
	/**
	Required by `SettingsHashtagCellDelegate` and called when hashtag editing completes to set the preferred hashtag settings on `MainViewController`.
	- Parameters:
	- id: the hashtag id
	- tag: the hashtag text
	*/
	internal func selectedHashtag(id: String, tag: String) {
		hashtagID = id
		hashtag = tag
	}
	
	func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
		result: MessageComposeResult) {
		self.dismiss(animated: true, completion: {
			
		})
	}
	
	internal func statusChanged(isSkip: Bool) {
		if isSkip {
			// If user is able to accept/skip call, do not allow them to swipe between views
			self.isSwipingEnabled = false
		} else {
			// Conversely, enable swipe interaction under normal circumstances
			self.isSwipingEnabled = true
		}
	}
	
	@IBAction func settingsButtonTapped(sender: Any) {
		self.present(self.swipableViewControllerToPresentOnRight!, animated: true, completion: nil)
	}
	
	@IBAction func chatButtonTapped(sender: Any) {
		self.present(self.swipableViewControllerToPresentOnLeft!, animated: true, completion: nil)
	}
	
	@IBAction func arrowButtonTapped(sender: Any) {
		self.present(self.swipableViewControllerToPresentOnBottom!, animated: true, completion: nil)
	}
	
	@IBOutlet var containerView: UIView!
	enum MatchingMode:String {
		case discover = "discover"
		case friends = "friends"
	}
	
	// MARK: Variables
	var dimView:UIView?
	
	// count of chats the user timed out before accept/declining
	var callsInSession = 0
	var matchingMode:MatchingMode = .discover
	var chatSession: ChatSession?
	/// The hashtag that the user has selected in settings. This is not persisted to disk anywhere.
	var hashtag : String?
	/// The ID of the currently selected hashtag. Returned by server and sent with chat requests.
	var hashtagID : String?
	/// Channels that the user has in common with the current skippable call
	var mutualChannels = Array<RealmChannel>()
	var inviteFriendsViewController: FacebookViewController?
	var appeared = false
	var viewsHiddenWhenShowingSettings = [UIButton]()
	var nextFact = APIController.shared.currentExperiment?.initial_fact_discover ?? ""
	var isFindingChats = false {
		didSet {
			self.loadingTextLabel?.isTicking = self.isFindingChats
			if self.isFindingChats {
				UIApplication.shared.isIdleTimerDisabled = true
			} else {
				UIApplication.shared.isIdleTimerDisabled = false
			}
		}
	}
	
	fileprivate var friendships:Results<RealmFriendship>?
	var pendingFactText:String?
	var isSkip:Bool = false {
		didSet {
			self.statusChanged(isSkip: isSkip)
			
			if isSkip {
				self.skipButton?.isHidden = false
				self.acceptButton?.isHidden = false
				self.matchModeContainer.isHidden = false
				self.arrowButton.isHidden = true
				self.settingsButton.isHidden = true
				self.chatButton.isHidden = true
				self.pageViewIndicator.isHidden = true
				self.inviteFriendsView.isHidden = true
				self.bananaView.isHidden = true
				self.matchModeSwitch.isHidden = true
				self.matchModePopup.isHidden = true
				
				let textMode = self.chatSession?.textMode ?? false
				self.acceptButton?.backgroundColor = textMode ? UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1.0, alpha: 1.0) : UIColor.init(red: 76.0 / 255.0, green: 71.0 / 255.0, blue: 1.0, alpha: 1.0)
				self.matchModeEmojiLeft.text = textMode ? "💬" : "🐵"
				self.matchModeEmojiRight.text = textMode ? "💬" : "🐵"
				self.matchModeTip.text = textMode ? "Text Chat" : "Video Chat"
				
				// dismiss if showing
				if let messageNotificationView = NotificationManager.shared.showingNotification {
					if messageNotificationView is RatingNotificationView {
						messageNotificationView.dismiss()
					} else {
						UIApplication.shared.keyWindow?.bringSubview(toFront: messageNotificationView)
					}
				}
			} else {
				self.matchModeContainer.isHidden = true
				self.acceptButton?.isHidden = true
				self.skipButton.isHidden = true
				self.arrowButton.isHidden = false
				self.settingsButton.isHidden = false
				self.chatButton.isHidden = false
				self.pageViewIndicator.isHidden = false
				self.inviteFriendsView.isHidden = false
				self.bananaView.isHidden = false
				self.matchModeSwitch.isHidden = false
			}
		}
	}
	
	/// True if the call was just skipped and the UI elements have adjusted but there may still be background work to complete the chat consumption.
	var didSkip = false
	var isLoading = false
	var isTicking = true {
		didSet {
			self.loadingTextLabel?.isTicking = self.isTicking
		}
	}
	
	@IBOutlet var factTextView: MakeTextViewGreatAgain!
	fileprivate let numberFormatter = NumberFormatter()
	fileprivate var currentTick = 0
	fileprivate var timer:Timer?
	fileprivate var bananaNotificationToken:NotificationToken?
	fileprivate var unreadMessageNotificationToken:NotificationToken?
	
	var hideSkipScreenWhen = DispatchTime.now() + (Double(4.0))
	
	let locationManager = CLLocationManager()
	
	func cancelSwipeWithTargetOpacity(opacity : CGFloat) {
		UIView.animate(withDuration: 0.3, animations: {
			self.view.layoutIfNeeded()
			self.containerView.alpha = opacity
		})
	}
	
	// MARK: UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = Colors.purple
		self.matchModePopup.isHidden = true
		self.matchModePopup.layer.cornerRadius = 12
		self.matchModePopup.alpha = 0
		
		self.matchModeSwitch.isHidden = !RemoteConfigManager.shared.text_chat_mode
		
		NotificationManager.shared.viewManager = self
		NotificationManager.shared.chatSessionLoadingDelegate = self
		IncomingCallManager.shared.delegate = self
		self.swipableViewControllerToPresentOnRight = UIStoryboard(name: "Channels", bundle: .main).instantiateInitialViewController() as? SwipeableViewController
		self.swipableViewControllerToPresentOnLeft = UIStoryboard(name: "Chat", bundle: .main).instantiateInitialViewController() as? SwipeableViewController
		self.swipableViewControllerToPresentOnBottom = UIStoryboard(name: "Settings", bundle: .main).instantiateInitialViewController() as? SwipeableViewController
		dimView = UIView(frame: self.containerView.frame)
		dimView?.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
		
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
		
		self.startUpdatingLocation()
		
		self.resetFact()
		
		self.addPublisherToView()
		
		guard let channelsVC = self.swipableViewControllerToPresentOnRight as? ChannelsViewController
			else {
				return
		}
     
     let realm = try? Realm()
     self.channels = realm?.objects(RealmChannel.self).filter(NSPredicate(format: "is_active = true")).sorted(byKeyPath: "channel_id")
     
     if self.channels?.count == 0 {
          RealmChannel.fetchAll { (result: JSONAPIResult<[RealmChannel]>) in
               switch result {
               case .success(_):
                    self.channels = realm?.objects(RealmChannel.self).filter(NSPredicate(format: "is_active = true"))
                    break
               case .error(let error):
                    error.log()
               }
          }
     }
		
		guard let selectedChannels = APIController.shared.currentUser?.channels else {
			return
		}
		
		if selectedChannels.isEmpty {
			RealmChannel.fetchAll { (result: JSONAPIResult<[RealmChannel]>) in
				switch result {
				case .success(_):
					let realm = try? Realm()
					guard let channel = realm?.object(ofType: RealmChannel.self, forPrimaryKey:
						"1") else {
							print("Error: could not get general channel from Realm.")
							return
					}
					
					let list = List<RealmChannel>()
					list.append(channel)
					
					channelsVC.updateChannels(selectedChannels: list)
				case .error(let error):
					error.log()
				}
				
			}
		}
		
		
		// from loadingView
		self.skipButton?.setTitle(APIController.shared.currentExperiment?.skip_text, for: .normal)
		
		self.setupBananas()
		self.updateBananas()
		self.setupFriendships()
		
		self.factTextView.textContainerInset = .zero
		self.skippedText.layer.opacity = 0.0
		Socket.shared.isEnabled = true
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
	
	var stopFindingReasons = [String]()
	func startFindingChats(forReason: String) {
		let reason = self.stopFindingReasons.removeObject(object: forReason)
		print("Started finding \(forReason):  \(reason)")
		if self.stopFindingReasons.count == 0 {
			isFindingChats = true
		} else {
			print("Still not finding because: \(stopFindingReasons.split(separator: ","))")
		}
		if self.chatSession == nil {
			self.getNewSession()
		}
		
		// ticker = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
	}
	func stopFindingChats(andDisconnect: Bool, forReason: String) {
		print("Stopped finding: \(forReason)")
		self.chatRequest?.cancel()
		self.stopFindingReasons.append(forReason)
		if self.stopFindingReasons.count == 1 {
			isFindingChats = false
		}
		if andDisconnect {
			self.chatSession?.disconnect(.consumed)
		}
	}
	
	var movingToBackground = false
	
	func appMovedToBackground() {
		self.hashtag = ""
		self.stopFindingChats(andDisconnect: false, forReason: "application-status")
		Socket.shared.isEnabled = false
	}
	
	func appMovedToForeground() {
		Socket.shared.isEnabled = true
		self.checkCamAccess()
		self.startFindingChats(forReason: "application-status")
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
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	override var prefersStatusBarHidden: Bool {
		return false
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
     APIController.trackSignUpFinish()
     if !self.hadRegiNoti {
          if Achievements.shared.promptedNotifications {
               self.hadRegiNoti = true
               UIApplication.shared.registerForRemoteNotifications()
          }else {
               self.checkNotifiPermission()
          }
     }
     
     if APIController.shared.currentUser?.first_name == nil || APIController.shared.currentUser?.birth_date == nil {
          self.present(self.storyboard!.instantiateViewController(withIdentifier: (self.view.window?.frame.height ?? 0.0) < 667.0 ? "editAccountSmallVC" : "editAccountVC"), animated: true, completion: nil)
     }
		
		// Tell bonus bananas button to hide if we have unlocked the achievement
		self.updateInvitationButton()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		// Step 2: As the view comes into the foreground, begin the connection process.
		if !appeared {
			appeared = true
		}
		
		print("Start finding chats")
		self.stopFindingChats(andDisconnect: true, forReason: "location-services")
		self.requestLocationPermissionIfUnavailable() // This will cause the thred to hang so we still need to toggle chat finding to cancel any existing requests.
		self.startFindingChats(forReason: "location-services")
		self.checkCamAccess()
		
		self.view.layoutIfNeeded()
		
		self.currentUserNotifcationToken = APIController.shared.currentUser?.addNotificationBlock({ (change) in
			self.updateInvitationButton()
		})
		
		self.currentExperimentNotifcationToken = APIController.shared.currentExperiment?.addNotificationBlock({ (change) in
			self.updateInvitationButton()
		})
	}
	
	func updateInvitationButton() {
		guard Achievements.shared.authorizedFacebookForBonusBananas == false else {
			self.bonusBananasButton.isHidden = true
			return
		}
		guard APIController.shared.currentExperiment?.facebook_app_id != nil else {
			self.bonusBananasButton.isHidden = true
			return
		}
		
		guard APIController.shared.currentUser?.facebook_friends_invited.value == nil else {
			self.bonusBananasButton.isHidden = true
			return
		}
		
		self.bonusBananasButton.isHidden = false
	}
	
	func checkCamAccess() {
		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) != AVAuthorizationStatus.authorized {
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
					self.stopFindingChats(andDisconnect: true, forReason: "camera-access")
					self.present(alert, animated: true, completion: nil)
				}
			})
		}
		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) !=  AVAuthorizationStatus.authorized {
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
					self.stopFindingChats(andDisconnect: true, forReason: "mic-access")
					self.present(alert, animated: true, completion: nil)
				}
			})
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillAppear(animated)
///		self.stopFindingChats(andDisconnect: true, forReason: "view-appearance")
	}
	
	
	/// Displays invite friends messaging dialog.
	///
	/// - Parameter sender: the instance of `BigYellowButton` that triggered the action
	@IBAction func showInviteFromMessagesViewController(sender:BigYellowButton) {
		let smsVC = MFMessageComposeViewController()
		smsVC.body = APIController.shared.currentExperiment?.sms_invite_friends
		smsVC.messageComposeDelegate = self
		
		self.present(smsVC, animated: true, completion: nil)
	}
	
	
	/// Displays an alert showing the users the current ways of getting bonus bananas.
	///
	/// - Parameter sender: the instance of `BigYellowButton` that triggered the action
	@IBAction func showBonusBananasAlert(sender:BigYellowButton) {
		let bonusBananasAlert = UIAlertController(title: "🎉 Get bonus bananas", message: "Get bonus bananas by sharing Monkey with friends by doing the tasks below.", preferredStyle: .alert)
		
		bonusBananasAlert.addAction(UIAlertAction(title: "Link Facebook = 🍌1000", style: .default, handler: {
			(UIAlertAction) in
			self.inviteFacebookFriends()
			bonusBananasAlert.dismiss(animated: true, completion: nil)
		}))
		
		bonusBananasAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
			(UIAlertAction) in
			bonusBananasAlert.dismiss(animated: true, completion: nil)
		}))
		
		self.present(bonusBananasAlert, animated: true, completion: nil)
	}
	
	
	/// Opens FacebookViewController -- called from the 'Bonus Bananas Popup'
	func inviteFacebookFriends() {
		self.inviteFriendsViewController = FacebookViewController()
		self.inviteFriendsViewController?.delegate = self
		
		guard let inviteFriendsViewController = self.inviteFriendsViewController else {
			return
		}
		inviteFriendsViewController.login(controller: self)
	}
	
	/**
	Completion delegate method for FacebookViewController, simply releases the reference to FacebookViewController, releasing it from memory.
	*/
	func loginCompleted(facebookViewController: FacebookViewController) {
		
	}
	
	func invitesCompleted(facebookViewController: FacebookViewController) {
		self.inviteFriendsViewController = nil
	}
	
	@IBAction func acceptButtonTapped(sender: Any) {
		
        MKMatchManager.shareManager.afmCount = 0
		self.chatSession?.accept()
		self.skipButton?.isHidden = true
		self.acceptButton?.isHidden = true
		
     if let chatSessionReady = self.chatSession?.matchUserDidAccept {
          if chatSessionReady {
               self.connectText.isHidden = false
               AnaliticsCenter.log(event: .matchConnect)
          }else {
               self.waitingText.isHidden = false
          }
     }
     
		UIView.animate(withDuration: 0.3, animations: {
			self.acceptButton?.isHidden = true
		})
	}
	
	private func resetFact() {
		if self.matchingMode == .discover {
			self.setFactText(self.nextFact)
		}
	}
     
     
     func checkNotifiPermission(){
          if #available(iOS 10.0, *) {
               let center = UNUserNotificationCenter.current()
               DispatchQueue.main.async {
                    center.getNotificationSettings(completionHandler: { (setting) in
                         if setting.authorizationStatus == UNAuthorizationStatus.authorized {
                              DispatchQueue.main.async {
                                   UIApplication.shared.registerForRemoteNotifications()
                                   self.hadRegiNoti = true
                              }
                         }
                    })
               }
          }else{
               if UIApplication.shared.isRegisteredForRemoteNotifications {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.hadRegiNoti = true
               }
          }
     }
	
	@IBAction func skipButtonTapped(sender: Any) {
        MKMatchManager.shareManager.afmCount = 0
     self.mySkip = true
		self.resetFact()
		self.chatSession?.response = .skipped
		self.chatSession?.chat?.skipped = true
     self.hideTreeLabels()
     //  the connection may not created , this will cause connection destroy callback never call , and it will not going to find next chat
//          self.chatSession?.disconnect(.consumed)
		self.start()
	}
	
	internal func factTextTapped() {
		self.present(self.storyboard!.instantiateViewController(withIdentifier: "onboardingVideoVC"), animated: true) { (Bool) in
			self.startFindingChats(forReason: "onboarding-video")
		}
		self.stopFindingChats(andDisconnect: true, forReason: "onboarding-video")
	}
	
	private func selectedMode(_ newMatchingMode: MatchingMode) {
		guard self.matchingMode != newMatchingMode else {
			self.startFindingChats(forReason: "mode-selection")
			return
		}
		self.resetFact()
		self.chatSession?.disconnect(.consumed)
		self.matchingMode = newMatchingMode
		self.chatSession?.disconnect(.consumed)
		self.startFindingChats(forReason: "mode-selection")
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
	
	func requestPresentation(of alertController: UIAlertController, from view: UIView) {
		self.present(alertController, animated: true, completion: nil)
	}
	var chatRequest: JSONAPIRequest?
	var gettingNewSession = false
	var sessionIndex = 0 // used to make sure we don't run more than one DispatchQueue.main.asyncAfter
	
	var shouldLogFirstMatchSuccess = false
	
	func getNewSession() {
		// log first match request event
		if shouldLogFirstMatchSuccess {
			shouldLogFirstMatchSuccess = false
			
			UserDefaults.standard.set(false, forKey: "MonkeyLogEventFirstMatchSuccess")
			UserDefaults.standard.synchronize()
		}
		
		if UserDefaults.standard.bool(forKey: "MonkeyLogEventFirstMatchRequest") {
			let currentUser = APIController.shared.currentUser
			
			let eventParameters:[String: Any] = [
				"user_gender": currentUser?.show_gender ?? "male",
				"user_age": currentUser?.age.value ?? 0,
				]
			AnaliticsCenter.log(withEvent: .matchFirstRequest, andParameter: eventParameters)
			
			UserDefaults.standard.set(false, forKey: "MonkeyLogEventFirstMatchRequest")
			UserDefaults.standard.synchronize()
			
			shouldLogFirstMatchSuccess = true
		}
		
		guard self.nextSessionToPresent == nil else {
			self.chatSession = self.nextSessionToPresent
			self.nextSessionToPresent = nil
			self.chatSession?.accept() // will trigger presentcallvc
			return
		}
		if (gettingNewSession || !isFindingChats) {
			print("Already finding because gettingNewSession:\(gettingNewSession) or isFindingChats:\(isFindingChats)")
			return
		}
		guard self.chatSession == nil else {
			print("Error: Retrieving new session before finished with old session. Typically caused by unbalanced calls to stop/start finding chats.")
			return
		}
		gettingNewSession = true
		print("Getting a new session")
		if !self.isFindingChats {
			print("Not finding chats")
			self.gettingNewSession = false
			return
		}
		
		let parameters:[String:Any] = [
			"data": [
				"type": "chats",
				"attributes": [
					"matching_mode": self.matchingMode.rawValue,
					"match_mode": Achievements.shared.selectMatchMode?.rawValue ?? MatchMode.VideoMode.rawValue,
				]
			]
		]
		
		self.chatRequest = RealmCall.create(parameters: parameters) { (result:JSONAPIResult<[RealmCall]>) in
			let chatRequest = self.chatRequest
			self.chatRequest = nil
			print("Chat request completed")
			self.gettingNewSession = false
			guard self.isFindingChats == true else {
				print("Not finding chats")
				return // stopped finding chats before request finished
			}
			switch result {
			case .success(let calls):
				guard let call = calls.first else {
					print("Error: RealmCall.create succeeded but no calls were returned")
					self.getNewSession()
					return
				}
				guard let jsonAPIDocument = chatRequest?.responseJSONAPIDocument else {
					print("Error: did not get a responseJSONAPIDocument from RealmCall.create")
					self.getNewSession()
					return
				}
				
				if let meta = jsonAPIDocument.meta, let nextFact = meta["next_fact"] as? String {
					self.nextFact = nextFact
				}
				
				guard let sessionId = call.session_id, let chatId = call.chat_id, let token = call.token else {
					print("Error: RealmCall object did not return with sufficient data to create a chatSession")
					self.getNewSession()
					return
				}
				
				var bio = "Connecting"
				if let includeds = jsonAPIDocument.included,
					let included = includeds.first
				{
					if let attribute = included.attributes {
						if let gender = attribute["gender"] as? String,
							let first_name = attribute["first_name"] as? String,
							let age = attribute["age"] as? Int,
							let location = attribute["location"] as? String {
							let showGender = (gender == "male") ? "He" : "She"
							let attributes: [RealmUser.Attribute] = [
								.first_name(first_name),
								.age(age),
								.gender(gender),
								]
							call.user?.update(attributes: attributes, completion: { ( _) in
								print("update match user info error")
							})
							bio = "Say hi to \(first_name)! \(showGender) is \(String(describing: age)) and from \(location)."
						}
						
						if let channels = attribute["channels"] as? [String] {
							self.listTrees(trees: channels)
						}
					}
				}else if let callBio = call.bio, let convertBio = callBio.removingPercentEncoding {
					bio = convertBio
				}
				
				APIController.trackMatchRecieve()
				self.chatSession = ChatSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId, chat: Chat(chat_id: chatId, first_name: call.user?.first_name, profile_image_url: call.user?.profile_photo_url, user_id: call.user?.user_id, match_mode: call.match_mode), token: token, loadingDelegate: self, isDialedCall: false)
				let textMode = (self.chatSession?.chat?.match_with_mode == .TextMode)
				self.chatSession?.textMode = textMode
				
				self.start(fact: bio)
			case .error(let error):
				error.log(context:"Create (POST) a matched call")
				let statusCode = error.status
				guard statusCode != "401" else {
					self.signOut()
					return
				}
				guard statusCode != "403" else {
					if (error.message == "You are old") { // was error["title"] before so may need to be investigated
						self.present((self.storyboard!.instantiateViewController(withIdentifier: "oldVC")), animated: true) { (Bool) in
							self.startFindingChats(forReason: "old-vc")
						}
						self.stopFindingChats(andDisconnect: true, forReason: "old-vc")
					} else {
						self.present((self.storyboard!.instantiateViewController(withIdentifier: "bannedVC")), animated: true) { (Bool) in
							self.startFindingChats(forReason: "banned-vc")
						}
						self.stopFindingChats(andDisconnect: true, forReason: "banned-vc")
					}
					return
				}
				let meta = error.meta
				if let fact = meta?["fact"] as? String {
					self.nextFact = fact
					self.resetFact()
				}
				
				if let errorMessage = (meta?["alert_message_text"] as? String) {
					let alert = UIAlertController(title: (meta?["alert_title_text"] as? String) ?? "Status Error", message: errorMessage, preferredStyle: .alert)
					if (meta?["alert_disable_retry"] as? Bool) != true {
						alert.addAction(UIAlertAction(title: (meta?["alert_retry_text"] as? String) ?? "Retry", style: .cancel, handler: {
							(UIAlertAction) in
							alert.dismiss(animated: true, completion: nil)
							self.getNewSession()
						}))
					}
					self.present(alert, animated: true, completion: nil)
				} else if (meta?["should_retry"] as? Bool) == true {
					print("Retrying")
					self.getNewSession()
					return
				}
				if error.code.rawValue == "-999" {
					if self.isFindingChats {
						self.getNewSession()
					}
					print("Cancelled finding chat.")
					return
				}
				self.getNewSession()
			}
		}
	}
	
	func signOut() {
		guard self.signedOut == false else {
			return
		}
		
		self.signedOut = true
		
		RealmDataController.shared.deleteAllData() { (error) in
			guard error == nil else {
				error?.log()
				return
			}
			APIController.authorization = nil
			UserDefaults.standard.removeObject(forKey: "user_id")
			Apns.update(callback: nil)
			
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	func presentCallViewController(for chatSession:ChatSession) {
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
		if self.callNotification != nil {
			self.callNotification?.dismiss()
			self.callNotification = nil
		}
		
		UIView.animate(withDuration: 0.3, animations: {
			if !(viewController is MainViewController) {
				viewController.view.alpha = 0.0
			}
			self.colorGradientView.alpha = 0.0
		}) { (Bool) in
			var matchModeId = "callVC"
			if (self.chatSession?.chat?.match_with_mode == .TextMode) {
				matchModeId = "textModeVC"
				print("Get textModeVC")
			}else {
				print("Get videoModeVC")
			}
			
			let matchViewController = self.storyboard?.instantiateViewController(withIdentifier: matchModeId) as! MatchViewController
			self.matchViewController = matchViewController
			matchViewController.chatSession = chatSession
			chatSession.callDelegate = matchViewController
			
			self.callsInSession += 1
			Achievements.shared.totalChats += 1
			viewController.present(matchViewController, animated: false, completion: nil)
		}
	}
	
	func consumeFromConnected() {
		let showMonkeyChatConsumeCount = UserDefaults.standard.integer(forKey: "MKShowMonkeyChatCountConsumeChat")
		let lastShowTime = UserDefaults.standard.double(forKey: "MKShowMonkeyChatTimeConsumeChat")
		let lastShowDate = Date.init(timeIntervalSince1970: lastShowTime)
		let monkeychatScheme = URL.init(string: Environment.MonkeyChatScheme)
		let monkeychatUrl = APIController.shared.currentExperiment?.monkeychat_link
     let monkeychatDes = APIController.shared.currentExperiment?.mc_invite_desc ?? "Check out our new app Monkey Chat, it's awesome, just trust"
     let monkeychatConfirm = APIController.shared.currentExperiment?.mc_invite_btn_pos_text ?? "Try it"
	    if monkeychatUrl != nil && showMonkeyChatConsumeCount < 3 && lastShowDate.compare(.isToday) == false && UIApplication.shared.canOpenURL(monkeychatScheme!) == false {
			 UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "MKShowMonkeyChatTimeConsumeChat")
			 UserDefaults.standard.set(showMonkeyChatConsumeCount + 1, forKey: "MKShowMonkeyChatCountConsumeChat")
		
			let controller = UIAlertController(title: nil, message: monkeychatDes, preferredStyle: .alert)
			let monkeychat = UIAlertAction(title: monkeychatConfirm, style: .default) { (action) in
				UIApplication.shared.openURL(URL.init(string: monkeychatUrl!)!)
			}
			controller.addAction(monkeychat)
			
			let cancel = UIAlertAction(title: "No trust", style: .cancel, handler: nil)
			controller.addAction(cancel)
		
			 DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 0.5)) {
				 self.present(controller, animated: true, completion: nil)
			 }
	  	}
	}
	
	/// Animateable property to show and hide navigation elements
	var elementsShouldHide:Bool? {
		didSet {
			guard let shouldHide = self.elementsShouldHide else {
				return
			}
			let alpha:CGFloat = shouldHide ? 0 : 1
			self.chatButton.alpha = alpha
			self.settingsButton.alpha = alpha
			self.inviteFriendsView.alpha = alpha
			self.bananaView.alpha = alpha
			self.arrowButton.alpha = alpha
			self.loadingTextLabel.alpha = alpha
			self.factTextView.alpha = alpha
			self.matchModeSwitch.alpha = alpha
			self.matchModePopup.alpha = alpha
			self.matchModeContainer.alpha = alpha
		}
	}
	
	func dismissCallViewController(for chatSession: ChatSession) {
        EffectsCoordinator().effects.removeAll()
     if chatSession.isReportedChat , chatSession.friendMatched , let userID = chatSession.chat?.user_id {
          if let friendShipID = FriendsViewModel().friendships?.filter("user.user_id = \(userID)").last?.friendship_id {
               let alert = UIAlertController(title: nil, message: "Do you want to remove this user in your friend list?", preferredStyle: .actionSheet)
               let remove = UIAlertAction.init(title: "Remove", style: .default, handler: { (action) in
                    JSONAPIRequest(url: "\(Environment.baseURL)/api/\(APIController.shared.apiVersion)/friendships/\(friendShipID)", method: .patch, parameters: [
                         "data": [
                              "id": friendShipID,
                              "type": "friendships",
                         ],
                         ], options: [
                              .header("Authorization", APIController.authorization),
                              ]).addCompletionHandler { (response) in
                                   
                              }
                    self.startFindingChats(forReason: "delete_report_friend")
               })
               
               
               let cancel = UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
                    self.startFindingChats(forReason: "delete_report_friend")
               })
               
               alert.addAction(remove)
               alert.addAction(cancel)
               
               self.stopFindingChats(andDisconnect: false, forReason: "delete_report_friend")
               self.present(alert, animated: true)
          }
     }
     
		guard self.matchViewController != nil else {
			self.skipped()
			return
		}
     
        self.waitingText.isHidden = true
        self.connectText.isHidden = true
		//
		print("Disconnecting event fired")
		self.start()
		
		chatSession.chat?.update(callback: nil)
		
		if chatSession.wasSkippable {
			self.resetFact()
		}
		if chatSession.response != .skipped && !chatSession.didConnect {
			self.skipped()
		}
		print("Consumed")
		let presentingViewController = self.matchViewController?.presentingViewController
		self.factTextView.text = self.nextFact
		let callViewController = self.matchViewController
		if chatSession.hadAddTime == false {
			self.matchViewController?.autoScreenShotUpload(source: .match_disconnec)
		}
		self.timer?.fireDate = Date.distantFuture
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
					
					if chatSession.shouldShowRating == true {
						self.stopFindingChats(andDisconnect:false, forReason:"rating-notification")
						NotificationManager.shared.showRatingNotification(chatSession) { [weak self] in
							self?.startFindingChats(forReason: "rating-notification")
						}
					}
				}
			}
		}
	}
	/// Inserts MonkeyPublisher.shared.view at the back of the ViewController's view and sets it's constraints.
	private func addPublisherToView() {
		self.view.insertSubview(MonkeyPublisher.shared.view, at: 0)
		let viewsDict = ["view": MonkeyPublisher.shared.view,]
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
		MonkeyPublisher.shared.view.translatesAutoresizingMaskIntoConstraints = false
	}
	func chatSession(_ chatSession: ChatSession, callEndedWithError error:Error?) {
		IncomingCallManager.shared.dismissShowingNotificationForChatSession(chatSession)
     if (self.connectText.isHidden == false) && (error != nil) {
          AnaliticsCenter.log(event: .matchConnectTimeOut)
     }
     
        self.waitingText.isHidden = true
        self.connectText.isHidden = true
		if !chatSession.didConnect {
			self.skipped()
		}
		let isCurrentSession = chatSession == self.chatSession
		if !isCurrentSession {
			print("Error: It's strange for a session to be ending that we don't own.")
		}
		self.chatSession = nil
		
		if error != nil {
			print("Error: Uh, oh! Unknown error occurred.")
			self.getNewSession()
			return
		} else if chatSession.friendMatched == true {
			if let username = chatSession.theirSnapchatUsername {
				let snapchatURL = URL(string: chatSession.subscriberData?["u"] ?? "snapchat://add/\(username)")
				if UIApplication.shared.canOpenURL(snapchatURL!) {
					print("Opening snapchat \(username)")
					UIApplication.shared.openURL(snapchatURL!)
				}
			}
			if let theirUserId = chatSession.chat?.user_id {
				self.waitingForFriendUserId = theirUserId
			}
			// Setting this will open the user's chat page as soon as the socket friendship is available when snapchat opening failed (for example, sever didn't send it because we don't open snap directly anymore)
		} /*else if
			// if they haven't invited snapchat friends
			!Achievements.shared.invitedSnapchatFriends &&
			// and they've have the app open for two calls
			self.callsInSession >= 2 &&
			// show the snapchat invite popup every calls
			Achievements.shared.totalChats % 10 == 0 &&
			// but dont show it for the first call
			Achievements.shared.totalChats != 0 &&
			// and only show it after a sucessful call
			self.chatSession?.didConnect == true &&
			// and don't show the popup if it's not possible to show (e.g. snap not installed)
			SnapchatInviteViewController.canDisplay() {
			print("Showing Snapchat")
			#if !REALM_SYNC
			self.stopFindingChats(andDisconnect: true, forReason: "snapchat-vc")
			self.present((self.storyboard?.instantiateViewController(withIdentifier: "inviteSnapchatVC"))!, animated: true, completion: {
			self.startFindingChats(forReason: "snapchat-vc")
			})
			#endif
		}*/ else {
			// check if chat id exists
			print("Trying again")
			if isCurrentSession {
				self.getNewSession()
			}
		}
	}
     
     func shouldShowConnectingStatus(in chatSession: ChatSession) {
          self.waitingText.isHidden = true
          self.connectText.isHidden = false
          AnaliticsCenter.log(event: .matchConnect)
     }
	@IBAction func matchModeChanged(_ sender: MatchModeSwitch) {
		self.stopFindingChats(andDisconnect: false, forReason: "switch match mode")
		
		var currentMatchMode = MatchMode.TextMode
		if let prevMatchMode = Achievements.shared.selectMatchMode {
			currentMatchMode = (prevMatchMode == .VideoMode) ? .TextMode : .VideoMode
		}else {
			// 第一次选择 match mode
			
		}
		Achievements.shared.selectMatchMode = currentMatchMode
		sender.switchToMode(matchMode: currentMatchMode)
		matchModeLabel.text = (currentMatchMode == .VideoMode) ? "Turn off text mode to get video chat matches only 📹" : "Turn on text mode to get both text and video chat matches 🙊💬"
		showPopup(popup: matchModePopup)
		self.startFindingChats(forReason: "switch match mode")
	}
	
	@IBAction func bananaButtonTapped(sender: Any) {
		let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.lineSpacing = 9
		paragraph.alignment = .center
		
		let attributedString = NSAttributedString(
			string: "🕑 Time added = 🍌2 \n 🎉 Friend added = 🍌5",
			attributes: [
				NSParagraphStyleAttributeName: paragraph,
				NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)
			]
		)
		
		alert.setValue(attributedString, forKey: "attributedMessage")
		
		alert.addAction(UIAlertAction(title: "Cool", style: .cancel, handler: {
			(UIAlertAction) in
			alert.dismiss(animated: true, completion: nil)
		}))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func warnConnectionTimeout(in chatSession:ChatSession) {
		self.stopFindingChats(andDisconnect: false, forReason: "ignoring")
		let alert = UIAlertController(title: "👮‍♀️ Don't ignore people", message: "Make sure to skip or accept chats.", preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "Soz officer", style: .cancel, handler: {
			(UIAlertAction) in
			alert.dismiss(animated: true, completion: nil)
			self.startFindingChats(forReason: "ignoring")
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
		self.bananaNotificationToken?.stop()
		self.unreadMessageNotificationToken?.stop()
		self.incomingCallNotificationToken?.stop()
		self.currentUserNotifcationToken?.stop()
		self.currentExperimentNotifcationToken?.stop()
		Socket.shared.isEnabled = false
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
		self.bananaNotificationToken = APIController.shared.currentUser?.addNotificationBlock { [weak self] (changes) in
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
		
		self.unreadMessageNotificationToken = self.friendships?.addNotificationBlock { [weak self] (changes) in
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
		
		let bananaRect = formattedNumber?.boundingRect(forFont: self.bananaCountLabel.font, constrainedTo: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bananaCountLabel.frame.size.height))
		let bananaViewWidth = (bananaRect?.size.width)! + 64 // padding
		
		self.bananaViewWidthConstraint.constant = bananaViewWidth
		self.view.setNeedsLayout()
	}
	
	func setFactText(_ text: String) {
		self.factTextView.isSelectable = true
		self.factTextView.text = text
		self.factTextView.isSelectable = false
	}
	
	func start(fact: String) {
		pendingFactText = fact
		if let fact = pendingFactText {
			self.isSkip = true
			self.setFactText(fact)
			if self.isLoading {
				return
			}
			self.isLoading = true
		}
	}
     
     func listTrees(trees:Array<String>){
          if trees.count == 0 {
               return
          }
          
          guard let allTree = self.channels else {
               print("no tree info now")
               return
          }
          
          guard let curTrees = APIController.shared.currentUser?.channels else { return  }
          var commonTrees = Array<String>.init()
          for tree in curTrees {
               if let treeID = tree.channel_id {
                    if trees.contains(treeID) {
                         commonTrees.append(treeID)
                    }
               }
          }
          
          commonTrees = commonTrees.sorted { (string1, string2) -> Bool in
               return string1 > string2
          }
          
          var count = 0
          var org_emoji_str = "🍌🍌🍌🍌"
          var emojiArr:[String] = []

          for treeInfo in allTree{
               if count >= 3 {break}
               
               if let channelID = treeInfo.channel_id , commonTrees.contains(channelID) ,
                    let emojiStr = treeInfo.emoji {
                    org_emoji_str.remove(at: org_emoji_str.startIndex)
                    org_emoji_str.append(emojiStr)
                    
                    count += 1
               }
          }
          
          for i in 0...3 {
               if i == 0 {
                    emojiArr.append(org_emoji_str)
               }else{
                    var newStr = emojiArr[i-1]
                    let cha = newStr.remove(at: newStr.startIndex)
                    newStr.append(cha)
                    emojiArr.append(newStr)
                    emojiArr[i-1].remove(at: emojiArr[i-1].startIndex)
               }
          }
          
          emojiArr[3].remove(at: emojiArr[3].startIndex)
          
          self.loadingTextLabel.setTicksWithArray(ticks: emojiArr)
     }
     
     func hideTreeLabels(){
          self.loadingTextLabel.setDefaultTicks()
     }
     
	func skipped() {
		DispatchQueue.main.async {
			self.start()
          if !self.mySkip {
               self.skippedText.layer.opacity = 1.0
          }
          self.mySkip = false
            UIView.animate(withDuration: 1.0, animations: {
                self.skippedText.layer.opacity = 0.0
                self.factTextView.text = self.nextFact
                self.view.layoutIfNeeded()
            })
            self.hideTreeLabels()
		}
	}
	func start() {
		if let onboardingFactText = APIController.shared.currentExperiment?.onboarding_fact_text, Achievements.shared.minuteMatches == 0, APIController.shared.currentExperiment?.onboarding_video.value == true {
			self.setFactText(onboardingFactText)
		}
		
		pendingFactText = nil
		
		if self.isSkip {
			self.isSkip = false
			self.didSkip = true
		}
		
		if self.isLoading {
			return
		}
		
		isLoading = true
	}
	
	func stop(withFade: Bool, completion: (() -> Void)?) {
		
		if !self.isLoading {
			completion?()
			return
		}
		
		isLoading = false
		timer?.invalidate()
		timer = nil
		if withFade && self.isLoading {
			UIView.animate(withDuration: 0.4, animations: {
			}, completion: { (_) in
				completion?()
			})
		} else {
			completion?()
		}
	}
}

extension MainViewController:SlideViewManager {
	func shouldShowNotification() -> Bool {
		return (self.presentedViewController?.presentedViewController as? ChatViewController) == nil
	}
	
	func shouldExecuteNotification() -> Bool {
		return self.chatSession?.status != .connected
	}
}


