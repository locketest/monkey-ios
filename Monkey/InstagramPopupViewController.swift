//
//  InstagramPopupViewController.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/24/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift

class InstagramPopupViewController: MonkeyViewController, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    /// The user's Monkey profile pic
    @IBOutlet var profileImageView: CachedImageView!
    /// The user's Monkey username
    @IBOutlet var nameLabel: UILabel!
    /// The label below nameLabel, currently displays location
    @IBOutlet var locationLabel: UILabel!
    /// The image view that async loads all the images, then cycles between them with taps
    @IBOutlet var instagramImageView: AsyncCarouselImageView!
    /// A overlay used for displaying a tutorial overlay on first display ever
    @IBOutlet var overlayView: UIView!
    /// An emoji label behind the image used for either loading, or no instagram linked messages
    @IBOutlet var backgroundEmojiLabel: UILabel!
    /// A text view behind the image used for either loading, or no instagram linked messages
    @IBOutlet var backgroundTextView: MakeTextViewGreatAgain!
    /// The root view of this view controller. We animate its color and add tap to dismiss functionality on it
    @IBOutlet var backgroundView: MakeUIViewGreatAgain!
    /// The percent driven transition that animates the pan to dismiss
    var interactiveDismissTransition = DismissPopupTransitionAnimator()
    var responderAfterDismissal: UIResponder?
    /// The user id for the popup. Only passed if no instagram account is linked to be used as a backup data source for UI elements
    /// The view that houses the instagram container
    @IBOutlet weak var unfriendButton: JigglyButton!
    @IBOutlet weak var snapchatButton: BigYellowButton!
    @IBOutlet weak var snapchatButtonTraillingConstraint: NSLayoutConstraint!
    @IBOutlet var instagramContainerView: MakeUIViewGreatAgain!
    var userId: String?
    /// The realm user for the popup. Only passed if no instagram account is linked to be used as a backup data source for UI elements
    /// Implemented as a getter for thread safety
    
    var isMonkeyKingBool : Bool?
    
    let ButtonBgColor = UIColor(red: 107 / 255, green: 68 / 255, blue: 1, alpha: 0.07)
 
    var user: RealmUser? {
        let realm = try? Realm()
        return realm?.object(ofType: RealmUser.self, forPrimaryKey: userId)
    }
    /// How many pixels the instagram container view will have to move up by to accomodate the alert sheet; the value is then artificially added to constraints for a smoother experience
    var alertSheetDisplacement:CGFloat {
        if !self.isShowingFriendsAlertSheet || self.isDismissingFriendsAlertSheet { // if not showing, or its dismissing there's no displacement
            return 0.0
        }
        let totalPixelsAvailableOnBottom = (self.view.frame.height - self.instagramContainerView.frame.height) / 2.0
        let pixelsMissing = totalPixelsAvailableOnBottom - 114.0 - 20.0 - 20.0 // 114 height, 20 pad on bottom and top
        return pixelsMissing <= 0 ? abs(pixelsMissing) : 0.0
    }
    /// The horizontal spacing between channel labels when in the expanded state
    var expandedChannelSpacing:CGFloat = -14.0
    /// The horizontal spacing between channel labels when in the contracted state
    var contractedChannelSpacing:CGFloat = -40.0
    
    /// Is true if we are animating the dismissal of friendOptionsAlertSheetController and we pause updates to transition animator
    /// Note: We need this because transition animators do not allow for other animation blocks to occur.
    var isDismissingFriendsAlertSheet = false
    /// Tracks whether the gesture started while the alert sheet was displayed, if so we want to add the alertSheetDisplacement to our constraints
    var shouldAddDisplacement = false
    /// A constraint used to animate the presentation and dismissal of the friendOptionsAlertSheetController
    var alertBottomConstraint:NSLayoutConstraint?
    /// The spacing constraint between the alertSheet and the instagramContainerView
    var spacingConstraint:NSLayoutConstraint?
    /// An alert sheet that gives friend management options, currently just Block user
    var friendOptionsAlertSheetController = UIAlertController(title: nil, message:nil, preferredStyle:.actionSheet)
    /// True when the alert sheet is showing
    var isShowingFriendsAlertSheet:Bool {
        return self.friendOptionsAlertSheetController.view.superview != nil
    }
    /// The up arrow above the instagram container view. A visual cue to the user that they can swipe up to display the alert sheet
    @IBOutlet var purpleUpButton: BigYellowButton!
    /// A collection of all the user's instagram photos as RealmInstagramPhoto
    var instagramPhotos:List<RealmInstagramPhoto>?
    /// The current instagram photo who's url is being displayed on the instagramImageView
    var displayingInstagramPhoto: RealmInstagramPhoto?
    /// The id for the friendship (if any) between the local user and the user who owns the instagram account they are viewing
    var friendshipId:String?
    /// The friendship, if the user is friends with the profile's user
    var friendship:RealmFriendship? {
        let realm = try? Realm()
        return realm?.object(ofType: RealmFriendship.self, forPrimaryKey: friendshipId)
    }
    /// Vertically centers the instagram container view. The constant is adjusted when the user is panning
    @IBOutlet var instagramContainerViewVerticalCenterConstraint: NSLayoutConstraint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .overFullScreen
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .overFullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let instagramAccount = self.user?.instagram_account
        if instagramAccount == nil {
            self.backgroundEmojiLabel.text = "😢"
            self.nameLabel.text = self.user?.first_name ?? self.user?.username ?? ""
            if let age = self.user?.age.value {
                self.nameLabel.text?.append(" \(age) \(self.isMonkeyKingBool! ? "" : (self.user?.gender == "female" ? "👩":"👱"))")
            }
            self.locationLabel.text = self.user?.location ?? ""
            self.profileImageView.url = self.user?.profile_photo_url
            self.backgroundTextView.text = "Instagram not linked"
            
        } else if !Achievements.shared.shownInstagramTutorial {
            self.overlayView.isHidden = false
            self.instagramImageView.image = #imageLiteral(resourceName: "InstagramTutorialPlaceholder")
        }
        
        self.setupFriendOptionsSheet()
        self.setEmojisForChannelButtons(self.user)
        
        self.setLabelsAndImages(using: instagramAccount)
        
        self.handleMonkeyKingFunc()
    }
    
    func handleMonkeyKingFunc() {
        
        self.purpleUpButton.isHidden = true

        self.snapchatButton.backgroundColor = ButtonBgColor
        
        if self.isMonkeyKingBool! {
            self.locationLabel.text = ""
            self.unfriendButton.isHidden = true
            self.snapchatButtonTraillingConstraint.constant = 9
        } else {
            self.unfriendButton.isHidden = false
            self.unfriendButton.backgroundColor = ButtonBgColor
           self.snapchatButtonTraillingConstraint.constant = 62
        }
    }
    
    @IBAction func unfriendBtnClickFunc(_ sender: BigYellowButton) {
        
        self.unfriendButton.isSelected = !self.unfriendButton.isSelected
        
        if self.unfriendButton.isSelected {
            self.presentFriendOptionsSheet()
        } else {
            self.dismissFriendOptionsSheet()
        }
    }
    
    @IBAction func snapchatBtnClickFunc(_ sender: BigYellowButton) {
        
        guard let username = friendship?.user?.username else {
            print("Error: could not get snapchat username to add")
            return
        }
        
        guard let url = URL(string: "snapchat://add/\(username)") else {
            print("Error: could not get snapchat username to add")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else {
            let backupUrl = URL(string: "https://www.snapchat.com/add/\(username)")!
            UIApplication.shared.openURL(backupUrl)
        }
    }
    
    @IBAction func toggleChannelLabelSpacing(_ tapGestureRecognizer: UITapGestureRecognizer) {
        guard let channels = self.user?.channels else {
            return
        }
        
        if channels.count > 1 {
            UIView.animate(withDuration: 0.25, delay: 0.0, options:.curveEaseOut, animations: {
                self.nameLabel.alpha = self.nameLabel.alpha == 1.0 ? 0.25 : 1.0
                self.profileImageView.alpha = self.profileImageView.alpha == 1.0 ? 0.25 : 1.0
                self.locationLabel.alpha = self.locationLabel.alpha == 1.0 ? 0.25 : 1.0
            })
        }
    }
    
    fileprivate func reloadInstagramAccount(_ instagramAccount: RealmInstagramAccount) {
        instagramAccount.reload(completion: { [weak self] (error: APIError?) in
            guard let `self` = self else { return }
            guard error == nil else {
                error?.log()
                self.backgroundEmojiLabel.text = "😢"
                self.backgroundTextView.text = "Instagram not linked"
                return
            }
            self.nameLabel.text = instagramAccount.user?.first_name ?? instagramAccount.user?.username ?? "Your friend"
            if let age = self.user?.age.value {
                self.nameLabel.text?.append(", \(age)")
            }
            self.locationLabel.text = instagramAccount.user?.location ?? ""
            self.instagramPhotos = instagramAccount.instagram_photos
            self.profileImageView.url = self.user?.profile_photo_url
            self.setEmojisForChannelButtons(self.user)
            
            var urls:[URL] = []
            
            self.instagramPhotos?.forEach({ (photo) in
                guard let url = URL(string:photo.standard_resolution_image_url!) else {
                    return
                }
                urls.append(url)
            })
            self.instagramImageView.loadURLs(urls)
            
            guard let firstPhoto = self.instagramPhotos?.first else {
                print("User has no instagram photos")
                self.backgroundEmojiLabel.text = "🙁"
                self.backgroundTextView.text = "No photos to show"
                return
            }
            self.displayingInstagramPhoto = firstPhoto
        })
    }
    
    func setLabelsAndImages(using account:RealmInstagramAccount?) {
        guard let instagramAccount = account else {
            return
        }
        
        // if available, set values before we reload
        self.nameLabel.text = instagramAccount.user?.first_name ?? instagramAccount.user?.username ?? ""
        if let age = self.user?.age.value {
            self.nameLabel.text?.append(", \(age)")
        }
        self.locationLabel.text = instagramAccount.user?.location ?? ""
        self.profileImageView.url = self.user?.profile_photo_url
        
        reloadInstagramAccount(instagramAccount)
    }
    
    
    /// Iterates through the channels the user is a part of and updates the emojis of the channel buttons
    func setEmojisForChannelButtons(_ user:RealmUser?) {
        
//        guard let channels = user?.channels else {
//            let firstChannel = self.channelStackView.arrangedSubviews[0] as? ChannelLabelView
//            firstChannel?.emojiLabelText = "🍌"
//
//            // We don't use a for-each because we give a default value for the first channelView, and hide the rest
//            for i in 1 ... channelStackView.arrangedSubviews.count - 1 {
//                self.channelStackView.arrangedSubviews[i].isHidden = true
//            }
//            return
//        }
//
//        for (index, view) in channelStackView.arrangedSubviews.enumerated() {
//            if channels.count > index, let channelView = view as? ChannelLabelView, let emoji = channels[index].emoji {
//                channelView.emojiLabelText = emoji
//                continue
//            }
//            // if we don't continue above, we weren't able to set the emoji so hide the view
//            view.isHidden = true
//        }
    }
    
    /// Sets up the friends option sheet if the user has a friendship.
    /// The friends option sheet currently allows the user to block or unfriend
    func setupFriendOptionsSheet() {
        guard let friendship = self.friendship else {
            print("Not setting friend options sheet because uers are not friends")
            self.purpleUpButton.isHidden = true
            return
        }
    
        let unfriendAction = UIAlertAction(title: "Unfriend", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            // Note to future engineers: Confirmation popups are tricky because this action causes a dismiss to be called automatically,
            // and since the alert view is a childVC of the instagramVC that goes dismissed with it

            friendship.delete(completion: { (error:APIError?) in
                if error != nil {
                    error?.log()
                }
                
                self.dismiss(animated: true, completion: nil)
            })
        })
        
        
        let deleteAction = UIAlertAction(title: "Block", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
            // Note to future engineers: Confirmation popups are tricky because this action causes a dismiss to be called automatically,
            // and since the alert view is a childVC of the instagramVC that goes dismissed with it

            guard let userId = friendship.user?.user_id else {
                return
            }
            
            let parameters:[String:Any] = [
                "data": [
                    "type": "blocks",
                    "relationships": [
                        "blocked_user": [
                            "data": [
                                "type": "users",
                                "id": userId,
                            ]
                        ]
                    ]
                ]
            ]
            RealmBlock.create(parameters: parameters, completion: { (result: JSONAPIResult<[RealmBlock]>) in
                switch result {
                case .success(_):
                    break
                case .error(let error):
                    error.log()
                }
            })
        })
        
        friendOptionsAlertSheetController.addAction(unfriendAction)
        friendOptionsAlertSheetController.addAction(deleteAction)
    }
    
    fileprivate func dismissFriendOptionsSheet() {
        guard !self.isDismissingFriendsAlertSheet else {
            return
        }
        
        self.isDismissingFriendsAlertSheet = true
        DispatchQueue.main.async {
            self.alertBottomConstraint?.constant = 134
            UIView.animate(withDuration: 0.2, animations: {
                self.purpleUpButton.layer.opacity = 1.0
                self.view.layoutIfNeeded()
            }){ (Bool) in
                self.isDismissingFriendsAlertSheet = false
                self.shouldAddDisplacement = false
                self.friendOptionsAlertSheetController.willMove(toParentViewController: nil)
                self.friendOptionsAlertSheetController.view.removeFromSuperview()
                self.friendOptionsAlertSheetController.removeFromParentViewController()
                self.alertBottomConstraint = nil
            }
        }
    }
    
    fileprivate func presentFriendOptionsSheet() {
        guard !self.isShowingFriendsAlertSheet else {
            return
        }
        
        // self.present does not work with interactive transition animators. Must add as childVC
        self.addChildViewController(self.friendOptionsAlertSheetController)
        self.view.addSubview(self.friendOptionsAlertSheetController.view)
        let yConstraint = NSLayoutConstraint(item: self.friendOptionsAlertSheetController.view, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        let bottomConstraint =  NSLayoutConstraint(item: self.friendOptionsAlertSheetController.view, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 134)
        let heightConstraint = NSLayoutConstraint(item: self.friendOptionsAlertSheetController.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 114)
        let spacingConstraint =  NSLayoutConstraint(item: self.friendOptionsAlertSheetController.view, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: self.instagramContainerView, attribute: .bottom, multiplier: 1, constant: 20)
        self.spacingConstraint = spacingConstraint
        self.view.addConstraints([yConstraint, bottomConstraint, heightConstraint, spacingConstraint])
        self.alertBottomConstraint = bottomConstraint
        self.friendOptionsAlertSheetController.didMove(toParentViewController: self)
        
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            bottomConstraint.constant = -20
            UIView.animate(withDuration: 0.2, animations: {
                self.purpleUpButton.layer.opacity = 0
                self.view.layoutIfNeeded()
            })
        }
    }
    /// Triggered when user presses purple button above instagram container view, this will show the friends sheet
    @IBAction func showFriendSheet(_ sender: BigYellowButton) {
        self.presentFriendOptionsSheet()
    }
    /// Triggered when a user taps on the instagramPhotoView, this will cause the next instagram image to display
    @IBAction func showNextInstagramPhoto(_ tap: UITapGestureRecognizer) {
        guard self.user?.instagram_account != nil else {
            return
        }
        
        if !Achievements.shared.shownInstagramTutorial {
            self.overlayView.isHidden = true
            self.instagramImageView.next()
            Achievements.shared.shownInstagramTutorial = true
            return
        }
        
        self.instagramImageView.next()
        
        guard let displayingPhoto = self.displayingInstagramPhoto else {
            print("Error: Attempting to switch instagram photo before we are ready")
            return
        }
        
        if displayingPhoto == self.instagramPhotos?.last {
            self.displayingInstagramPhoto = self.instagramPhotos?.first
        } else {
            guard let index = self.instagramPhotos?.index(of: displayingPhoto) else {
                print("Error: Can not find displaying instagram photos in list of available photos")
                return
            }
            self.displayingInstagramPhoto = self.instagramPhotos?[index+1]
        }
    }
    /// Dismisses the viewController when a user taps on the background
    @IBAction func tappedToDismiss(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    /// Calculates and adjusts constraints and progress for intereactive dismissal, this method ensures the UI is in correct state from gesture recognizer data
    ///
    /// - Parameters:
    ///   - displacement: The vertical distance between the intial gesture location and the current gesture location
    ///   - yVelocity: The vertical distance between the previous initial gesture location and the current gesture location
    ///   - isEnding: A boolean indicating whether the gesture is ending and this is the final update
    func adjustInstagramConstraints(_ displacement: CGFloat, _ yVelocity: CGFloat, isEnding:Bool = false) {

        var progress = displacement / self.backgroundView.bounds.size.height
        // interactive dismiss animators take a percent complete value
        progress = min(1.0, max(0.0, progress))
        
        if isEnding {
            if progress > 0.3 && yVelocity > 0 {
                if self.isDismissingFriendsAlertSheet {
                    // if user lets go while dismissing sheet, we'll never have started the transition again, so .finish() wont do anything
                    // we still want to dismiss if thats the case tho
                    self.interactiveDismissTransition.hasStarted = true
                    self.dismiss(animated: true, completion: nil)
                }
                self.interactiveDismissTransition.finish()
            } else {
                self.interactiveDismissTransition.cancel()
                self.instagramContainerViewVerticalCenterConstraint.constant = self.alertSheetDisplacement
            }
            self.interactiveDismissTransition.hasStarted = false
            return
        }
        
        if displacement < 0 { // panning above starting state
            let amountToDisplace = self.shouldAddDisplacement ? self.alertSheetDisplacement : 0
            self.instagramContainerViewVerticalCenterConstraint.constant = (displacement / 4.0) - amountToDisplace // divide by 4 to dampen the displacement
            if displacement < -154 { // 114 alert sheet padding + 20 padding on top and bottom
                if self.friendshipId != nil { // don't display friendsSheet if not friends
                    // We need to cancel the interactive dismiss if it is happening because any animation blocks occur instantly otherwise
                    // This is a problem since we use animation blocks to animate the presentation of the friends alert sheet
                    if self.interactiveDismissTransition.hasStarted {
                        self.interactiveDismissTransition.cancel()
                        self.interactiveDismissTransition.hasStarted = false
                    }
                    // prentation logic is self contained on the didSet of this property
                }
            } else {
                if self.isShowingFriendsAlertSheet && yVelocity > 0 {
                    self.dismissFriendOptionsSheet()
                }
            }
        } else { // if we are panning below starting state
            if self.isShowingFriendsAlertSheet {
                // hides the alert sheet if the user previously panned up to show it
                self.dismissFriendOptionsSheet()
            }
            if self.isDismissingFriendsAlertSheet {
                // since we're not actually updating progress here (because it hijacks all animations)
                // we adjust the constraint so that it still moves with finger
                // it's value is dampened slightly to prevent too large of a misalignment with it's preferred value of self.alertSheetDisplacement
                self.instagramContainerViewVerticalCenterConstraint.constant = displacement / 2.0
                return
            }
            // Once we are done dismissing the alert sheet (or if we never were at all), start the transition
            if self.interactiveDismissTransition.hasStarted == false {
                self.interactiveDismissTransition.hasStarted = true
                self.dismiss(animated: true, completion: nil)
            }
            // We use this to slowly ease the inconsistency that occurs from constraint adjustments
            // while .isDismissingFriendsAlertSheet == true. I have not been able to find a way to cleanly hand the
            // displaced amount to the interactiveDismissTransition's progress, unsightly jumps occur even if they are updated at same time
            // This may potentially be avoided by an interruptible transition (iOS10+, not done because we still support ios9)
            if self.instagramContainerViewVerticalCenterConstraint.constant > self.alertSheetDisplacement {
                // To avoid a large jump in position, we spread out the adjustment as the user pans to allow for a more seamless experience
                self.instagramContainerViewVerticalCenterConstraint.constant = self.instagramContainerViewVerticalCenterConstraint.constant - 1.0
            }
            
            self.interactiveDismissTransition.update(progress) // for positive displacement it's being dismissed so allow the animator to update views
        }
    }
    /// Updates the view based off the pan gesture on the instagram
    ///
    /// The pan gesture currently handles:
    /// - Animating the interactive dismissal of the view controller (via self.interactiveDismissTransition)
    /// - Presenting and dismissing the friends option alert sheet
    @IBAction func handleDismissPanRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let displacement = panGestureRecognizer.translation(in: panGestureRecognizer.view).y
        var progress = displacement / self.backgroundView.bounds.size.height
        // interactive dismiss animators take a percent complete value
        progress = min(1.0, max(0.0, progress))
        
        switch panGestureRecognizer.state {
        case .began:
            self.shouldAddDisplacement = self.isShowingFriendsAlertSheet
        case .changed:
            adjustInstagramConstraints(displacement, panGestureRecognizer.velocity(in: panGestureRecognizer.view).y)
        case .ended, .cancelled:
            adjustInstagramConstraints(displacement, panGestureRecognizer.velocity(in: panGestureRecognizer.view).y, isEnding: true)
        default:
            return
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.interactiveDismissTransition
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentPopupTransitionAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactiveDismissTransition.hasStarted ? self.interactiveDismissTransition : nil
    }
    
    deinit {
        self.instagramImageView.cancel()
    }
}
