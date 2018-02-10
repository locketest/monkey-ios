//
//  TextChatViewController.swift
//  Monkey
//
//  Created by 王广威 on 2018/2/5.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import DeviceKit
import ObjectMapper

class TextChatViewController: MonkeyViewController {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var policeButton: SmallYellowButton!
	@IBOutlet weak var soundButton: SmallYellowButton!
	@IBOutlet weak var friendButton: SmallYellowButton!
	@IBOutlet weak var endCallButton: SmallYellowButton!
	@IBOutlet weak var publisherContainerView: UIView!
	weak var remoteStreamView: UIView?
	
	@IBOutlet weak var inputContainerView: UIView!
	@IBOutlet weak var placeholderTextLabel: UILabel!
	@IBOutlet weak var textInputView: UITextView!
	@IBOutlet weak var textMessageList: UITableView!
	@IBOutlet weak var GradientView: UIView!
	@IBOutlet weak var publisherContainerViewLeftConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var publisherContainerViewHeightConstraint: NSLayoutConstraint!
	/// Height of chat text view constraint, used to lock when we go past 3 lines
	@IBOutlet weak var inputHeightConstraint:NSLayoutConstraint!
	
	@IBOutlet weak var conversationTip: UILabel!
	@IBOutlet weak var soundButtonHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var addFriendButtonHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var policeButtonTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var inputContainerViewBottomConstraint: NSLayoutConstraint!
	
	var chatSession: ChatSession?
	var messages = [TextMessage].init()
	var reportImage: UIImage?
	var reportChatId: String?
	weak var callDelegate: CallViewControllerDelegate?
	var soundPlayer = SoundPlayer.shared
	var eras = "👂"
	
	var tips = [
		"Share your weekend vibe. Use emojis only.",
		"Most monkeys have tails. If you didn’t know now you know.",
		"Share what you’re doing right now and make it rhyme.",
		"Flip flops or high tops? Raindrop or drop top? Choose wisely, peasants.",
		"Yeezus or Sasha Fierce? Who are you.",
		"If you were a fashion brand which one would you be. Explain yourself.",
		"Do you ever ask yourself: WWYD? FYI the Y stands for Yeezy.",
		"When is homework not homework? Answer the q.",
		"There are secret features in the app. Find them.",
		"Name your spirit animal. Is it furry?",
		"Are you a New World monkey or an Old World monkey?",
		"A baboon is an example of an Old World monkey.",
		"A group of monkeys is called a troop. You’re welcome.",
		"Apes don’t have tails. That’s weird.",
		"PSA: don’t try to touch a monkey, they don’t like it.",
		"Bananas float in water, as do apples and watermelons.",
		"Nobody knew how to spell “bananas” before Gwen Stefani's “Hollaback Girl.\"",
		"There is a Banana Club Museum in Mecca, CA. My temple.",
		"You can heal a splinter with a banana peel.",
		"Over 100 billion bananas are eaten every year around the world.",
		"Bananas are technically berries. But strawberries are not.",
		"There are 264 known monkey species.",
		"The King of Hearts is the only king without a mustache...except the Monkey King.",
		"Monkeys don't just love bananas, they love mangoes too.",
		"Did you know mangoes can get sunburned?",
		"Name the color shirt you're wearing and count to 5. Do it now.",
		"The # is actually called an octothorp.",
		"Your socks don’t match. Made you look.",
		"95% of people reading this are staring at their phones.",
		"Tell a knock knock joke. Make it about a monkey.",
		"Name your favorite vlogger. What’s so great about them.",
		"How would your friends describe you. Only use 3 words, peasant.",
		"Describe a snapchat filter you love or hate. Do it now.",
		"IG or snap? Pick 1 and explain.",
		"Will Selena and JB get back together? Explain.",
		"Share the last song you listened to. Don’t say the name of the song.",
		"Is Post Malone a G? Give 2 reasons why/why not.",
		"Be a good monkey and share what you did last weekend.",
	]
	var winEmojis = "🎉👻🌟😀💎♥️🎊🎁🐬🙉🔥"
	var animator: UIDynamicAnimator!
	var isAnimatingUnMuted = false
	var effectsCoordinator = EffectsCoordinator()
	
	func isIphoneX() -> Bool {
		return Device() == Device.iPhoneX
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
	}
	
	deinit {
		KeyboardManager.default().removeKeyboardObserver(self)
		NotificationCenter.default.removeObserver(self, name: .UITextInputCurrentInputModeDidChange, object: nil)
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshTypingStatus), object: nil)
		print("(self) deinit...")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		Socket.shared.isEnabled = true
		self.endCallButton.isEnabled = false
		self.soundButton.isHidden = true
		self.friendButton.isHidden = true
		self.endCallButton.isHidden = true
		
		self.textInputView.delegate = self
		self.textInputView.layer.masksToBounds = true
		self.textInputView.layer.cornerRadius = 8
		self.textInputView.font = UIFont.systemFont(ofSize: 17)
		
		self.textMessageList.keyboardDismissMode = .onDrag
		self.soundButton.alpha = 0
		self.friendButton.alpha = 0
		self.endCallButton.alpha = 0
		
		self.conversationTip.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
		self.conversationTip.backgroundColor = UIColor.clear
		
		let random: Int = Int(arc4random_uniform(UInt32(self.tips.count)))
		self.conversationTip.text = self.tips[random]
		
		chatSession?.add(messageHandler: self)
		if let subView = self.chatSession?.subscriber?.view {
			self.containerView.insertSubview(subView, belowSubview: policeButton)
			subView.frame = UIScreen.main.bounds
			self.remoteStreamView = subView
		}
		
		if isIphoneX() {
			inputContainerViewBottomConstraint.constant = 34
			policeButtonTopConstraint.constant = 52
		}else {
			inputContainerViewBottomConstraint.constant = 0
			policeButtonTopConstraint.constant = 28
		}
		
		let gradientLayer = CAGradientLayer();
		gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
		gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
		gradientLayer.endPoint = CGPoint.init(x: 0, y: 1)
		gradientLayer.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 32)
		GradientView.layer.addSublayer(gradientLayer)
		
		animator = UIDynamicAnimator(referenceView: self.containerView)
		self.publisherContainerView.layer.masksToBounds = true
		updatePublisherViewConstraints(enlarged: true)
        // Do any additional setup after loading the view.
		
		// notifications for keyboard hide/show
		KeyboardManager.default().addKeyboardWillShowObserver(self) {[weak self] (keyboardTransition) in
			guard let `self` = self else { return }
			self.inputContainerViewBottomConstraint.constant = keyboardTransition.toFrame.size.height
			UIView.animate(withDuration: keyboardTransition.animationDuration, delay: 0.0, options: keyboardTransition.animationOption, animations: {
				self.containerView.layoutIfNeeded()
			}, completion: nil)
		}
		KeyboardManager.default().addKeyboardWillChangeFrameObserver(self) {[weak self] (keyboardTransition) in
			guard let `self` = self else { return }
			self.inputContainerViewBottomConstraint.constant = keyboardTransition.toFrame.size.height
			UIView.animate(withDuration: keyboardTransition.animationDuration, delay: 0.0, options: keyboardTransition.animationOption, animations: {
				self.containerView.layoutIfNeeded()
			}, completion: nil)
		}
		KeyboardManager.default().addKeyboardWillDismissObserver(self) {[weak self] (keyboardTransition) in
			guard let `self` = self else { return }
			self.inputContainerViewBottomConstraint.constant = self.isIphoneX() ? 34 : 0
			UIView.animate(withDuration: keyboardTransition.animationDuration, delay: 0.0, options: keyboardTransition.animationOption, animations: {
				self.containerView.layoutIfNeeded()
			}, completion: nil)
		}
		
//		self.view.backgroundColor = UIColor.clear
//		self.containerView.backgroundColor = UIColor.clear
		self.containerView.isUserInteractionEnabled = true
		self.containerView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(stopEditing)))
		
		// notification for dictation
		NotificationCenter.default.addObserver(self, selector: #selector(changeInputMode(notification:)), name: .UITextInputCurrentInputModeDidChange, object: nil)
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: Double(RemoteConfigManager.shared.next_show_time))) {[weak self] in
			guard let `self` = self else { return }
			self.endCallButton.isHidden = false
			self.endCallButton.isEnabled = true
			UIView.animate(withDuration: 0.25, animations: {
				self.endCallButton.alpha = 1
			})
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.publisherContainerView.addSubview(MonkeyPublisher.shared.view)
		let viewsDict = ["view": MonkeyPublisher.shared.view]
		self.publisherContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
		self.publisherContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.isPublisherViewEnlarged = false
		self.soundButton.isHidden = false
		self.friendButton.isHidden = false
		
		let streamViewWidth = (self.containerView.frame.size.width - 60 - 4 * 4) / 2
		UIView.animate(withDuration: 0.3) {
			self.soundButton.alpha = 1
			self.friendButton.alpha = 1
//			self.endCallButton.alpha = 1
			self.remoteStreamView?.layer.cornerRadius = 4.0
			self.remoteStreamView?.layer.masksToBounds = true
			self.remoteStreamView?.frame = CGRect.init(x: self.containerView.frame.size.width - streamViewWidth - 4, y: self.isIphoneX() ? 44 : 20, width: streamViewWidth, height: 192)
			self.view.layoutIfNeeded()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.textInputView.resignFirstResponder()
		self.updateIsTyping(false)
		
		self.remoteStreamView?.layer.masksToBounds = false
		self.soundButton.isUserInteractionEnabled = false
		self.friendButton.isUserInteractionEnabled = false
		self.endCallButton.isUserInteractionEnabled = false
		self.policeButton.isUserInteractionEnabled = false
		UIView.animate(withDuration: 0.3, animations: {
			self.remoteStreamView?.layer.cornerRadius = 0
			self.soundButton.alpha = 0
			self.friendButton.alpha = 0
			self.endCallButton.alpha = 0
			self.policeButton.alpha = 0
		})
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.stopEditing()
	}
	
	func requestPresentation(of alertController: UIAlertController, from view: UIView) {
		self.present(alertController, animated: true, completion: nil)
	}
	
	func stopEditing() {
		self.view.endEditing(true)
	}
	
	// Sound Button
	@IBAction func unMute(_ sender: BigYellowButton) {
		self.soundButton.isEnabled = false
		
		if Achievements.shared.unMuteFirstTextMode == false {
			let chatSession = self.chatSession
			
			let first_name = chatSession?.realmCall?.user?.first_name ?? ""
			let unMuteFirstTextModeAlert = UIAlertController(title: "Open sound!", message: "You will open the sound channel when \(first_name) open the sound channel too!", preferredStyle: .alert)
			unMuteFirstTextModeAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: { (UIAlertAction) in
				if chatSession == self.chatSession && chatSession?.status == .connected {
					self.chatSession?.sentUnMute()
					Achievements.shared.unMuteFirstTextMode = true
				}
			}))
			self.present(unMuteFirstTextModeAlert, animated: true)
		}else {
			self.chatSession?.sentUnMute()
		}
	}
	
	// Add Friend Button
	@IBAction func addSnapchat(_ sender: BigYellowButton) {
		sender.isEnabled = false
		
		if Achievements.shared.addFirstSnapchat == false {
			let chatSession = self.chatSession
			let first_name = chatSession?.realmCall?.user?.first_name ?? ""
			let addFirstSnapchatAlert = UIAlertController(title: "Add friends!", message: "You will become friends when \(first_name) add friends too!", preferredStyle: .alert)
			addFirstSnapchatAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: { (UIAlertAction) in
				if chatSession == self.chatSession && chatSession?.status == .connected {
					let _ = self.chatSession?.sendSnapchat(username: APIController.shared.currentUser!.snapchat_username!)
					Achievements.shared.addFirstSnapchat = true
				}
			}))
			self.present(addFirstSnapchatAlert, animated: true)
		}else {
			let _ = self.chatSession?.sendSnapchat(username: APIController.shared.currentUser!.snapchat_username!)
		}
	}
	
	// Next Button
	@IBAction func endCall(_ sender: BigYellowButton) {
		self.endCallButton.isEnabled = false
		self.chatSession?.disconnect(.consumed)
	}
	
	func updatePublisherViewConstraints(enlarged: Bool) {
		if enlarged {
			publisherContainerView.layer.cornerRadius = 0
			publisherContainerViewLeftConstraint.constant = 0
			publisherContainerViewTopConstraint.constant = 0
			
			publisherContainerViewWidthConstraint.constant = self.containerView.frame.size.width
			publisherContainerViewHeightConstraint.constant = self.containerView.frame.size.height
		}else {
			publisherContainerView.layer.cornerRadius = 4
			publisherContainerViewLeftConstraint.constant = 4
			publisherContainerViewTopConstraint.constant = isIphoneX() ? 44 : 20
			
			publisherContainerViewWidthConstraint.constant = (self.containerView.frame.size.width - 60 - 4 * 4) / 2.0
			publisherContainerViewHeightConstraint.constant = 192
		}
		self.view.setNeedsLayout()
	}
	
	var isPublisherViewEnlarged = true { // true when skip button,
		didSet {
			updatePublisherViewConstraints(enlarged: isPublisherViewEnlarged)
		}
	}
	
	var hideStatusBarForScreenshot = false {
		didSet {
			self.setNeedsStatusBarAppearanceUpdate()
		}
	}
	
	/// Placeholder text for the chat input UITextView
	var isShowingPlaceholderText = true {
		didSet {
			guard isShowingPlaceholderText != oldValue else {
				return
			}
			self.placeholderTextLabel.isHidden = !self.isShowingPlaceholderText
			if isShowingPlaceholderText {
				self.textInputView.text = ""
				self.textInputView.isScrollEnabled = false
				self.inputHeightConstraint.constant = 44
				self.view.setNeedsLayout()
			}
			updateIsTyping(!isShowingPlaceholderText)
		}
	}
	
	func updateIsTyping(_ isTyping: Bool) {
		
	}
	
	func reloadData() {
		self.textMessageList.reloadData()
		self.textMessageList.scrollToBottom(animated: true)
		
		
	}
	
	override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
		if hideStatusBarForScreenshot {
			return .none
		}
		return .slide
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension TextChatViewController: UITextViewDelegate {
	/// This will catch any time people change language, but we only care about dictation so we can hide placeholder
	func changeInputMode(notification : NSNotification) {
		
		if textInputView.textInputView.textInputMode?.primaryLanguage == "dictation" {
			self.isShowingPlaceholderText = false
		} else if textInputView.text.unicodeScalars.first?.value == 65532 { // the unicode for "object replacement character"; occurs when speaker says nothing
			self.isShowingPlaceholderText = true
		}
		
	}
	
	/// When we get a newline (and ONLY a newline, prevents pasting things with a newline from triggering send), we treat that as a 'send' action
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if textView.text.count == 0 && text.count == 0 {
			// Pressing backspace for no reason.
			return false
		}
		if text == "\n" {
			self.sendMessage()
			return false
		}
		
		self.chatSession?.sentTypeStatus()
		let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
		self.isShowingPlaceholderText = (newText.count == 0)
		
		return true
	}
	
	func textViewDidChange(_ textView: UITextView) {
		let heightOfTextInput = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
		let heightOfTextContainerView = ceil(heightOfTextInput) + 16
		let textHeight = max(44, min(heightOfTextContainerView, 85)) // Don't go above 3 lines lmao this number
		textView.isScrollEnabled = heightOfTextContainerView > 85
		self.inputHeightConstraint.constant = textHeight
		self.view.setNeedsLayout()
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		self.textMessageList.scrollToBottom(animated: true)
	}
	
	/// Send message, prevent keyboard dismissal, reset text to ""
	func sendMessage() {
		guard let messageText = self.textInputView.text, self.textInputView.text.isEmpty == false else {
			return
		}
		let body = messageText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if body.isEmpty == false {
			self.chatSession?.sentTextMessage(text: messageText)
			let messageInfo = [
				"type": MessageType.Text.rawValue,
				"body": messageText,
				"sender": APIController.shared.currentUser?.user_id ?? ""
			]
			if let textMessage = Mapper<TextMessage>().map(JSON: messageInfo) {
				var typingMessage: TextMessage?
				if let lastMessage = self.messages.last, lastMessage.type == MessageType.Typing.rawValue {
					typingMessage = lastMessage
					self.messages.removeLast()
				}
				self.messages.append(textMessage)
				if let lastTypingMessage = typingMessage {
					self.messages.append(lastTypingMessage)
				}
			}
		}
		
		self.isShowingPlaceholderText = true
		self.reloadData()
	}
}

extension TextChatViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let textMessage = self.messages[indexPath.row]
		return textMessage.textHeight + 16 + 16
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let rowCount = messages.count
		self.conversationTip.isHidden = rowCount > 0
		return rowCount
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let textMessage = self.messages[indexPath.row]
		let cellIdentifier = textMessage.direction.rawValue
		var messageCell: TextModeMessageCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? TextModeMessageCell
		if messageCell == nil {
			messageCell = TextModeMessageCell.init(direction: textMessage.direction)
		}
		
		messageCell?.configure(messageModel: textMessage)
		return messageCell!
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		self.stopEditing()
	}
}

extension TextChatViewController: MatchViewControllerProtocol {
	internal func friendMatched(in chatSession: ChatSession?) {
		if let currentChatSession = chatSession {
			Achievements.shared.snapchatMatches += 1
			if Achievements.shared.addedFirstSnapchat == false {
				let first_name = currentChatSession.realmCall?.user?.first_name ?? ""
				let addedFirstSnapchatAlert = UIAlertController(title: "👫 Add friends!", message: "Add friends success with \(first_name)", preferredStyle: .alert)
				addedFirstSnapchatAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: { (UIAlertAction) in
					Achievements.shared.addedFirstSnapchat = true
				}))
				self.present(addedFirstSnapchatAlert, animated: true)
			}
			self.celebrateAddFriend()
		}else {
			self.addFriendButtonHeightConstraint.constant = 0
			self.view.setNeedsLayout()
		}
		
		self.endCallButton.emoji = "👋"
		self.endCallButton.setTitle("Pce out", for: .normal)
	}
	
	func soundUnMuted(in chatSession: ChatSession) {
		
		if Achievements.shared.unMutedFirstTextMode == false {
			let unMutedFirstTextModeAlert = UIAlertController(title: "👂Open sound success!", message: "Sound channel open already.", preferredStyle: .alert)
			unMutedFirstTextModeAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: { (action) in
				Achievements.shared.unMutedFirstTextMode = true
			}))
			self.present(unMutedFirstTextModeAlert, animated: true)
		}
		
		self.celebrateUnMuted()
	}
	
	func minuteAdded(in chatSession: ChatSession) {
		
	}
	
	func celebrateAddFriend() {
		soundPlayer.play(sound: .win)
		animator.removeAllBehaviors()
		let gravityBehaviour = UIGravityBehavior()
		gravityBehaviour.gravityDirection = CGVector(dx: 0.0, dy: 1.6)
		animator.addBehavior(gravityBehaviour)
		var emojiLabels = Array<UILabel>()
		TapticFeedback.impact(style: .medium)
		
		for _ in 1...130 {
			let emojiLabel = UILabel()
			emojiLabel.text = String(winEmojis[winEmojis.index(winEmojis.startIndex, offsetBy: (Int(arc4random_uniform(UInt32(winEmojis.count)))))])
			emojiLabel.font = UIFont.systemFont(ofSize: 39.0)
			emojiLabel.frame = CGRect(x: (self.friendButton.superview?.frame.origin.x)! + 30, y: self.friendButton.frame.origin.y, width: 50, height: 50)
			self.containerView.insertSubview(emojiLabel, belowSubview: self.friendButton)
			
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
			if self.chatSession?.status == .connected {
				self.addFriendButtonHeightConstraint.constant = 0
				self.view.setNeedsLayout()
			}
		}
	}
	
	func celebrateUnMuted() {
		AudioServicesPlayAlertSound(1519) // kSystemSoundID_Vibrate: (this is  `Peek` or a weak boom, 1520 is `Pop` or a strong boom)
		soundPlayer.play(sound: .score)
		for _ in 1...18 {
			let emojiLabel = UILabel()
			emojiLabel.text = eras
			emojiLabel.font = UIFont.systemFont(ofSize: 39.0)
			let xDifference:CGFloat = CGFloat(arc4random_uniform(100))
			emojiLabel.frame = CGRect(x: (self.soundButton.superview?.frame.origin.x)! + xDifference, y: self.soundButton.frame.origin.y, width: 50, height: 50)
			UIView.animate(withDuration: TimeInterval(CGFloat(arc4random_uniform(200)) / 100.0), animations: {
				emojiLabel.layer.opacity = 0.0
				emojiLabel.frame.origin.y = self.containerView.frame.size.height - 350
			}) { (Bool) in
				emojiLabel.removeFromSuperview()
			}
			self.containerView.insertSubview(emojiLabel, belowSubview: self.soundButton)
		}
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
			if self.chatSession?.status == .connected {
				self.soundButtonHeightConstraint.constant = 0
				self.view.setNeedsLayout()
			}
		}
	}
	
	func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
		return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
	}
	
	func received(textMessage: TextMessage, in chatSession: ChatSession) {
		if let lastMessage = self.messages.last, lastMessage.type == MessageType.Typing.rawValue {
			if textMessage.type == MessageType.Typing.rawValue {
				return
			}else {
				self.messages.removeLast()
			}
		}
		
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshTypingStatus), object: nil)
		self.messages.append(textMessage)
		self.reloadData()
		if textMessage.type == MessageType.Typing.rawValue {
			self.perform(#selector(refreshTypingStatus), with: nil, afterDelay: 10)
		}
	}
	
	func refreshTypingStatus() {
		if let lastMessage = self.messages.last, lastMessage.type == MessageType.Typing.rawValue {
			self.messages.removeLast()
			self.reloadData()
		}
	}
	
	func unhideAfterReportScreenshot() {
		self.chatSession?.subscriber?.view?.effectsEnabled = true
		
		self.policeButton.isHidden = false
		self.soundButton.isHidden = false
		self.friendButton.isHidden = false
		if self.endCallButton.isEnabled {
			self.endCallButton.isHidden = false
		}
		
		self.hideStatusBarForScreenshot = false
	}
}

extension TextChatViewController: MessageHandler {
	var chatSessionMessagingPrefix: String {
		return "TextModeMessage"
	}
	
	func chatSession(_ chatSession: ChatSession, received message: String, from connection: OTConnection, withType type: String) {
		
	}
	func chatSession(_ chatSession: ChatSession, statusChangedTo status: ChatSessionStatus) {
		
	}
	func chatSesssion(_ chatSesssion: ChatSession, connectionCreated connection: OTConnection) {
		
	}
}
