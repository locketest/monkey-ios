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
import DeviceKit

class ChatViewController: SwipeableViewController, ChatViewModelDelegate, UITextViewDelegate, IncomingCallManagerDelegate {
    /// Table showing the conversation as chat bubbles
    @IBOutlet weak var chatTableView: UITableView!
    /// Input view for conversation
    @IBOutlet weak var chatTextField: UITextView!
    /// Image view showing the users profile picture
    @IBOutlet weak var profileImageView:CachedImageView!
    /// Label containing the users name
    @IBOutlet weak var profileNameLabel:UILabel!
    /// Label describing the last time the user was online
    @IBOutlet weak var profileActiveLabel:UILabel!
    /// Bottom constraint for view, changed with keyboard movements
    @IBOutlet var bottomConstraint:NSLayoutConstraint!
    /// Height of chat text view constraint, used to lock when we go past 3 lines
    @IBOutlet var inputHeightConstraint:NSLayoutConstraint!
    @IBOutlet var placeholderTextLabel: UILabel!
    /// Button that opens snapchat when tapped
    @IBOutlet var snapchatButton: BigYellowButton!
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
    let textInset:CGFloat = 12
    let maxBubbleWidth:CGFloat = 244
    var pendingCallId:String?
    /// Is dismissing keyboard
    var isAnimatingDown = false

    var callTimer:Timer?

    var isMonkeyKingBool : Bool?

    let MonkeyKingShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor

    let MonkeyKingBgColor = UIColor(red: 34 / 255, green: 29 / 255, blue: 62 / 255, alpha: 1)

    /// A reference to the presented instagramVC. Currently used to forward longPressGestureRecognizer updates
    weak var instagramViewController: InstagramPopupViewController?
    /// The location of the user's finger when instagram popup is presented, used to calculate displacement to pass to instagramVC if they do not lift finger to pan
    var initialLongPressLocation: CGPoint?
    /// The previous location of the user's finger, used to calculate velocity to pass to instagramVC if they do not lift finger to pan
    var previousLongPressLocation: CGPoint?

    weak var callViewController:CallViewController?
    var nextSessionToPresent:ChatSession?
    var chatSession: ChatSession? {
        didSet {
            guard self.chatSession != oldValue else {
                return
            }

            guard let chatSession = self.chatSession else {
                return
            }

            // it's being passed to us by incomingCallManager
            if chatSession.response != .accepted {
                chatSession.loadingDelegate = self

                self.callButton.backgroundColor = Colors.purple
                self.initiateCallTimer() // call timer just loops noises
                self.callButton.isJiggling = true
            }

            // else: we're the initiator and have already done UI changes so nothing to do
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
                ], to: "patch_friendships", completion: { (error, _) in
                    guard error == nil else {
                        print("Error: Unable to patch friendships")
                        return
                    }
            })
        }
    }

    /// Mark - ChatViewModelDelegate
    /// Received a message, reload data
    func reloadData() {
        self.chatTableView.reloadData()
        self.chatTableView.scrollToBottom(animated: true)

        if !self.isMonkeyKingBool! {
            if (self.viewModel.friendship?.user_is_typing.value ?? false) == true {
                self.profileActiveLabel.text = "typing..."
            } else if self.callButton.isSpinning {
                self.profileActiveLabel.text = "connecting..."
            } else {
                self.profileActiveLabel.text = viewModel.userLastOnlineAtString
            }
        } else{
            self.profileActiveLabel.isHidden = true
        }
    }

    func callFailedBeforeInitializingChatSession() {
        self.callButton.isJiggling = false
        self.callButton.isSpinning = false
        self.sendCancelCallMessage()
        self.stopCallSound()
    }

    /// This method is a callback for the API request to create a RealmCall object. It is only called when user initiates a call.
    func processRecievedRealmCallFromServer(realmVideoCall: RealmVideoCall) {
        guard let sessionId = realmVideoCall.session_id, let chatId = realmVideoCall.chat_id else {
            self.callFailedBeforeInitializingChatSession()
            print("Chat couldn't be created because the server did not return the correct token, chat, or session_id")
            return
        }
		let realm = try? Realm()
		do {
			try realm?.write {
				realmVideoCall.initiator = self.viewModel.friendship?.user
			}
		} catch(let error) {
			print("Error: ", error)
		}

        let chatSession = ChatSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId, chat: Chat(chat_id: chatId, first_name: self.profileNameLabel.text, profile_image_url: self.profileImageView.url, user_id: realmVideoCall.initiator?.user_id), token: realmVideoCall.channelToken, loadingDelegate: self, isDialedCall: true)
        self.chatSession = chatSession
		
		chatSession.accept() // we accept before setting it because didSet checks to see if it's been accepted to differientiate bw initiated and incoming calls
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.delegate = self

        self.chatTableView.delegate = self
        self.chatTableView.dataSource = self

        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height / 2.0
        self.profileImageView.layer.masksToBounds = true

        // Slide down immediately on scroll down
        //TODO: Make interactive https://stackoverflow.com/a/19576934/1767028
        self.chatTableView.keyboardDismissMode = .onDrag

        Socket.shared.isEnabled = true
        self.chatTextField.delegate = self

        // Setup input UITextView to start out with the 'placeholder' text, with proper insets
        self.chatTextField.textContainerInset = UIEdgeInsetsMake(3.7, 3, 3.8, 3)
        self.chatTextField.layer.cornerRadius = 5.0

        self.chatTextField.contentInset = .zero
        self.chatTableView.contentInset = UIEdgeInsetsMake(14, 0, 10, 0)

        self.callButton.emojiLabel = self.callEmojiLabel

        // Hide snapchat button if we dont have a snapchat for them
        if self.viewModel.friendship?.user?.username == nil {
            self.snapchatButton.isHidden = true
        }

        self.handleViewFunc()

        // notifications for keyboard hide/show
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)

        // notification for dictation
        NotificationCenter.default.addObserver(self, selector: #selector(changeInputMode(notification:)), name: .UITextInputCurrentInputModeDidChange, object: nil)
    }

    func handleViewFunc() {

        guard self.isMonkeyKingBool != nil else {
            print("Monkey King user id is nil")
            return
        }

        if self.isMonkeyKingBool! {
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        /// AT LEAST TWO ENGINEERS MUST APPROVE ALL CODE ADDED TO THIS FUNCTION
        self.chatTextField.resignFirstResponder()
        self.updateIsTyping(false)
        /// AT LEAST TWO ENGINEERS MUST APPROVE ALL CODE ADDED TO THIS FUNCTION
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.presentedViewController == nil || self.presentingViewController == nil { // aka not moving to call or getting alert
            NotificationCenter.default.removeObserver(self)
            self.chatSession?.disconnect(.consumed)
            self.stopCallSound()
        }
    }

    @IBAction func aboutUsBtnClickFunc(_ sender: BigYellowButton) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "💖 Rate Us", style: .default, handler: { (UIAlertAction) in
            self.openURL("https://itunes.apple.com/us/app/id1165924249?action=write-review", inVC: true)
        }))
        alertController.addAction(UIAlertAction(title: "📲 Support", style: .default, handler: { (UIAlertAction) in
            self.openURL("https://monkey.canny.io/requests", inVC: true)
        }))

        alertController.addAction(UIAlertAction(title: "🚑 Safety", style: .default, handler: { (UIAlertAction) in

            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIKit.UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            }))
            alertController.addAction(UIKit.UIAlertAction(title: "😐 Terms of Use", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/terms", inVC: true)
            }))
            alertController.addAction(UIKit.UIAlertAction(title: "☹️ Privacy Policy", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/privacy", inVC: true)
            }))
            alertController.addAction(UIKit.UIAlertAction(title: "😇 Safety Center", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/safety", inVC: true)
            }))
            alertController.addAction(UIKit.UIAlertAction(title: "😁 Community Guidelines", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/community", inVC: true)
            }))
            if let creditsURL = APIController.shared.currentExperiment?.credits_url {
                alertController.addAction(UIKit.UIAlertAction(title: "Credits", style: .default, handler: { (UIAlertAction) in
                    self.openURL(creditsURL, inVC: true)
                }))
            }
            self.present(alertController, animated: true, completion: nil)

        }))
        self.present(alertController, animated: true, completion: nil)
    }

    func openURL(_ urlString: String, inVC: Bool)
    {
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

            // TEMP UX FIX: "Will be fixed in 2 weeks" : Sept 14
            // View hierarchy breaks when place call -> open isntagram -> call gets accepted while instagram open
            if let chatSession = self.chatSession, chatSession.response == .accepted { // we are placing a call
                print("Not opening instagram becauase we are placing a call. FIX THIS ALREADY!!")
                return
            }

            guard let friendship = self.viewModel.friendship else {
                return
            }

            guard let friendshipId = friendship.friendship_id else {
                return
            }

            guard let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as? InstagramPopupViewController else {
                return
            }

            if !self.isMonkeyKingBool! {
                instagramVC.responderAfterDismissal = self.chatTextField
            }

            self.chatTextField.resignFirstResponder()
            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil

            instagramVC.friendshipId = friendshipId
            instagramVC.userId = friendship.user?.user_id
            instagramVC.isMonkeyKingBool = self.isMonkeyKingBool!

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // endTransition on DismissPopupAnimator calls view life cycle methods (even if cancelled); dont want keyboard to come up over insta
        if !self.isMonkeyKingBool! {
            self.chatTextField.becomeFirstResponder()
        }
        self.chatTableView.scrollToBottom()

        IncomingCallManager.shared.delegate = self
    }
    func incomingCallManager(_ incomingCallManager: IncomingCallManager, didDismissNotificatationFor chatSession: ChatSession) {

    }
    func incomingCallManager(_ incomingCallManager: IncomingCallManager, shouldShowNotificationFor chatSession: ChatSession) -> Bool {
        guard self.viewModel.friendship?.user?.user_id == chatSession.realmCall?.initiator?.user_id else {
            return true
        }

        guard chatSession != self.chatSession else { // incoming manager trying to send us local, so it's a status update and we ignore
            return false
        }

        if self.chatSession != nil {
            guard let incomingInitiator = chatSession.realmCall?.initiator?.user_id, let localInitiator = self.chatSession?.realmCall?.initiator?.user_id else {
                print("Error: Initiator is missing in RealmCall object")
                return false
            }

            if incomingInitiator != localInitiator { // they both placed call at same time
                guard let incomingCallDateIntervalSince1970 = chatSession.realmCall?.created_at?.timeIntervalSince1970, let localCallDateIntervalSince1970 = self.chatSession?.realmCall?.created_at?.timeIntervalSince1970 else {
                    return false
                }
                if incomingCallDateIntervalSince1970 < localCallDateIntervalSince1970 { // incoming call came first
                    // next chat to accept (act on call end)
                    self.chatSession?.disconnect(.consumed)
                    self.nextSessionToPresent = chatSession
                    return false
                } else { // local call came first
                    chatSession.disconnect(.consumed) // disconnect from external, the other person should connect with above code
                    return false
                }
            }
        }

        chatSession.loadingDelegate = self
        self.chatSession = chatSession
        return false
    }

    func incomingCallManager(_ incomingCallManager: IncomingCallManager, transitionToChatSession chatSession: ChatSession) {
        chatSession.loadingDelegate = self
        self.chatSession = chatSession
    }

    /// Ensure scrolling the message table does not trigger the change page scroll view pan gesture recognizer
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if (gestureRecognizer == self.chatTableView.panGestureRecognizer || otherGestureRecognizer == self.chatTableView.panGestureRecognizer || gestureRecognizer == self.chatTextField.panGestureRecognizer || otherGestureRecognizer == self.chatTextField.panGestureRecognizer) {
            return false
        }

        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let friendship = self.viewModel.friendship {
            let user = friendship.user
            self.profileImageView.url = user?.profile_photo_url
            self.profileNameLabel.text = user?.first_name ?? user?.snapchat_username ?? user?.username ?? ""
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
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
        let currentViewHeight = UIApplication.shared.keyWindow?.bounds.height
        let keyboardDisplacement = currentViewHeight! - endFrame.origin.y

        // if we're sliding down, resign first responder on the textview
        /*if self.bottomConstraint.constant > keyboardDisplacement + 5 {
            self.chatTextField.resignFirstResponder()
        }*/
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
        if messageText == "/random" { // An easter egg for users to send a random message if they type
            self.viewModel.sendText(nil)
        } else {
            self.viewModel.sendText(messageText)
        }
        self.isShowingPlaceholderText = true

		AnaliticsCenter.log(event: .sentMessageConvo)

        self.view.layoutIfNeeded()
    }

    func sendCancelCallMessage() {
        if let chatSession = self.chatSession {
            IncomingCallManager.shared.cancelVideoCall(chatsession: chatSession)
        }

        self.viewModel.sendText("Call canceled")
        self.view.layoutIfNeeded()
    }

    @IBAction func addSnapchat(_ sender: Any) {
        self.viewModel.addSnapchat()
    }

    @IBAction func makeCall(_ sender: JigglyButton) {
        if let chatSession = self.chatSession {
            if chatSession.response == .accepted && chatSession.status != .consumed && chatSession.status != .consumedWithError {
                chatSession.disconnect(.consumed)
                self.stopCallSound()
                self.callButton.isJiggling = false
                self.callButton.backgroundColor = Colors.white(0.06)
            } else {
                self.callButton.isSpinning = true
                self.isMonkeyKingBool! ? (self.profileActiveLabel.isHidden = true) : (self.profileActiveLabel.text = "connecting...")
                self.chatSession?.accept()
			}
            return
        }
        self.callButton.isJiggling = true
        self.initiateCallTimer()
        self.viewModel.initiateCall()
    }


    @IBAction func startConvo(_ sender: UIButton) {
        self.viewModel.sendText(nil)
        sender.isEnabled = false
    }


}

/// Mark - ChatSessionLoadingDelegate
extension ChatViewController: ChatSessionLoadingDelegate {
    func presentCallViewController(for chatSession:ChatSession) {
        self.callButton.isSpinning = false
        self.callButton.isJiggling = false
        self.callButton.backgroundColor = Colors.white(0.06)
        self.stopCallSound()
        self.chatTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }) { (Bool) in
            let callViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "callVC") as! CallViewController
            self.callViewController = callViewController
            self.callViewController?.chatSession = self.chatSession
            self.chatSession?.callDelegate = callViewController

            self.present(callViewController, animated: false)

            Achievements.shared.totalChats += 1
        }
    }

    func chatSession(_ chatSession: ChatSession, callEndedWithError error:Error?) {
        self.callButton.isSpinning = false
        self.callButton.isJiggling = false
        self.stopCallSound()
        if !chatSession.matchUserDidAccept {
            self.sendCancelCallMessage()
        }

        self.chatSession = nil
        self.isMonkeyKingBool! ? (self.profileActiveLabel.isHidden = true) : (self.profileActiveLabel.text = viewModel.userLastOnlineAtString)

        if let nextSessionToPresent = self.nextSessionToPresent {
            self.nextSessionToPresent = nil
            nextSessionToPresent.loadingDelegate = self
            nextSessionToPresent.accept() // accept external (must be done before self.chatSession or else it will think its an unaccepted incoming call and trigger purple and calls)
            self.chatSession = nextSessionToPresent
        }

        self.callButton.backgroundColor = Colors.white(0.06)
    }

    func dismissCallViewController(for chatSession:ChatSession) {

        HWCameraManager.shared().removePixellate()
        HWCameraManager.shared().changeCameraPosition(to: .front)

        self.callButton.isJiggling = false
        self.callButton.isSpinning = false // sets jiggling to false if its true so captures both
        self.stopCallSound()

        chatSession.chat?.update(callback: nil)
		let presentingViewController = self.callViewController?.presentingViewController
		
//		UIView.animate(withDuration: 0.2, animations: {
//			self.colorGradientView.alpha = 1.0
//			presentingViewController?.view.alpha = 1.0
//		}) { (Bool) in
//			self.containerView.setNeedsLayout()
//			self.matchViewController = nil
//		}

        print("Consumed")
        UIView.animate(withDuration: 0.3, animations: {
            self.callViewController?.isPublisherViewEnlarged = true
            self.callViewController?.view.layoutIfNeeded()
        }) { [weak self] (success) in
            presentingViewController?.dismiss(animated: false) {
                let publisherContainerView = self?.presentingViewController!.presentingViewController!.view
                publisherContainerView?.insertSubview(HWCameraManager.shared().localPreviewView, at: 0)
                HWCameraManager.shared().localPreviewView.translatesAutoresizingMaskIntoConstraints = false
                let viewsDict = ["view": HWCameraManager.shared().localPreviewView,]
                publisherContainerView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
                publisherContainerView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
                UIView.animate(withDuration: 0.2, animations: {
                    self?.view.alpha = 1.0
					presentingViewController?.view.alpha = 1.0
                }) { (Bool) in
					self?.callViewController = nil
				}
            }
        }
    }

    func shouldShowConnectingStatus(in chatSession: ChatSession) {
        // do noting
    }

    internal func initiateCallTimer() {

        self.stopCallSound()
        self.callTimer = Timer(timeInterval: 2.52, target: self, selector: #selector(playCallSound), userInfo: nil, repeats: true)
        RunLoop.main.add(self.callTimer!, forMode: .commonModes)
        self.callTimer?.fire()
    }

    func playCallSound() {
        DispatchQueue.global().async {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, with: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
        }
        SoundPlayer.shared.play(sound: .call)
    }

    func stopCallSound() {
        SoundPlayer.shared.stopPlayer()
        self.callTimer?.invalidate()
        self.callTimer = nil
    }

    func acceptChat(chatId:String) {
        IncomingCallManager.shared.delegate = self
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
        let textInset:CGFloat = 16
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
        if !self.isMonkeyKingBool! {
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
