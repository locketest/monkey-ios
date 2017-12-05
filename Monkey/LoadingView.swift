//
//  LoadingView.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/14/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import RealmSwift

class LoadingView: MakeUIViewGreatAgain {
    @IBOutlet weak public var acceptButton: BigYellowButton?
    
    @IBOutlet weak var pageViewIndicator: UIPageControl!
    @IBOutlet weak var arrowButton: BigYellowButton!
    @IBOutlet weak var bottomArrowPadding: NSLayoutConstraint!
    
    @IBOutlet var inviteFriendsButton: BigYellowButton!
    
    @IBOutlet weak public var skipButton: BigYellowButton!
    
    @IBOutlet weak public var settingsButton: BigYellowButton!
    @IBOutlet weak var chatButton: BigYellowButton!

    @IBOutlet weak public var loadingTextLabel: LoadingTextLabel!
    @IBOutlet var skippedTextBottomConstraint: NSLayoutConstraint!
    @IBOutlet var skippedText: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bananaView: MakeUIViewGreatAgain!
    @IBOutlet weak var bananaCountLabel: UILabel!
    @IBOutlet weak var bananaViewWidthConstraint:NSLayoutConstraint!

    private var currentTick = 0
    private var timer:Timer?
    private var bananaNotificationToken:NotificationToken?
    private var unreadMessageNotificationToken:NotificationToken?
    private let numberFormatter = NumberFormatter()
    private var friendships:Results<RealmFriendship>?
    weak var delegate:LoadingViewDelegate?
    
    var isLoading = false
    var isTicking = true {
        didSet {
            self.loadingTextLabel?.isTicking = self.isTicking
        }
    }
    
    /// Manages visibility of navigation items (chat and settings button, as well as page control indicator). When true, indicators are not visible. When false, they are visible.
    var navigationItemsHidden = false {
        didSet {
            var alpha: CGFloat = 1
            
            if navigationItemsHidden {
                alpha = 0
            }
            self.settingsButton.alpha = alpha
            self.chatButton.alpha = alpha
            self.pageViewIndicator.alpha = alpha
            self.arrowButton.alpha = alpha
        }
    }
    
    private var isFactTappable = false
    @IBOutlet var factTextView: UITextView!
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        self.isSkip = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
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
        let isNotBlocker = NSPredicate(format: "is_blocking == NO")
        let isNotBlocking = NSPredicate(format: "is_blocking == NO")
        let isInConversation = NSPredicate(format: "last_message_at != nil")
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
        self.setNeedsLayout()
    }
    
    override func awakeFromNib() {
        self.factTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(factTextTapped(_:))))
        self.skipButton?.setTitle(APIController.shared.currentExperiment?.skip_text, for: .normal)
        
        self.pageViewIndicator.isHidden = true
        self.setupBananas()
        self.updateBananas()
        self.setupFriendships()
    }
    
    /// True if the call was just skipped and the UI elements have adjusted but there may still be background work to complete the chat consumption.
    var didSkip = false
    
    var isSkip:Bool = false {
        didSet {
            self.delegate?.statusChanged(loadingView: self, isSkip: isSkip)
            
            if isSkip {
                self.skipButton?.isHidden = false
                self.acceptButton?.isHidden = false
                self.arrowButton.isHidden = true
                self.settingsButton.isHidden = true
                self.chatButton.isHidden = true
                self.pageViewIndicator.isHidden = true
                self.inviteFriendsButton.isHidden = true
                self.bananaView.isHidden = true
            } else {
                self.acceptButton?.isHidden = true
                self.skipButton.isHidden = true
                self.arrowButton.isHidden = false
                self.settingsButton.isHidden = false
                self.chatButton.isHidden = false
                self.pageViewIndicator.isHidden = false
                self.inviteFriendsButton.isHidden = false
                self.bananaView.isHidden = false
            }
        }
    }
    class func instanceFromNib() -> LoadingView {
        let view = UINib(nibName: "LoadingView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LoadingView
        view.factTextView.textContainerInset = .zero
        view.skippedText.layer.opacity = 0.0
        return view
    }
    func setFactText(_ text: String) {
        self.isFactTappable = false
        self.factTextView.isSelectable = true
        self.factTextView.text = text
        self.factTextView.isSelectable = false
    }
    var pendingFactText:String?
    func start(fact: String) {
        pendingFactText = fact
        if let fact = pendingFactText {
            self.isSkip = true
            self.setFactText(fact)
            if self.isLoading {
                return
            }
            self.isLoading = true
            self.layer.opacity = 1
        }
    }
    func skipped() {
        self.skippedText.layer.opacity = 1.0
        // was crashing on
        // self.skippedTextBottomConstraint.constant = 58
        UIView.animate(withDuration: 1.0, animations: {
            self.skippedText.layer.opacity = 0.0
            self.layoutIfNeeded()
        }) { (Bool) in
            //TODO: fix this

           // self.skippedTextBottomConstraint.constant = 20

        }
    }
    func start() {
        if let onboardingFactText = APIController.shared.currentExperiment?.onboarding_fact_text, Achievements.shared.minuteMatches == 0, APIController.shared.currentExperiment?.onboarding_video.value == true {
            self.isFactTappable = true
            self.setFactText(onboardingFactText)
        } else {
            self.isFactTappable = false
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
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        self.delegate?.settingsButtonTapped(loadingView: self)
    }
    @IBAction func chatButtonTapped(_ sender: UIButton) {
        self.delegate?.chatButtonTapped(loadingView: self)
    }
    @IBAction func acceptButtonTapped(_ sender: UIButton) {
        self.delegate?.acceptButtonTapped(loadingView: self)
    }
    @IBAction func skipButtonTapped(_ sender: UIButton) {
        self.delegate?.skipButtonTapped(loadingView: self)
    }
    @IBAction func inviteButtonTapped(_ sender: BigYellowButton) {
        self.delegate?.inviteButtonTapped(loadingView: self)
    }
    @IBAction func titleTextTapped(_ sender: UIButton) {
        self.delegate?.titleTextTapped(loadingView: self)
    }
    @IBAction func modeSelectorTapped(_ sender: UIButton) {
        self.delegate?.modeSelectorTapped(loadingView: self)
    }
    @IBAction func arrowButtonTapped(sender: UIButton) {
        self.delegate?.arrowButtonTapped(loadingView: self)
    }
    func factTextTapped(_ sender: UIButton) {
        if self.isFactTappable {
            self.delegate?.factTextTapped(loadingView: self)
        }
    }
    
    @IBAction func showBananaHint(sender:BigYellowButton) {
        self.delegate?.bananaButtonTapped(loadingView: self)
    }

	func stop(withFade: Bool, completion: (() -> Void)?) {
        if !self.isLoading {
            completion?()
            return
        }
        isLoading = false
        timer?.invalidate()
        self.layer.opacity = 1
        timer = nil
        if withFade && self.isLoading {
            UIView.animate(withDuration: 0.4, animations: {
                self.layer.opacity = 0
            }, completion: { (_) in
                completion?()
            })
        } else {
            self.layer.opacity = 0
            completion?()
        }
    }
    
    deinit {
        self.bananaNotificationToken?.stop()
        self.unreadMessageNotificationToken?.stop()
    }
}

protocol LoadingViewDelegate: class {
    func settingsButtonTapped(loadingView: LoadingView)
    func chatButtonTapped(loadingView: LoadingView)
    func inviteButtonTapped(loadingView: LoadingView)
    func acceptButtonTapped(loadingView: LoadingView)
    func skipButtonTapped(loadingView: LoadingView)
    func factTextTapped(loadingView: LoadingView)
    func modeSelectorTapped(loadingView: LoadingView)
    func titleTextTapped(loadingView: LoadingView)
    func statusChanged(loadingView: LoadingView, isSkip: Bool)
    func arrowButtonTapped(loadingView: LoadingView)
    func bananaButtonTapped(loadingView: LoadingView)
}
