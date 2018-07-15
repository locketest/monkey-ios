//
//  ChatViewController.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/9/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import Foundation
import RealmSwift
import SafariServices
import Kingfisher
import DeviceKit

class ChatViewController: SwipeableViewController, ChatViewModelDelegate, UITextViewDelegate {
    /// Table showing the conversation as chat bubbles
    @IBOutlet weak var chatTableView: UITableView!
    /// Input view for conversation
    @IBOutlet weak var chatTextField: UITextView!
    /// Image view showing the users profile picture
    @IBOutlet weak var profileImageView:CachedImageView!
    /// Label containing the users name
    @IBOutlet weak var profileNameLabel: UILabel!
    /// Label describing the last time the user was online
    @IBOutlet weak var profileActiveLabel: UILabel!
    /// Bottom constraint for view, changed with keyboard movements
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    /// Height of chat text view constraint, used to lock when we go past 3 lines
    @IBOutlet weak var inputHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderTextLabel: UILabel!
    /// Button that opens snapchat when tapped
    @IBOutlet weak var snapchatButton: BigYellowButton!
    /// The button used to make and answer calls
    @IBOutlet weak var callButton: JigglyButton!
    /// The Emoji on the callButton that recieves the animations for calls
    @IBOutlet weak var callEmojiLabel: EmojiLabel!
    /// A button shown when users have not exchanged any messages. Pressing it will send a random conversation starter
    @IBOutlet weak var startConvoButton: UIButton!

    @IBOutlet weak var textFieldBgView: UIView!

    @IBOutlet weak var aboutUsButton: BigYellowButton!

    @IBOutlet weak var snapchatButtonConstraint: NSLayoutConstraint!

    @IBOutlet weak var chatTableViewBottomConstraint: NSLayoutConstraint!

    /// Data backing for ChatViewController
    lazy var viewModel = ChatViewModel()
    let textInset: CGFloat = 12
    let maxBubbleWidth: CGFloat = 244
    var pendingCallId: String?
    /// Is dismissing keyboard
    var isAnimatingDown = false
	var isTrackingMessage = false

    var callTimer: Timer?

    var isMonkeyKingBool: Bool = false
    let MonkeyKingShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
    let MonkeyKingBgColor = UIColor(red: 34.0 / 255.0, green: 29.0 / 255.0, blue: 62.0 / 255.0, alpha: 1)

    /// A reference to the presented instagramVC. Currently used to forward longPressGestureRecognizer updates
    weak var instagramViewController: InstagramPopupViewController?
    /// The location of the user's finger when instagram popup is presented, used to calculate displacement to pass to instagramVC if they do not lift finger to pan
    var initialLongPressLocation: CGPoint?
    /// The previous location of the user's finger, used to calculate velocity to pass to instagramVC if they do not lift finger to pan
    var previousLongPressLocation: CGPoint?

	var videoCall: VideoCallModel?
	var videoCallManager = VideoCallManager.default
	var callViewController: MatchMessageObserver?
	
    /// Placeholder text for the chat input UITextView
	var isShowingPlaceholderText: Bool = true {
        didSet(oldValue) {
            guard isShowingPlaceholderText != oldValue else {
                return
            }
            self.placeholderTextLabel.isHidden = !self.isShowingPlaceholderText
            if isShowingPlaceholderText {
                self.chatTextField.text = ""
                self.chatTextField.isScrollEnabled = false
                self.inputHeightConstraint.constant = 44
                self.view.setNeedsLayout()
            }
            updateIsTyping(!isShowingPlaceholderText)
        }
    }

    func updateIsTyping(_ isTyping: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let friendshipId = self?.viewModel.friendship?.friendship_id else {
                return
            }
            Socket.shared.send(message: [
                "data": [
                    "type": "friendships",
                    "id": friendshipId,
                    "attributes": [
                        "is_typing": isTyping,
                    ]
                ]
			], to: "patch_friendships")
        }
    }

    /// Mark - ChatViewModelDelegate
    /// Received a message, reload data
    func reloadData() {
        self.chatTableView.reloadData()
        self.chatTableView.scrollToBottom(animated: true)

        if self.isMonkeyKingBool == false {
            if (self.viewModel.friendship?.user_is_typing ?? false) == true {
                self.profileActiveLabel.text = "typing..."
            } else if self.callButton.isSpinning {
                self.profileActiveLabel.text = "connecting..."
            } else {
                self.profileActiveLabel.text = viewModel.userLastOnlineAtString
            }
        } else {
            self.profileActiveLabel.isHidden = true
        }
    }
	
	func callCanceled() {
		self.resetCallStatus()
		self.sendCancelCallMessage()
	}
	
	func callFailed() {
		self.resetCallStatus()
		self.videoCallManager.closeCall()
		self.videoCall = nil
	}
	
	func resetCallStatus() {
		self.callButton.isJiggling = false
		self.callButton.isSpinning = false
		self.callButton.backgroundColor = Colors.white(0.06)
	}
	
	/// This method is a callback for the API request to create a RealmCall object. It is only called when user initiates a call.
	func callSuccess(videoCall: VideoCallModel) {
		self.videoCall = videoCall
		// we accept before setting it because didSet checks to see if it's been accepted to differientiate bw initiated and incoming calls
		videoCall.accept = true
		self.videoCallManager.startCall()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.delegate = self
		MessageCenter.shared.addMessageObserver(observer: self)
		NotificationManager.shared.prePresentDelegate = self

        self.chatTableView.delegate = self
        self.chatTableView.dataSource = self

        self.profileImageView.layer.cornerRadius = 24
        self.profileImageView.layer.masksToBounds = true
		
		var imageName = "ProfileImageDefaultMale"
		if self.viewModel.friendship?.user?.gender == Gender.female.rawValue {
			imageName = "ProfileImageDefaultFemale"
		}
		self.profileImageView.placeholder = imageName
		self.profileImageView.url = self.viewModel.friendship?.user?.profile_photo_url

        self.chatTableView.keyboardDismissMode = .onDrag
        self.chatTextField.delegate = self

        // Setup input UITextView to start out with the 'placeholder' text, with proper insets
        self.chatTextField.textContainerInset = UIEdgeInsetsMake(3.7, 3, 3.8, 3)
        self.chatTextField.layer.cornerRadius = 5.0

        self.chatTextField.contentInset = .zero
        self.chatTableView.contentInset = UIEdgeInsetsMake(14, 0, 10, 0)

        self.callButton.emojiLabel = self.callEmojiLabel
		self.callButton.backgroundColor = Colors.white(0.06)

        // Hide snapchat button if we dont have a snapchat for them
        if self.viewModel.friendship?.user?.username == nil {
            self.snapchatButton.isHidden = true
        }

        self.handleViewFunc()
    }

    func handleViewFunc() {
        if self.isMonkeyKingBool {
            self.aboutUsButton.layer.shadowColor = MonkeyKingShadowColor
            self.aboutUsButton.backgroundColor = MonkeyKingBgColor
            self.aboutUsButton.layer.shadowOpacity = 0.7
            self.aboutUsButton.layer.shadowRadius = 10
            self.aboutUsButton.clipsToBounds = false

            self.chatTableViewBottomConstraint.constant = 0
            self.snapchatButtonConstraint.constant = 14
            self.startConvoButton.isHidden = true
            self.textFieldBgView.isHidden = true
            self.aboutUsButton.isHidden = false
            self.callButton.isHidden = true
        } else {
            self.chatTableViewBottomConstraint.constant = 44
            self.snapchatButtonConstraint.constant = 76
            self.startConvoButton.isHidden = false
            self.textFieldBgView.isHidden = false
            self.aboutUsButton.isHidden = true
            self.callButton.isHidden = false
        }
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let friendship = self.viewModel.friendship {
			let user = friendship.user
			
			self.profileNameLabel.text = user?.first_name
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// enter forground
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
		// notifications for keyboard hide/show
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)
		// notification for dictation
		NotificationCenter.default.addObserver(self, selector: #selector(changeInputMode(notification:)), name: .UITextInputCurrentInputModeDidChange, object: nil)
		
		// endTransition on DismissPopupAnimator calls view life cycle methods (even if cancelled); dont want keyboard to come up over insta
		if self.isMonkeyKingBool == false {
			self.chatTextField.becomeFirstResponder()
		}
		self.chatTableView.scrollToBottom()
	}
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        /// AT LEAST TWO ENGINEERS MUST APPROVE ALL CODE ADDED TO THIS FUNCTION
        self.chatTextField.resignFirstResponder()
        self.updateIsTyping(false)
        /// AT LEAST TWO ENGINEERS MUST APPROVE ALL CODE ADDED TO THIS FUNCTION
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
		NotificationCenter.default.removeObserver(self)
    }

    @IBAction func aboutUsBtnClickFunc(_ sender: BigYellowButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "💖 Rate Us", style: .default, handler: { (UIAlertAction) in
			AnalyticsCenter.log(withEvent: .monkeyKingClick, andParameter: [
				"type": "rate",
				])
			
            self.openURL("https://itunes.apple.com/us/app/id1165924249?action=write-review", inVC: true)
        }))
        alertController.addAction(UIAlertAction(title: "📲 Support", style: .default, handler: { (UIAlertAction) in
			AnalyticsCenter.log(withEvent: .monkeyKingClick, andParameter: [
				"type": "support",
				])
			
            self.openURL("https://monkey.canny.io/requests", inVC: true)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }

    func openURL(_ urlString: String, inVC: Bool) {
        guard let url = URL(string: urlString) else {
            return
        }
        if !inVC {
            UIApplication.shared.openURL(url)
            return
        }
        let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
        vc.modalPresentationCapturesStatusBarAppearance = true
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true, completion: nil)
    }

    @IBAction func presentInstagramPopover(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {

        let locationPoint = longPressGestureRecognizer.location(in: longPressGestureRecognizer.view)

        switch longPressGestureRecognizer.state {
        case .began:

            guard let friendship = self.viewModel.friendship else {
                return
            }

            guard let friendshipId = friendship.friendship_id else {
                return
            }

            guard let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as? InstagramPopupViewController else {
                return
            }

            if self.isMonkeyKingBool == false {
                instagramVC.responderAfterDismissal = self.chatTextField
            }

            self.chatTextField.resignFirstResponder()
            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil

            instagramVC.friendshipId = friendshipId
            instagramVC.userId = friendship.user?.user_id
            instagramVC.isMonkeyKingBool = self.isMonkeyKingBool
			
			AnalyticsCenter.log(withEvent: .insgramClick, andParameter: [
				"entrance": "convopage",
				])

            self.present(instagramVC, animated: true, completion: {
                self.initialLongPressLocation = locationPoint
                self.previousLongPressLocation = locationPoint
            })

            self.instagramViewController = instagramVC

        case .changed:
            guard let instagramVC = self.instagramViewController, let initialLocation = self.initialLongPressLocation, let previousLocation = self.previousLongPressLocation else {
                return
            }

            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y

            instagramVC.adjustInstagramConstraints(displacement, velocity)

            self.previousLongPressLocation = locationPoint
        case .cancelled, .ended:
            guard let instagramVC = self.instagramViewController, let initialLocation = self.initialLongPressLocation, let previousLocation = self.previousLongPressLocation else {
                return
            }
            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y

            instagramVC.adjustInstagramConstraints(displacement, velocity, isEnding: true)

            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil
            self.instagramViewController = nil // no longer need a reference to it
        default:
            break
        }
    }

    /// Ensure scrolling the message table does not trigger the change page scroll view pan gesture recognizer
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if (gestureRecognizer == self.chatTableView.panGestureRecognizer || otherGestureRecognizer == self.chatTableView.panGestureRecognizer || gestureRecognizer == self.chatTextField.panGestureRecognizer || otherGestureRecognizer == self.chatTextField.panGestureRecognizer) {
            return false
        }

        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
	
    func applicationWillEnterForeground() {
        self.viewModel.markRead()
    }

    func keyboardWillChangeFrame(notification: NSNotification) {

        guard let userInfo = notification.userInfo else {
            return
        }

        guard let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        // calculate keyboard displacement against window bounds
        let currentViewHeight = Environment.ScreenHeight
        var keyboardDisplacement = currentViewHeight - endFrame.origin.y

        // if we're sliding down, resign first responder on the textview
        /*if self.bottomConstraint.constant > keyboardDisplacement + 5 {
            self.chatTextField.resignFirstResponder()
        }*/
		if keyboardDisplacement > 0 && Environment.isIphoneX {
			keyboardDisplacement -= 34
		}
        self.bottomConstraint.constant = keyboardDisplacement + 5
        self.view.layoutIfNeeded()
    }

    /// This will catch any time people change language, but we only care about dictation so we can hide placeholder
    func changeInputMode(notification : NSNotification) {
        if chatTextField.textInputView.textInputMode?.primaryLanguage == "dictation" {
            self.isShowingPlaceholderText = false
        } else if chatTextField.text.unicodeScalars.first?.value == 65532 { // the unicode for "object replacement character"; occurs when speaker says nothing
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
        self.isShowingPlaceholderText = false
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        if newText.count == 0 {
            self.isShowingPlaceholderText = true
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        let heightOfTextInput = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
        let heightOfTextContainerView = ceil(heightOfTextInput) + 16
        let textHeight = min(heightOfTextContainerView, 85) // Don't go above 3 lines lmao this number
        textView.isScrollEnabled = heightOfTextContainerView > 85
        self.inputHeightConstraint.constant = textHeight
        self.view.setNeedsLayout()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.chatTableView.scrollToBottom(animated: true)
    }

    /// Send message, prevent keyboard dismissal, reset text to ""
    func sendMessage() {
        guard let messageText = self.chatTextField.text, self.chatTextField.text.isEmpty == false else {
            return
        }
		
		if isTrackingMessage == false {
			isTrackingMessage = true
			AnalyticsCenter.log(withEvent: .friendChatClick, andParameter: [
				"type": "message",
				])
		}
		
        if messageText == "/random" { // An easter egg for users to send a random message if they type
            self.viewModel.sendText(nil)
        } else {
            self.viewModel.sendText(messageText)
        }
        self.isShowingPlaceholderText = true

		AnalyticsCenter.log(event: .sentMessageConvo)
        self.view.layoutIfNeeded()
    }

    func sendCancelCallMessage() {
		self.viewModel.cancelCall()
		self.videoCallManager.closeCall()
		self.videoCallManager.delegate = nil
		self.viewModel.sendText("Call canceled")
		self.videoCall = nil
		self.view.layoutIfNeeded()
    }

    @IBAction func addSnapchat(_ sender: Any) {
		AnalyticsCenter.log(withEvent: .friendChatClick, andParameter: [
			"type": "snapchat",
			])
		AnalyticsCenter.log(event: .snapchatClickConvo)
		AnalyticsCenter.log(withEvent: .snapchatClick, andParameter: [
			"entrance": "convopage",
			])
		
        self.viewModel.addSnapchat()
    }

    @IBAction func makeCall(_ sender: JigglyButton) {
		AnalyticsCenter.log(withEvent: .friendChatClick, andParameter: [
			"type": "video_call",
			])
		
        if let videoCall = self.videoCall {
			// video call from my self
			if videoCall.call_out {
				self.callCanceled()
			}else {
				// accept other video call
				videoCall.accept = true
				self.videoCallManager.delegate = self
				self.videoCallManager.connect(with: videoCall)
				self.videoCallManager.sendResponse(type: .Accept)
				self.callButton.isSpinning = true
				self.profileActiveLabel.text = "connecting..."
			}
		}else {
			self.callButton.backgroundColor = Colors.purple
			self.callButton.isJiggling = true
			self.viewModel.initiateCall()
		}
    }

    @IBAction func startConvo(_ sender: UIButton) {
        self.viewModel.sendText(nil)
        sender.isEnabled = false
    }
	
	deinit {
		MessageCenter.shared.delMessageObserver(observer: self)
		NotificationCenter.default.removeObserver(self)
	}
}

extension ChatViewController: MatchServiceObserver {
	func handleMatchError(error: MatchError) {
		guard self.videoCall != nil else { return }
		
		// 服务器上报配对结果，必须在上一步记录检测结果之后
		self.reportCallEnd()
		
		// dismiss chat controller
		self.endVideoCall()
		
		// 断开连接
		self.videoCallManager.disconnect()
	}
	
	fileprivate func reportCallEnd() {
		
	}
	
	func disconnect(reason: MatchError) {
		self.handleMatchError(error: reason)
	}
	
	func remoteVideoReceived(user user_id: Int) {
		guard let videoCall = self.videoCall else { return }
		
		// 如果已经收到所有人的流
		if videoCall.allUserConnected() {
			self.videoCallManager.beginChat()
			self.resetCallStatus()
			self.startVideoCall()
		}
	}
	
	// match message
	func handleReceivedMessage(message: MatchMessage) {
		let type = MessageType.init(type: message.type)
		switch type {
		case .PceOut:
			self.receivePceOut(message: message)
		default:
			self.callViewController?.handleReceivedMessage(message: message)
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
	
	func startVideoCall() {
		guard let videoCall = self.videoCall else { return }
		
		let callViewController = UIStoryboard.init(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "callVC") as! MatchMessageObserver
		self.callViewController = callViewController
		callViewController.present(from: self, with: videoCall, complete: nil)
	}
	
	func endVideoCall() {
		guard self.videoCall != nil else { return }
		self.videoCall = nil
		self.resetCallStatus()
		
		guard let callViewController = self.callViewController else {
			self.videoCallManager.sendResponse(type: .Skip)
			NotificationManager.shared.dismissAllNotificationBar()
			return
		}
		
		self.callViewController = nil
		callViewController.dismiss {
			self.mainViewController?.localPreview.addLocalPreview()
		}
	}
}

extension ChatViewController: InAppNotificationPreActionDelegate {
	func shouldPresentVideoCallNotification(videoCall: VideoCallModel) -> Bool {
		if "\(videoCall.left.user_id)" == self.viewModel.friendship?.user?.user_id {
			return false
		}
		return true
	}
}

/// Mark - ChatSessionLoadingDelegate
extension ChatViewController: MessageObserver {
	
	// 收到对 match 的操作
	func didReceiveMatchSkip(in chat: String) {
		if chat == self.videoCall?.match_id {
			self.callFailed()
		}
	}
	
	func didReceiveMatchAccept(in chat: String) {
		if let videoCall = self.videoCall, chat == videoCall.match_id, videoCall.call_out {
			self.videoCallManager.delegate = self
			self.videoCallManager.connect(with: videoCall)
			self.callButton.isSpinning = true
			self.profileActiveLabel.text = "connecting..."
		}
	}
	
	// 收到对方的 video call
	func didReceiveVideoCall(call: VideoCallModel) {
		if "\(call.left.user_id)" == self.viewModel.friendship?.user?.user_id {
			self.callButton.backgroundColor = Colors.purple
			self.callButton.isJiggling = true
			call.left.accept = true
			self.videoCall = call
		}
	}
	
	func didReceiveCallCancel(in call: String) {
		if call == self.videoCall?.match_id {
			self.callFailed()
		}
	}
}

// MARK: -- Tableview Delegate & Data Source
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var text:String

        if viewModel.pendingMessages.count > 0 && indexPath.row >= viewModel.messages.count {
            let message = viewModel.pendingMessages[indexPath.row - (viewModel.messages.count)]
            text = message.text
        } else {
            guard let message = viewModel.messages?[indexPath.row] else {
                return 0
            }
            guard let realmText = message.text else {
                return 0
            }
            text = realmText
        }

        /// 8 pixels on top and bottom of text
        let textInset: CGFloat = 16
        let stringSize = text.boundingRect(forFont: .systemFont(ofSize: 17), constrainedTo: CGSize(width: 244, height: CGFloat.greatestFiniteMagnitude))

        /// Minimum cell height, lowercase a is shorter than capital A, keep consistent 1 line height

        return stringSize.height + textInset + cellPaddingForIndexPath(indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? MessageTableViewCell)?.sizeCell()
    }
    /// Returns padding dependent on whether or not the cells are sequential in friendship
    func cellPaddingForIndexPath(_ indexPath: IndexPath) -> CGFloat {

        // Check to see if the next message is a PendingMessage
        if viewModel.pendingMessages.count > 0 && indexPath.row >= viewModel.messages.count {
            return 2 // Sequential for pending messages
        }

        // Confirm there's a next message (so we dont get out of bounds in next call)
        if (indexPath.row + 1 == self.viewModel.messages.count) {
            if viewModel.pendingMessages.count > 0 {
                return 2
            }
            return 0
        }

        // Make sure we have a next message
        guard let nextMessage = self.viewModel.messages?[indexPath.row + 1] else {
            return 0
        }

        // Make sure we have a current message
        guard let currentMessage = self.viewModel.messages?[indexPath.row] else {
            return 0
        }

        // Sequential
        if (nextMessage.sender?.user_id == currentMessage.sender?.user_id) {
            return 2
        } else { // nonsequential
            return 14
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isMonkeyKingBool == false {
            self.startConvoButton.isHidden = self.viewModel.messageCount != 0
        }
        return self.viewModel.messageCount
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message") as! MessageTableViewCell

        // If we have pending messages and are at an indexPath past the sent messages, we must be dequeuing a cell for a PendingMessage
        if viewModel.pendingMessages.count > 0 && indexPath.row >= viewModel.messages.count {
            let message = viewModel.pendingMessages[indexPath.row - viewModel.messages.count]
            cell.currentType = .sending
            cell.messageTextView.text = message.text
            cell.chatBubbleView.layer.opacity = 0.25
        } else { // otherwise it's a normal message
            guard let message = viewModel.messages?[indexPath.row] else {
                return MessageTableViewCell()
            }
            if message.sender?.user_id == APIController.shared.currentUser?.user_id {
                cell.currentType = .sending
            } else {
                cell.currentType = .receiving
            }
            cell.messageTextView.text = message.text ?? ""
            cell.chatBubbleView.layer.opacity = 1.0
        }

        cell.messageTextView.dataDetectorTypes = .link
        cell.messageTextView.linkTextAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        cell.sizeCell()

        let bottomInset = cellPaddingForIndexPath(indexPath)
        cell.bottomPaddingConstraint.constant = bottomInset
        cell.topPaddingConstraint.constant = 0

        switch cell.currentType {
        case .sending:
            cell.chatBubbleView.backgroundColor = Colors.purple
        case .receiving:
            cell.chatBubbleView.backgroundColor = Colors.white(0.06)
        }
        return cell
    }

    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith targetURL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        if interaction == .invokeDefaultAction , let scheme = targetURL.scheme{
            if scheme == "http" || scheme == "https" {
                let safariViewController = SFSafariViewController(url: targetURL, entersReaderIfAvailable: false)
                safariViewController.modalPresentationCapturesStatusBarAppearance = true
                safariViewController.modalPresentationStyle = .overFullScreen
                self.present(safariViewController, animated: true)
                return false
            }
        }
        return true
    }
    @available(iOS 9.0, *)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
