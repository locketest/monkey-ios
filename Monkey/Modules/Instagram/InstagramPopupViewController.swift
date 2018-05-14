//
//  InstagramPopupViewController.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/24/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift
import Kingfisher

// photosId为预留字段，暂未用上
typealias PhotoIdAndUrlTuple = (photosId:String, photoUrl:String)

class InstagramPopupViewController: MonkeyViewController, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    /// The user's Monkey profile pic
    @IBOutlet var profileImageView: CachedImageView!
    /// The user's Monkey username
    @IBOutlet var nameLabel: UILabel!
    /// The label below nameLabel, currently displays location
    @IBOutlet var locationLabel: UILabel!
    /// The image view that async loads all the images, then cycles between them with taps
//    @IBOutlet var instagramImageView: AsyncCarouselImageView!
    /// The instagramPhoto background view
    @IBOutlet var instagramPhotosBgView: UIView!
    /// The instagramPhoto background view height constraint
    @IBOutlet var instagramPhotosHeightConstraint: NSLayoutConstraint!
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
    
    var isMonkeyKingBool = false
    
    var followMyIGTagBool = true
    
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
		
        self.setupFriendOptionsSheet()
        
        self.setLabelsAndImages()
        
        self.handleBtnStateFunc()
        
        self.initData()
    }
    
    func initData() {
        if let accountId = user?.instagram_account?.instagram_account_id {
            JSONAPIRequest(url: "\(Environment.baseURL)/api/\(APIController.shared.apiVersion)/instagram_accounts/\(accountId)", options: [
                .header("Authorization", APIController.authorization)
                ]).addCompletionHandler { (response) in
                    switch response {
                    case .error(let error):
                        print(error)
                    case .success(let jsonAPIDocument):
                        
                        if let includes = jsonAPIDocument.included {
                            
                            var dataTupleArray : [PhotoIdAndUrlTuple]! = []
                            
                            if includes.count > 0 {
                                for (index, include) in includes.enumerated() {
                                    if index < (self.followMyIGTagBool ? 8 : 9) { // 如果最后一张图是followMyIG，前面最多显示八张，否则最多显示九张
                                        dataTupleArray.append((photosId: include.id!, photoUrl: include.attributes!["standard_resolution_image_url"]! as! String))
                                    } else { break } // 避免图片过多虽然没有添加图片但循环还是在继续
                                }
                                
                                if self.followMyIGTagBool {
                                    dataTupleArray.append((photosId: "", photoUrl: ""))
                                }
                                
                                self.addInstagramPhotosFunc(dataTupleArray: dataTupleArray)
                            } else {
                                self.instagramPhotosHeightConstraint.constant = 0
                            }
                        }
                    }
            }
        }
    }
    
    func addInstagramPhotosFunc(dataTupleArray:[PhotoIdAndUrlTuple]) {
        
        if dataTupleArray.count > 0 {

            let Padding : CGFloat = 2 // 控件之间的间距

            let Margin : CGFloat = 5 // 边上控件距父控件间距
            
            let totleColumns : CGFloat = 3 // 每行要显示的列数

            let imageButtonW : CGFloat = (self.instagramPhotosBgView.frame.size.width - Margin * 2 - Padding * (totleColumns - 1)) / totleColumns
            let imageButtonH : CGFloat = imageButtonW

            for (index, value) in dataTupleArray.enumerated() {

                let imageButton = UIButton()
                
                imageButton.layer.cornerRadius = 5
                imageButton.layer.masksToBounds = true
                imageButton.adjustsImageWhenHighlighted = false

                let row = index / Int(totleColumns) // 行号等于索引除以每行要显示的列数
                let col = index % Int(totleColumns) // 列号等于索引对每行要显示的列数取摸

                let imageButtonX : CGFloat = Margin + CGFloat(col) * (imageButtonW + Padding)
                let imageButtonY : CGFloat = CGFloat(row) * (imageButtonH + Padding)
                
                if value.photoUrl == "" {
                    imageButton.setImage(UIImage(named: "followMyIGBtn"), for: .normal)
                    imageButton.addTarget(self, action: #selector(followMyIGClickFunc), for: .touchUpInside)
                } else {
					imageButton.kf.setImage(with: URL(string: value.photoUrl), for: .normal, placeholder: UIImage(named: "insDefultImg")!)
				}
                
                imageButton.frame = CGRect(x: imageButtonX, y: imageButtonY, width: imageButtonW, height: imageButtonH)

                self.instagramPhotosBgView.addSubview(imageButton)
            }

            self.instagramPhotosHeightConstraint.constant = (imageButtonH + Padding) * CGFloat(self.countTotalCol(total: dataTupleArray.count, columns: Int(totleColumns)))
        }
    }
    
    func followMyIGClickFunc(sender:UIButton) {
        
        var instagramURL : URL!
        
        let isInstagramInstalledBool = UIApplication.shared.canOpenURL(URL(string: "instagram://")!)
        
        if let accountId = user?.instagram_account?.instagram_account_id {
            
            if isInstagramInstalledBool {
                instagramURL = URL(string: "instagram://user?username=\(accountId)")
            } else {
                instagramURL = URL(string: "http://instagram.com/\(accountId)")
            }
            
            UIApplication.shared.openURL(instagramURL)
        }
    }
    
    func handleBtnStateFunc() {
        
        self.purpleUpButton.isHidden = true

        self.snapchatButton.backgroundColor = ButtonBgColor
        
        if self.isMonkeyKingBool {
            self.locationLabel.text = ""
            self.unfriendButton.isHidden = true
            self.snapchatButtonTraillingConstraint.constant = 9
        } else {
            self.unfriendButton.isHidden = false
            self.unfriendButton.backgroundColor = ButtonBgColor
           self.snapchatButtonTraillingConstraint.constant = 62
        }
        
        // text、chat页面弹出pop时不显示这俩按钮，此逻辑跟monkey king无关
        if !self.followMyIGTagBool {
            self.unfriendButton.isHidden = true
            self.snapchatButton.isHidden = true
        }
    }
    
    /*
     *  计算列数，传入总数和每行需要显示的列数
     */
    func countTotalCol(total:Int, columns:Int) -> Int {
        if total > columns {
            if total % columns == 0 {
                return total / columns
            } else {
                return total / columns + 1
            }
        } else {
            return 1
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
        
        guard let username = user?.snapchat_username else {
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
    
    func setLabelsAndImages() {
        // if available, set values before we reload
		self.nameLabel.text = self.user?.first_name ?? self.user?.username ?? "Your friend"
        if let age = self.user?.age.value {
            self.nameLabel.text?.append(", \(age)")
        }
		
		self.locationLabel.text = ""
		guard isMonkeyKingBool == false else {
			return
		}
		
		self.locationLabel.text = self.user?.location
		if self.user?.isAmerican() == true, let state = self.user?.state {
			self.locationLabel.text = state
		}
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
			
			RealmBlock.create(method: .post, parameters: parameters, completion: { (result: JSONAPIResult<RealmBlock>) in
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
//            self.instagramImageView.next()
            Achievements.shared.shownInstagramTutorial = true
            return
        }
        
//        self.instagramImageView.next()
        
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
//        self.instagramImageView.cancel()
    }
}
