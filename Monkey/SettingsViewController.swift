//
//  SettingsViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 1/9/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Alamofire
import SafariServices
import MessageUI
import SafariServices
import ObjectMapper
import RealmSwift



class SettingsViewController: SwipeableViewController, UITableViewDelegate, SettingsBooleanTableViewCellDelegate, SettingsHashtagCellDelegate, MFMessageComposeViewControllerDelegate, UITableViewDataSource, ProfilePhotoButtonViewDelegate,UITextFieldDelegate {

    @IBOutlet var containerView: MakeUIViewGreatAgain!

    @IBOutlet weak var stuffView: MakeUIViewGreatAgain!
    
//    @IBOutlet weak var placeholderView: MakeUIViewGreatAgain!
  
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contentScrollview: UIScrollView!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var editButtons: UIButton!
    @IBOutlet weak var timeOnMonkey: UILabel!
    @IBOutlet weak var firstName: UILabel!

    @IBOutlet weak var linkInstgramLabel: UILabel!
    
    @IBOutlet weak var profilePhoto: ProfilePhotoButtonView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleButton: UIButton!

    @IBOutlet weak var profileView:UIView!

    @IBOutlet weak var dismissTapGestureRecognizer:UITapGestureRecognizer!

    var inviteFriendsViewController: MFMessageComposeViewController?

    var editProfileView:UIView!
    var editProfileContentView:UIView!
    /// edit Profile UI
    var firstNameField:UITextField! //名字
    var birthdayField:UITextField!  //生日
    var snapChatUserName:UsernameTextField! //snap chat
    var editStatus:Bool! //编辑状态，控制手势滑动
    var firstNameTipLab:UILabel! //名字提示lab
    var birthdayTipLab:UILabel! //生日提示
    var snchatTipLab:UILabel! //生日提示
    var pickerContainerView:UIView! //年龄选择
    var editBirthdayStatus:Bool!
    var cancelBtn:UIButton!
    var saveBtn: BigYellowButton!
    var datePicker:BirthdatePicker!
	var userOption: UserOptions?
    var keyBoardWasShow:Bool!
    ///end edit Profile UI

    /// A reference to the presented instagramVC. Currently used to forward longPressGestureRecognizer updates
    weak var instagramViewController: InstagramPopupViewController?
    /// The long press gesture responsible for presenting the instagram popover
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    /// The location of the user's finger when instagram popup is presented, used to calculate displacement to pass to instagramVC if they do not lift finger to pan
    var initialLongPressLocation: CGPoint?
    /// The previous location of the user's finger, used to calculate velocity to pass to instagramVC if they do not lift finger to pan
    var previousLongPressLocation: CGPoint?

    /// Returns the content size of the view, is a getter because TODO: replace with actual calculation of content within view
    override var contentHeight: CGFloat {
        if self.keyBoardWasShow {
            return UIScreen.main.bounds.size.height
        }else {
            return ScreenHeight - self.contentScrollview.frame.minY
        }
    }

    var headImageInited = false

    var lastY: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
		
        self.keyBoardWasShow = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.bounces = true
        self.tableView.register(SettingTalkToCell.self, forCellReuseIdentifier: "SettingTalkToCell")
        self.tableView.register(SettingAcceptButtonCell.self, forCellReuseIdentifier: "AcceptBtnCell")
        self.setupInviteFriendsViewController()
        self.profilePhoto.delegate = self
        profilePhoto.presentingViewController = self
        profilePhoto.lightPlaceholderTheme = true

        NotificationCenter.default.addObserver(self, selector: #selector(instagramNotificationReceived(_:)), name: .instagramLoginNotification, object: nil)

        if let firstName = APIController.shared.currentUser?.first_name {
            self.firstName.text = firstName
        }

        if let secondsInApp = APIController.shared.currentUser?.seconds_in_app.value {
            var localizedTime = ""
            if secondsInApp < 60 {
                localizedTime = "1 min"
            } else if secondsInApp < 3600 {
                localizedTime = "\(secondsInApp / 60) min"
            } else if secondsInApp < 7200 {
                localizedTime = "1 hour"
            } else {
                localizedTime = "\(secondsInApp / 60 / 60) hours"
            }
            timeOnMonkey.text = localizedTime + " on Monkey"
        }

        self.editProfileView = UIView.init(frame: CGRect(x: UIScreen.main.bounds.size.width, y: self.containerView.frame.origin.y, width: self.containerView.frame.size.width, height: self.containerView.frame.size.height+self.stuffView.frame.size.height))
        self.editProfileView.backgroundColor = UIColor.clear
        self.view.addSubview(self.editProfileView)
        self.editProfileView.layer.cornerRadius = self.containerView.layer.cornerRadius
        self.editProfileView.layer.masksToBounds = true
        
       
        let editProfileTitleLab:UILabel = UILabel.init(frame: CGRect(x:0,y:0,width:UIScreen.main.bounds.size.width,height:30))
        //foregroundColor
        editProfileTitleLab.backgroundColor = UIColor.init(white: 0, alpha: 0.56)
        let attributedString = NSMutableAttributedString(string: " ✏️ Edit Profile", attributes: [
            NSFontAttributeName: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightMedium),
            NSForegroundColorAttributeName: UIColor(white: 154.0 / 255.0, alpha: 1.0)
            ])
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: 3))
        editProfileTitleLab.attributedText = attributedString
        self.editProfileView.addSubview(editProfileTitleLab)

        let blurEffect = UIBlurEffect(style: .dark)
        //创建一个承载模糊效果的视图
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(x: 0, y: 30, width: UIScreen.main.bounds.size.width, height: self.editProfileView.height)
        blurView.autoresizingMask = UIViewAutoresizing.flexibleHeight
        self.editProfileView.addSubview(blurView)
        
        editProfileContentView =  UIView.init(frame: CGRect(x: 0, y: 30, width: UIScreen.main.bounds.size.width, height: self.editProfileView.height - 30))
        editProfileContentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.editProfileView.addSubview(editProfileContentView)
        self.editBirthdayStatus = false
		self.contentScrollview.showsVerticalScrollIndicator = false
        
		self.crateEditProfileUI()
        self.contentScrollview.bounces = false
        ScreenHeight < 666 ? (self.scrollViewHeightConstraint.constant = ScreenHeight - 44) : (self.scrollViewHeightConstraint.constant = 578)
        
        var tapGesture = UITapGestureRecognizer(target: self,action:#selector(handleTapGesture))
        self.profileView.addGestureRecognizer(tapGesture)
    }
    func handleTapGesture(){
        self.panningTowardsSide = .top
       self.dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		self.refreshEditStatus()
    	self.resetEditProfileFrame()
		self.firstName.text = APIController.shared.currentUser?.first_name
        print("left margin\(self.leftMargin)")
    }
	
    func resetEditProfileFrame(){
        self.pickerContainerView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width, height: 220);
        self.editProfileView.frame = CGRect(x:UIScreen.main.bounds.size.width,y:self.contentScrollview.y+self.profileView.height+5,width:ScreenWidth-10,height:self.contentScrollview.height-self.profileView.height-5)
        self.editButtons.setImage(UIImage(named:"EditProfileButtton"), for: .normal)
        self.editButtons.isSelected = false
        self.containerView.isHidden = false
        
        self.containerView.x = 0
        self.stuffView.x = 0
        self.contentScrollview.isScrollEnabled = true
        self.profileView.isHidden = false
        self.stuffView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.resetEditProfileFrame()
        if !headImageInited {
            headImageInited = true
            if let photoURL = APIController.shared.currentUser?.profile_photo_upload_url {
                _ = ImageCache.shared.load(url: photoURL, callback: {[weak self] (result) in
                    switch result {
                    case .error(let error):
                        print("Get user profile photo error : \(error)")
                    case .success(let cacheImage):
                        if let image = cacheImage.image {
                            self?.profilePhoto.setProfile(image: image)
                        }
                    }
                })
            }
        }

		NotificationCenter.default.addObserver(self, selector:#selector(self.keyBoardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector:#selector(self.keyBoardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
	}

	func refreshEditStatus() {
		JSONAPIRequest(url: "\(Environment.baseURL)/api/\(UserOptions.api_version)/\(UserOptions.requst_subfix)", options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler {[weak self] (response) in
			switch response {
				case .error( _): break
				case .success(let jsonAPIDocument):
					do {
					self?.userOption = Mapper<UserOptions>().map(JSON: jsonAPIDocument.json)
                    let canEditUserBirthday = (self?.userOption?.update_birth_date)!

                    if canEditUserBirthday{
                        self?.birthdayField.isUserInteractionEnabled = true
                        self?.birthdayField.textColor = UIColor.white.withAlphaComponent(0.7);
                    }else{
                        self?.birthdayField.isUserInteractionEnabled = false
                        self?.birthdayField.textColor = UIColor.white.withAlphaComponent(0.5);
                    }
                    //服务器返回的时间是 未来能修改的那一天的日期,不是返回的修改日期
					let time = self?.userOption?.update_username.timeIntervalSince1970 ?? 0
					let now = Date().timeIntervalSince1970*1000


					let canEdit = time - now  < 0
                    let sec:Double = abs(now - time)/1000
					let min:Double = floor(sec/60)
					let hr:Double = floor(min/60)
					var d:Int = Int(floor(hr/24))

					if canEdit == true {
                        self?.firstNameField.isUserInteractionEnabled = true
                        self?.firstNameTipLab.text = ""
                        self?.firstNameField.textColor = UIColor.init(white: 1, alpha: 0.7)
                    }else{
                        if d<1{
                            d = 1
                        }
                        self?.firstNameField.textColor = UIColor.init(white: 1, alpha: 0.5)
                        self?.firstNameField.isUserInteractionEnabled = false
                        self?.firstNameTipLab.text = "You can change your name after \(d) days"
                    }
//self?.birthdayField.isUserInteractionEnabled = true
				}
			}
		}
	}

    internal func showAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.editStatus {
            self.editCancelButtonClick()
            self.editStatus = false
        }

        self.view.endEditing(true)
    }

    func selectedHashtag(id: String, tag: String) {
        fatalError("Not implemented")
    }

    func profilePhotoButtonView(_ profilePhotoButtonView: ProfilePhotoButtonView, selectedImage: UIImage) {
        self.profilePhoto.profileImage = selectedImage
        self.profilePhoto.uploadProfileImage {
            print("Uploaded profile image")
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // false so that swiping to side during longPress does not try to dismiss friendsVC (to go to mainVC) while instagramVC is presented
        if gestureRecognizer == self.panGestureRecognizer && gestureRecognizer != self.longPressGestureRecognizer  {
            return false
        }

        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        self.placeholderView.isHidden = true
        return !self.editStatus
    }

    func instagramNotificationReceived(_ notification:Notification) {
        guard let loginParameters = notification.object as? [String:Any] else {
            print("Error: notification posted without an object")
            return
        }
        guard loginParameters["error_reason"] as? String != "user_denied" else {
            return // Web view will be dismissed.
        }
        guard let code = loginParameters["code"] as? String else {
            let errorMessage = loginParameters["error_description"] as? String
            let instagramFailedAlert = UIAlertController(title: "😬 Couldn't link Instagram", message: errorMessage?.replacingOccurrences(of: "+", with: " ") ?? "Try again", preferredStyle: .alert)
            instagramFailedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(instagramFailedAlert, animated: true)
            return
        }

        self.linkInstagramToUser(code)
    }

    func linkInstagramToUser(_ code:String) {

        let parameters:[String:Any] = [
            "data": [
                "type": "instagram_accounts",
                "attributes": ["code":code],
                ]
        ]

        RealmInstagramAccount.create(parameters: parameters) { [weak self] (result: JSONAPIResult<[RealmInstagramAccount]>) in
            switch result {
            case .success(_):
                self?.linkInstgramLabel.text = "📸 Link instagram"
                break
            case .error(let error):
                error.log()
                let instagramFailedAlert = UIAlertController(title: "😬 Error linking Instagram", message: "Please try again", preferredStyle: .alert)
                instagramFailedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self?.present(instagramFailedAlert, animated: true)
            }
        }
    }

    func saveGenderPreference(gender : String?) {

    }

	func savePreferenceClick() {
		guard let currentUser = APIController.shared.currentUser else {
			return
		}

        let alpha:Bool = self.saveBtn.alpha == 1.0
        if !alpha{
            self.editCancelButtonClick()
            return
        }

		var attributes: [RealmUser.Attribute] = []
        var editFirstName :Bool = false
        var editBirthDay :Bool = false
		if let newFirstName = self.firstNameField.text, newFirstName != currentUser.first_name {
			attributes.append(.first_name(newFirstName))
            editFirstName = true
		}

		if let newBirthdayStr = self.birthdayField.text {
			if let oldBirthday = currentUser.birth_date {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "MM/dd/yyyy"
				let oldBirthdayDate = Date.init(timeIntervalSince1970: oldBirthday.timeIntervalSince1970)
				let oldBirthdayStr = dateFormatter.string(from: oldBirthdayDate)
				if (newBirthdayStr != oldBirthdayStr) {
					attributes.append(.birth_date(self.datePicker.date as NSDate))
                    editBirthDay = true
				}
			}
		}

		if let newSnapchatName = self.snapChatUserName.text, newSnapchatName != currentUser.snapchat_username {
			attributes.append(.snapchat_username(newSnapchatName))
		}

		if attributes.count > 0 {
			saveBtn.isLoading = true

			currentUser.update(attributes: attributes) { (error) in
				self.saveBtn.isLoading = false
				// 保存请求返回结果

				guard error == nil else {
                    if error?.status == "400" {
                        return self.present(error!.toAlert(onOK: { (UIAlertAction) in
                            //
                        }), animated: true, completion: nil)
                    }
                    self.present(error!.toAlert(onRetry: { (UIAlertAction) in
                        self.savePreferenceClick()
                    }), animated: true, completion: nil)
                    return
				}

				var userProperty = [String: Any]()

				currentUser.first_name.then {
					userProperty["first_name"] = $0
				}

				currentUser.snapchat_username.then {
					userProperty["snapchat_username"] = $0
				}

				currentUser.birth_date.then {
					userProperty["birth_date"] = $0
				}
                DispatchQueue.main.async {
                    self.editBirthdayStatus = false
                    if editBirthDay{
                        self.birthdayField.isUserInteractionEnabled = false
                        self.birthdayTipLab.text = ""
                    }
//

                    if editFirstName{
                        self.firstNameField.isUserInteractionEnabled = false
						self.firstName.text = currentUser.first_name
                    }
                   self.editCancelButtonClick()
                    self.refreshEditStatus()
                    self.view.endEditing(true)
//                    self.saveBtn.isUserInteractionEnabled = false
                }
				AnaliticsCenter.update(userProperty: userProperty)
				// 保存成功
			}
        }else{
            self.editCancelButtonClick()
        }
	}

    @IBAction func presentInstagramController(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let locationPoint = longPressGestureRecognizer.location(in: self.longPressGestureRecognizer.view)

        switch longPressGestureRecognizer.state {
        case .began:

            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil

            guard let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as? InstagramPopupViewController else {
                return
            }
            instagramVC.userId = APIController.shared.currentUser?.user_id
            self.present(instagramVC, animated: true, completion: {
                self.initialLongPressLocation = locationPoint
                self.previousLongPressLocation = locationPoint
            })

            self.instagramViewController = instagramVC

        case .changed:
            guard let instagramVC = self.instagramViewController else {
                print("Error: can not forward touches to instagramVC since reference is invalid")
                return
            }
            guard let initialLocation = self.initialLongPressLocation else {
                print("Error: can not calculate displacement since no initialLongPressLocation")
                return
            }
            guard let previousLocation = self.previousLongPressLocation else {
                print("Error: can not caluclate velocity since no previousLongPressLocation")
                return
            }

            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y

            instagramVC.adjustInstagramConstraints(displacement, velocity)

            self.previousLongPressLocation = locationPoint
        case .cancelled, .ended:
            guard let instagramVC = self.instagramViewController else {
                print("Error: can not forward touches to instagramVC since reference is invalid (.ended)")
                return
            }
            guard let initialLocation = self.initialLongPressLocation else {
                print("Error: can not calculate displacement since no initialLongPressLocation (.ended)")
                return
            }
            guard let previousLocation = self.previousLongPressLocation else {
                print("Error: can not caluclate velocity since no previousLongPressLocation (.ended)")
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
    @IBAction func editProfileTapped(_ sender: UIButton) {
        let  settingRect:CGRect = CGRect(x:-self.view.frame.size.width,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height);
        sender.isUserInteractionEnabled = false
        self.view.layoutIfNeeded()
        self.view.bringSubview(toFront: self.editProfileView)
        let profileHeigh:CGFloat = self.profileView.frame.size.height
        let  editprofileRect:CGRect = CGRect(x:5,y:self.contentScrollview.y+profileHeigh+5,width:ScreenWidth-10,height:ScreenHeight-(self.contentScrollview.y+profileHeigh+5)-26)
        self.keyBoardWasShow = false
        self.editProfileView.frame = CGRect(x:self.editProfileView.x,y:self.contentScrollview.y+profileHeigh+5,width:self.editProfileView.width,height:ScreenHeight-(self.contentScrollview.y+profileHeigh+5)-26)
        self.editProfileView.setNeedsLayout()
        //
        self.contentScrollview.setContentOffset(CGPoint(x:0,y: 0), animated: false)
        if self.editButtons.isSelected {
            self.editButtons.setImage(UIImage(named:"EditProfileButtton"), for: .normal)
            self.editButtons.isSelected = false
            self.containerView.isHidden = false
            self.editStatus = false
            self.contentScrollview.isScrollEnabled = true
            UIView.animate(withDuration:0.35, animations: {
                self.editProfileView.x = ScreenWidth
                self.view.layoutIfNeeded()
                self.containerView.x = 0
                self.stuffView.x = 0
            }) { (completed) in
                sender.isUserInteractionEnabled = true
            }
        }else{
            self.editStatus = true
            self.editButtons.isSelected = true
            self.editButtons.setImage(UIImage(named:"edit_profile_backbtn_icon"), for: .normal)
            self.contentScrollview.isScrollEnabled = false
            if let currentUser:RealmUser = APIController.shared.currentUser{
                self.firstNameField.text = currentUser.first_name
                self.snapChatUserName.text = currentUser.snapchat_username;

                if let birthday = currentUser.birth_date {
                    self.datePicker.date = Date.init(timeIntervalSince1970: birthday.timeIntervalSince1970)
                    self.birthdayField.text = self.datePicker.formattedDate
                }
            }

 print("tap \(editprofileRect)")
            UIView.animate(withDuration:0.35, animations: {
                self.view.layoutIfNeeded()
                self.editProfileView.frame = editprofileRect
                self.containerView.frame = settingRect
                self.editProfileContentView.height = self.editProfileView.height-30
                self.stuffView.frame = CGRect(x: -self.view.frame.size.width, y: self.stuffView.frame.origin.y, width: self.stuffView.frame.size.width, height: self.stuffView.frame.size.height)
            }) { (completed) in
                UIView.animate(withDuration: 0.15, animations: {
                    self.containerView.isHidden = true
                }, completion: { done in
                    sender.isUserInteractionEnabled = true
                })
                print("222tap \(self.editProfileView.frame)")
                self.view.layoutIfNeeded()
            }
        }
    }

    func linkInstagram() {
        guard let loginUrl = APIController.shared.currentExperiment?.instagram_login_url else {
            return
        }

        let instagramWebViewController = SFSafariViewController(url: URL(string:loginUrl)!, entersReaderIfAvailable: false)
        instagramWebViewController.modalPresentationStyle = .overFullScreen
        instagramWebViewController.delegate = self
        self.present(instagramWebViewController, animated: true, completion: nil)
    }

    func unlinkInstagram() {
        guard let user = APIController.shared.currentUser else {
            return
        }

        user.update(relationship:"instagram_account", resourceIdentifier:nil) { (error:APIError?) in
            guard error == nil else {
                error?.log()
                return
            }
            
            self.linkInstgramLabel.text = "🌅 Unlink instagram"

            print("Instagram account unlinked & deleted")
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
        result: MessageComposeResult)
    {
		if result == .sent {
			AnaliticsCenter.log(event: .inviteFriendSuccess)
		}
        self.dismiss(animated: true, completion: {
//            self.setupInviteFriendsViewController()
        })
    }
    func setupInviteFriendsViewController() {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        self.inviteFriendsViewController = MFMessageComposeViewController()
        self.inviteFriendsViewController?.body = APIController.shared.currentExperiment?.sms_invite_friends
        self.inviteFriendsViewController?.messageComposeDelegate = self
    }
/*
    override func viewDidLayoutSubviews() {
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        // Code below will make height correct
        // 100 is height of other content besides table view content we need to account for
        if self.tableView.contentSize.height > UIScreen.main.bounds.height - 100 {
            // On small devices, we want to fill the screen with the table view
            self.view.addConstraints([
                NSLayoutConstraint(item: self.containerView,
                                   attribute: .top, relatedBy: .equal,
                                   toItem: self.view, attribute: .top,
                                   multiplier: 1, constant: 22),
                ])
         } else {
            let settingsHeight = self.tableView.contentSize.height + 34
            self.view.addConstraints([
                NSLayoutConstraint(item: self.containerView,
                                   attribute: .height, relatedBy: .equal,
                                   toItem: nil, attribute: .notAnAttribute,
                                   multiplier: 1, constant: settingsHeight),
                ])
        }
        super.viewDidLayoutSubviews()
    }
 */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell else {
            return
        }
        guard let data = cell.data else {
            return
        }
        switch data.type {

        case .signOut:
            RealmDataController.shared.deleteAllData() { (error) in
                guard error == nil else {
                    error?.log()
                    return
                }
                APIController.authorization = nil
                UserDefaults.standard.removeObject(forKey: "user_id")
                Apns.update(callback: nil)


                let rootVC = self.view.window?.rootViewController
                rootVC?.presentedViewController?.dismiss(animated: false, completion: {
                    DispatchQueue.main.async {
                        rootVC?.dismiss(animated: true, completion: nil)
                    }
                })
            }
        case .editProfile:
            // Edit profile has been combined with editAccount, the information is all on one page
            // The logic actually hasnt been rewritten, however, since currently we do not allow for the user to edit these values (this is legacy code)
            break
        case .inviteFriends:
            guard let inviteFriendsViewController = self.inviteFriendsViewController else {
                return
            }
            self.present(inviteFriendsViewController, animated: true, completion: nil)
		case .aboutUS:
			break;
        case .talkTo:
            break;
        case .acceptButton:
            break;
        }
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


    internal func buttonStatesChanged(settingsTableViewCell: SettingsBooleanTableViewCell) {
        if settingsTableViewCell.data?.firstOption?.isSelected == true {
            UserDefaults.standard.set("female", forKey: "show_gender")
        } else if settingsTableViewCell.data?.firstOption?.isSelected == true {
            UserDefaults.standard.set("male", forKey: "show_gender")
        }
    }
    var secretButtonTimer:Timer?
    func showSecret() {
        // Ben told me to get
        //self.hideSettingsView()
        //self.present(self.storyboard!.instantiateViewController(withIdentifier: "secretsVC"), animated: true, completion: nil)
    }
    @IBAction func secretsButtonStartHolding(_ sender: UIButton) {
        self.secretButtonTimer = Timer.scheduledTimer(timeInterval: 2,
                                                      target: self,
                                                      selector: #selector(self.showSecret),
                                                      userInfo: nil,
                                                      repeats: false)
    }
    @IBAction func secretsButtonStopHolding(_ sender: UIButton) {
        self.secretButtonTimer?.invalidate()
    }

    @IBAction func inviteFriendsBtnClickFunc(_ sender: UIButton) {
        guard let inviteFriendsViewController = self.inviteFriendsViewController else {
            return
        }
		AnaliticsCenter.log(event: .inviteFriendClick)
        self.present(inviteFriendsViewController, animated: true, completion: nil)
    }
    
    @IBAction func linkInstgramBtnClickFunc(_ sender: UIButton) {
        if self.linkInstgramLabel.text == "📸 Link instagram" {
            self.linkInstagram()
        } else {
            self.unlinkInstagram()
        }
    }
    
    @IBAction func signOutClickFunc(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "You sure you want to log out?", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
            (UIAlertAction) in
			
			AnaliticsCenter.log(event: .signOut)
            RealmDataController.shared.deleteAllData() { (error) in
                guard error == nil else {
                    error?.log()
                    return
                }
                APIController.authorization = nil
                UserDefaults.standard.removeObject(forKey: "user_id")
                Apns.update(callback: nil)
                
                
                let rootVC = self.view.window?.rootViewController
                rootVC?.presentedViewController?.dismiss(animated: false, completion: {
                    DispatchQueue.main.async {
                        rootVC?.dismiss(animated: true, completion: nil)
                    }
                })
            }
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    let inviteFriendsData = SettingsTableViewCellData(for: .inviteFriends, title: "🎉 Invite friends")
    let talkToData = SettingsTableViewCellData(for: .talkTo, title: "💬 Talk to", style: .talkToCell) //SettingsTableViewCellData(for: .talkTo, title: "💖 Talk to")
    let acceptButtonData = SettingsTableViewCellData(for: .acceptButton, title: "🤙 Auto accept matches", style: .accetpBtnCell)
    
    let nearbyButtonData = SettingsTableViewCellData(for: .acceptButton, title: "🏡 Nearby", style: .accetpBtnCell)

    let aboutUSData = SettingsTableViewCellData(for: .aboutUS, title: "🐒 About us")
    let signOutData = SettingsTableViewCellData(for: .signOut, title: "🙈 Sign out")
    var cells: [SettingsTableViewCellData] {
		var basicCells = [
			talkToData,
		]
//        if RemoteConfigManager.shared.app_in_review == false {
//            basicCells.append(acceptButtonData)
//        }
		
		basicCells.append(contentsOf: [
            acceptButtonData,
            nearbyButtonData,
//            inviteFriendsData,
//            aboutUSData,
//            signOutData,
			])
		return basicCells
//		rateOnAppStoreData,
//		addOnSnapchatData,
//		legalStuffData,
    }
	
	
	
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = cells[indexPath.row]
        switch data.style {
        case .basic:
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath) as! SettingsBasicTableViewCell
            cell.titleLabel?.text = data.title
            cell.data = data
            return cell
        case .talkToCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTalkToCell", for: indexPath) as! SettingTalkToCell
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.titleLabel?.text = data.title
            switch Gender(rawValue: APIController.shared.currentUser?.show_gender ?? "") {
            case .male?:
                cell.genderButton.setImage(#imageLiteral(resourceName: "Guys"), for: .normal)
            case .female?:
                cell.genderButton.setImage(#imageLiteral(resourceName: "Girls"), for: .normal)
            default:
                cell.genderButton.setImage(#imageLiteral(resourceName: "GenderPreferenceButton"), for: .normal)
            }
            return cell;
        case .accetpBtnCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AcceptBtnCell", for: indexPath) as! SettingAcceptButtonCell
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.titleLabel?.text = data.title
			
			if indexPath.row == 1 {
				// auto accept
				cell.acceptSwitch.open = Achievements.shared.autoAcceptMatch
			}else {
				cell.acceptSwitch.open = Achievements.shared.nearbyMatch
			}
            
			cell.acceptSwitch.switchValueChanged = {
				if indexPath.row == 1 {
					// auto accept
					Achievements.shared.autoAcceptMatch = $0
				}else {
					Achievements.shared.nearbyMatch = $0
				}
			}
            return cell;
        case .booleanButtons:
            let cell = tableView.dequeueReusableCell(withIdentifier: "booleanCell", for: indexPath) as! SettingsBooleanTableViewCell
            cell.titleLabel?.text = data.title
            cell.data = data
            cell.delegate = self
            return cell
        case .textField:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! SettingsTextFieldTableViewCell

            cell.hashtagField.delegate = cell
            cell.hashtagField.text = data.text
            if let placeholderText = data.placeholderText {
                cell.hashtagField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: Colors.white(0.5), NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)])
            }
            cell.titleLabel?.text = data.title
            cell.data = data
            cell.delegate = self
            return cell
        }
    }

    /// Dismiss settings view controller if tapped in empty area
    @IBAction func dismissTapped(sender:UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }

        let location = sender.location(in: self.view)
        let remainingSpace = self.view.bounds.height - self.contentHeight

        if location.y < remainingSpace {
            self.panningTowardsSide = .top
            self.dismiss(animated: true, completion: nil)
        }
    }

    func crateEditProfileUI(){
        let firstNameLab:UILabel = UILabel.init(frame:CGRect(x: 16, y: 0, width: 119, height: 64))
        firstNameLab.text = "😊 Name :"
        firstNameLab.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        firstNameLab.textColor = UIColor.white
        self.editProfileContentView.addSubview(firstNameLab)


        self.firstNameTipLab = UILabel.init(frame: CGRect(x:45,y:16+28,width:UIScreen.main.bounds.size.width-60,height:14))
        self.firstNameTipLab.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.firstNameTipLab)

        //self.firstNameTipLab.text = "You can change your name once every 2 months"
        self.firstNameTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)

        let textFieldWidth:CGFloat = UIScreen.main.bounds.size.width-205-20

        self.firstNameField = UsernameTextField.init(frame: CGRect(x:205,y:0,width:textFieldWidth,height:64))
        self.firstNameField.textColor = UIColor.init(white: 1, alpha: 0.7)
        self.firstNameField.text = ""
        self.firstNameField.delegate = self
        self.firstNameField.textAlignment = .right
        self.firstNameField.isUserInteractionEnabled = false
        self.firstNameField.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.firstNameField)

        let birthdayLab:UILabel = UILabel.init(frame:CGRect(x:16,y:64,width:119,height:64))
        birthdayLab.text = "🎂 Birthday :"
        birthdayLab.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        birthdayLab.textColor = UIColor.white
        self.editProfileContentView.addSubview(birthdayLab)

        self.birthdayTipLab = UILabel.init(frame: CGRect(x:45,y:64+28+16,width:UIScreen.main.bounds.size.width-60,height:14))
        self.birthdayTipLab.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.birthdayTipLab)

        self.birthdayField = UITextField.init(frame: CGRect(x:45,y:64,width:UIScreen.main.bounds.size.width-45-20,height:64))
        self.birthdayField.textColor = UIColor.init(white: 1, alpha: 0.7)
        self.birthdayField.text = ""
        self.birthdayField.isUserInteractionEnabled = false
        self.birthdayField.delegate = self
        self.birthdayField.textAlignment = .right
        self.birthdayField.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.birthdayField)

        let snapchatLab:UILabel = UILabel.init(frame:CGRect(x:16,y:64*2,width:200,height:64))
        snapchatLab.text = "👻 Snapchat :"
        snapchatLab.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        snapchatLab.textColor = UIColor.white
        self.editProfileContentView.addSubview(snapchatLab)

        self.snchatTipLab = UILabel.init(frame: CGRect(x:45,y:64*2+28+16,width:UIScreen.main.bounds.size.width-60,height:14))
        self.snchatTipLab.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.snchatTipLab)

        self.snapChatUserName = UsernameTextField.init(frame: CGRect(x:205,y:64*2,width:textFieldWidth,height:64))
        self.snapChatUserName.textColor = UIColor.init(white: 1, alpha: 0.7)
        self.snapChatUserName.text = ""
        self.snapChatUserName.delegate = self
        self.snapChatUserName.textAlignment = .right
        self.snapChatUserName.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.snapChatUserName)

        let width = UIScreen.main.bounds.size.width*0.37
        let space = (UIScreen.main.bounds.size.width-width*2)/3
        self.cancelBtn = BigYellowButton.init(type: .custom)
        self.cancelBtn.frame = CGRect(x:space,y:59*2+88,width:width,height:49)
        self.cancelBtn.layer.cornerRadius = 49/2.0
        self.cancelBtn.layer.masksToBounds = true
        self.cancelBtn.setTitle("Cancel", for: .normal)
        self.cancelBtn.setTitleColor(UIColor.white, for: .normal)
        self.cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightMedium)
        self.cancelBtn.layer.borderWidth = 2
        self.cancelBtn.layer.borderColor = UIColor.init(white: 1, alpha: 0.25).cgColor
        self.editProfileContentView.addSubview(self.cancelBtn)
        self.cancelBtn.addTarget(self, action:#selector(editCancelButtonClick), for: .touchUpInside)

        self.saveBtn = BigYellowButton.init(frame: CGRect.zero)
        self.saveBtn.frame = CGRect(x: space*2+width,y: 59 * 2 + 88, width: width, height: 49)
        self.saveBtn.setTitle("Save", for: .normal)
        self.saveBtn.setTitleColor(UIColor.black, for: .normal)
        self.saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight:UIFontWeightMedium)
        self.saveBtn.layer.cornerRadius = 49/2.0;
        self.saveBtn.backgroundColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
        self.saveBtn.layer.masksToBounds = true
        self.editProfileContentView.addSubview(self.saveBtn)
		self.editStatus = false
        self.saveBtn.alpha = 0.25
//        self.saveBtn.isUserInteractionEnabled = false
		self.saveBtn.addTarget(self, action: #selector(savePreferenceClick), for: UIControlEvents.touchUpInside)

        self.pickerContainerView = UIView.init(frame: CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220))
        self.pickerContainerView.backgroundColor = UIColor.white
        self.view.addSubview(self.pickerContainerView)

        self.datePicker = BirthdatePicker(frame: CGRect(x:0, y:0, width:self.pickerContainerView.frame.size.width, height:216))
        self.datePicker.addTarget(self, action: #selector(dateChanged),
                             for:UIControlEvents.valueChanged)
        self.datePicker.datePickerMode = UIDatePickerMode.date
        self.pickerContainerView.addSubview(self.datePicker)

        self.cancelBtn.isHidden = true
        self.saveBtn.isHidden = true
    }
    func editCancelButtonClick(){
        self.editStatus = false
        self.editBirthdayStatus = false
        self.view.endEditing(true)
        if self.firstNameField.isUserInteractionEnabled{
             self.firstNameTipLab.text = ""
        }
        self.birthdayTipLab.text = ""
        self.snchatTipLab.text = ""
        if let currentUser:RealmUser = APIController.shared.currentUser{
            self.firstNameField.text = currentUser.first_name
            self.snapChatUserName.text = currentUser.snapchat_username;

            if let birthday = currentUser.birth_date {
                self.datePicker.date = Date.init(timeIntervalSince1970: birthday.timeIntervalSince1970)
                self.birthdayField.text = self.datePicker.formattedDate
            }
        }
        self.saveBtn.alpha = 0.25
        
        
        let  settingRect:CGRect = CGRect(x:-self.view.frame.size.width,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height);
        self.containerView.frame = settingRect
        self.stuffView.frame = CGRect(x: -self.view.frame.size.width, y: self.stuffView.frame.origin.y, width: self.stuffView.frame.size.width, height: self.stuffView.frame.size.height)
        
        self.view.layoutIfNeeded()
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    
                    self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220);
                    self.editProfileView.frame = CGRect(x:5,y:self.contentScrollview.y+self.profileView.height+5,width:self.editProfileView.width,height:ScreenHeight-self.contentScrollview.y-self.profileView.height-5-26)
                    self.editProfileContentView.height = self.editProfileView.height-30
                   
            },
                completion: { Void in()
             print("editCancelButtonClick self.editprofileframe\(self.editProfileView.frame)")
            }
            )
        self.cancelBtn.isHidden = true
        self.saveBtn.isHidden = true

        self.profileView.isHidden = false
        self.containerView.isHidden = false
        self.stuffView.isHidden = false
    }
    func dateChanged(datePicker : BirthdatePicker){
        self.birthdayField.text = datePicker.formattedDate

        self.saveBtn.isUserInteractionEnabled = true
        self.saveBtn.alpha = 1.0
        if !self.isValid {
//            self.saveBtn.isUserInteractionEnabled = false
            self.saveBtn.alpha = 0.25
        }
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.snchatTipLab.text = ""
        self.editBirthdayStatus = false
        self.cancelBtn.isHidden = false
        self.saveBtn.isHidden = false
        if textField == self.firstNameField{
            self.firstNameTipLab.text = "You can change your name once every 2 months"
            self.firstNameTipLab.numberOfLines = 0
            self.firstNameTipLab.sizeToFit()
            self.firstNameTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
            if self.birthdayField.isUserInteractionEnabled{
                self.birthdayTipLab.text = ""
            }
        }
        if textField == self.birthdayField{
            self.editBirthdayStatus = true
            if self.firstNameField.isUserInteractionEnabled{
                self.firstNameTipLab.text = ""
            }
            self.profileView.isHidden = true
            self.containerView.isHidden = true
            self.stuffView.isHidden = true
            self.birthdayTipLab.text = "Better make sure yo, you can only change this once"
            self.birthdayTipLab.numberOfLines = 0
            self.birthdayTipLab.sizeToFit()
            self.birthdayTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
            self.view.endEditing(true)
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height-5-self.pickerContainerView.frame.size.height,width:self.pickerContainerView.frame.size.width,height:self.pickerContainerView.frame.size.height)
                    self.editProfileView.frame = CGRect(x:5,y:UIScreen.main.bounds.size.height - self.pickerContainerView.frame.size.height - 300-12,width:self.editProfileView.frame.size.width,height:300)
            },
                completion: { Void in()  }
            )
            return  false
        }else{
            if textField == self.snapChatUserName{
                if self.firstNameField.isUserInteractionEnabled{
                    self.firstNameTipLab.text = ""
                }
                if self.birthdayField.isUserInteractionEnabled{
                    self.birthdayTipLab.text = ""
                }
            }
        }
        return true
    }
    var isValid: Bool {
        return  self.snapChatUserName.isValid && self.firstNameField.charactersCount > 2
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let currentUser:RealmUser = APIController.shared.currentUser{

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"

                if let birthday = currentUser.birth_date {
                    if self.firstNameField.text != currentUser.first_name || self.snapChatUserName.text != currentUser.snapchat_username || self.datePicker.formattedDate != dateFormatter.string(from: birthday as Date) {
                        self.saveBtn.isUserInteractionEnabled = true
                        self.saveBtn.alpha = 1.0
                        if !self.isValid {
//                            self.saveBtn.isUserInteractionEnabled = false
                            self.saveBtn.alpha = 0.25
                        }
                    }else{
//                        self.saveBtn.isUserInteractionEnabled = false
                        self.saveBtn.alpha = 0.25
                    }
                }else{
//                    self.saveBtn.isUserInteractionEnabled = false
                    self.saveBtn.alpha = 0.25
                }

               self.updateTextFieldTip(textField: textField)
            }
        }

        return true
    }

    func updateTextFieldTip(textField:UITextField){
        if textField == self.firstNameField  {
            if self.firstNameField.charactersCount <= 2{
                self.firstNameTipLab.text = "Invalid format"
                self.firstNameTipLab.textColor = UIColor.init(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
            }else{
                self.firstNameTipLab.text = "You can change your name once every 2 months"
                self.firstNameTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
            }
        }
        if textField == self.snapChatUserName {
            if !self.snapChatUserName.isValid{
                self.snchatTipLab.text = "Invalid format"
                self.snchatTipLab.textColor = UIColor.init(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
            }else{
                self.snchatTipLab.text = ""
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func keyBoardWillShow(notification: Notification){
        let userInfo  = notification.userInfo! as NSDictionary
        let  keyBoardBounds = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let deltaY = keyBoardBounds.size.height
    
        let editProfileHeight :CGFloat = 300
        var editProfileStartPointY = UIScreen.main.bounds.size.height - deltaY - editProfileHeight-12
//        if editProfileStartPointY<20 {
//            editProfileStartPointY = 20
//        }
        self.profileView.isHidden = true
        self.containerView.isHidden = true
        self.stuffView.isHidden = true
        
        self.keyBoardWasShow = true
        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue:UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: options,
                animations: {
                    // 键盘高度
                    self.editProfileView.frame = CGRect(x:5,y:editProfileStartPointY,width:self.editProfileView.width,height:editProfileHeight)
            },
                completion: { Void in()
                    print("keyBoardWillShow self.editprofileframe\(self.editProfileView.frame)")
                    self.view.layoutIfNeeded()
                    print("keyBoardWillShow=== self.editprofileframe\(self.editProfileView.frame)")
            }
            )
        }else{
           self.editProfileView.frame = CGRect(x:5,y:editProfileStartPointY,width:self.editProfileView.width,height:editProfileHeight)
        }
        self.pickerContainerView.y = ScreenHeight
    }
    func keyBoardWillHide(notification: Notification){
        
        if self.editBirthdayStatus {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.keyBoardWasShow = false
        }
        self.profileView.isHidden = false
        self.containerView.isHidden = false
        self.stuffView.isHidden = false
        self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220);
        
        self.editProfileView.frame = CGRect(x:5,y:self.contentScrollview.y+self.profileView.height+5,width:self.editProfileView.width,height:ScreenHeight-self.contentScrollview.y-self.profileView.height-5-26)
        self.editProfileContentView.height = self.editProfileView.height-30
        
        self.cancelBtn.isHidden = true
        self.saveBtn.isHidden = true
    }
}

extension SettingsViewController: SFSafariViewControllerDelegate {

}

enum SettingsTableViewCellStyle {
    case basic
    case booleanButtons
    case textField
    case talkToCell
    case accetpBtnCell
}
struct SettingsTableViewCellData {
    var title: String
    var style: SettingsTableViewCellStyle
    var type: SettingsTableViewCellType
    var firstOption: SettingsTableViewCellOption?
    var secondOption: SettingsTableViewCellOption?
    var text: String?
    var placeholderText: String?
    var isEditing = false

    init(for type: SettingsTableViewCellType, title: String) {
        self.type = type
        self.title = title
        self.style = .basic
    }
    init(for type: SettingsTableViewCellType, title: String ,style:SettingsTableViewCellStyle) {
        self.type = type
        self.title = title
        self.style = style
    }

    init(for type: SettingsTableViewCellType, title: String, text: String, placeholderText: String) {
        self.type = type
        self.title = title
        self.style = .textField
        self.text = text
        self.placeholderText = placeholderText
    }
    init(for type: SettingsTableViewCellType, title: String, firstOption: SettingsTableViewCellOption, secondOption: SettingsTableViewCellOption) {
        self.type = type
        self.title = title
        self.style = .booleanButtons
        // custom to this type
        self.firstOption = firstOption
        self.secondOption = secondOption
    }
    mutating func set(text: String?) {
        self.text = text
    }
    mutating func setFirstOption(isSelected: Bool) {
        self.firstOption?.isSelected = isSelected
    }
    mutating func setSecondOption(isSelected: Bool) {
        self.secondOption?.isSelected = isSelected
    }
}

class SettingsTableViewCellOption {
    let emoji: String
    let title: String
    var isSelected = false
    init(title: String, emoji: String, isSelected: Bool) {
        self.emoji = emoji
        self.title = title
        self.isSelected = isSelected
    }
}

enum SettingsTableViewCellType {
    case signOut
    case editProfile
    case inviteFriends
    case aboutUS
    case talkTo
    case acceptButton
}

class SettingsTableViewCell: UITableViewCell {
    var data: SettingsTableViewCellData?
    @IBOutlet var titleLabel: UILabel!
}

class SettingsBasicTableViewCell: SettingsTableViewCell {

}

class  SettingAcceptButtonCell: UITableViewCell {
    var data: SettingsTableViewCellData?
    var titleLabel : UILabel!
    var acceptSwitch : MonkeySwitch!
    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style:UITableViewCellStyle, reuseIdentifier:String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpUI();
    }

    func setUpUI() {
        self.backgroundColor = UIColor.clear
        self.titleLabel = UILabel.init()
        self.titleLabel.backgroundColor = UIColor.clear;
        self.titleLabel.frame = CGRect(x: 16, y: 0, width: self.contentView.frame.size.width - 18 - 40 - 18, height: 64)
		self.titleLabel.autoresizingMask = [.flexibleWidth]
        self.titleLabel.text = ""
        self.titleLabel.textColor = UIColor.white
        self.titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.titleLabel.textAlignment = NSTextAlignment.left
        self.contentView.addSubview(self.titleLabel)

		self.acceptSwitch = MonkeySwitch.init(frame: CGRect(x: self.contentView.frame.size.width - 40 - 18, y: 17, width: 40, height: 30))
		self.acceptSwitch.closeIndicatorColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.3)
		self.acceptSwitch.openEmoji = "🐵"
		self.acceptSwitch.autoresizingMask = [.flexibleLeftMargin]
        self.contentView.addSubview(self.acceptSwitch)
    }
}

class SettingTalkToCell: UITableViewCell {
    var data: SettingsTableViewCellData?
    var titleLabel : UILabel!
    var genderButton : UIButton!
    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style:UITableViewCellStyle, reuseIdentifier:String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpUI();
    }

    func setUpUI() {
        self.backgroundColor = UIColor.clear
        self.titleLabel = UILabel.init()
        self.titleLabel?.backgroundColor = UIColor.clear;
        self.titleLabel?.frame = CGRect(x:16, y:0, width:150, height:64)
        self.titleLabel?.text = ""
        self.titleLabel?.textColor = UIColor.white
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.titleLabel?.textAlignment = NSTextAlignment.left
        self.contentView.addSubview(self.titleLabel!)

        self.genderButton = UIButton.init(type: .custom)
        self.genderButton?.frame = CGRect(x: self.contentView.frame.size.width - 14 - 48, y: 7, width: 48, height: 48)
		self.genderButton.autoresizingMask = [.flexibleLeftMargin]
        self.genderButton?.backgroundColor = UIColor.clear

        self.contentView.addSubview(self.genderButton!)

		let fullButton = UIButton.init(type: .custom)
		fullButton.adjustsImageWhenHighlighted = false
		fullButton.backgroundColor = UIColor.clear
		fullButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		fullButton.frame = self.contentView.bounds
		self.contentView.addSubview(fullButton)
        fullButton.addTarget(self, action:#selector(genderPerferenceBtnClick), for: .touchUpInside)
    }
    func genderPerferenceBtnClick(){
        let alertController = UIAlertController(title: "Talk to", message: "Tap who you'd rather talk to", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alertController.addAction(UIAlertAction(title: "👫 Both", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender(nil)], completion: { $0?.log() })

            self.genderButton.setImage(#imageLiteral(resourceName: "GenderPreferenceButton"), for: .normal)
        }))

        alertController.addAction(UIAlertAction(title: "👱 Guys", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("male")], completion: { $0?.log() })

            self.genderButton.setImage(#imageLiteral(resourceName: "Guys"), for: .normal)
            
            self.handleSubAlertFunc(isGirls: false)
        }))

        alertController.addAction(UIAlertAction(title: "👱‍♀️ Girls", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("female")], completion: { $0?.log() })

            self.genderButton.setImage(#imageLiteral(resourceName: "Girls"), for: .normal)
            
            self.handleSubAlertFunc(isGirls: true)
        }))
        
        self.alertKeyAndVisibleFunc(alert: alertController)
    }
    
    func handleSubAlertFunc(isGirls:Bool) {
        
        let subAlert = UIAlertController(title: isGirls ? "👱‍♀️" : "👱", message: isGirls ? "This gives priority to talk to girls but not guaranteed 🆗" : "This gives priority to talk to guys but not guaranteed 🆗", preferredStyle: .alert)
        
        subAlert.addAction(UIAlertAction(title: "kk", style: .default, handler:nil))
        
        self.alertKeyAndVisibleFunc(alert: subAlert)
    }
    
    func alertKeyAndVisibleFunc(alert:UIAlertController) {
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = AlertViewController()
        alertWindow.windowLevel = UIWindowLevelAlert
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
class AlertViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
class BooleanButton: BigYellowButton {
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.backgroundColor = UIColor(red: 107.0 / 255.0, green: 68.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)

            } else {
                self.backgroundColor = UIColor(red: 35.0 / 255.0, green: 35.0 / 255.0, blue: 35.0 / 255.0, alpha: 1.0)
            }
        }
    }
}

class SettingsBooleanTableViewCell: SettingsTableViewCell {
    weak var delegate:SettingsBooleanTableViewCellDelegate?
    override var data: SettingsTableViewCellData? {
        didSet {
            self.firstOptionButton.isSelected = self.data?.firstOption?.isSelected ?? false
            self.secondOptionButton.isSelected = self.data?.secondOption?.isSelected ?? false
        }
    }
    @IBOutlet private var firstOptionButton: BooleanButton!
    @IBOutlet private var secondOptionButton: BooleanButton!
    @IBAction func firstOptionSelected() {
        self.data?.setFirstOption(isSelected: true)
        self.data?.setSecondOption(isSelected: false)
        self.delegate?.buttonStatesChanged(settingsTableViewCell: self)
    }
    @IBAction func secondOptionSelected() {
        self.data?.setFirstOption(isSelected: false)
        self.data?.setSecondOption(isSelected: true)
        self.delegate?.buttonStatesChanged(settingsTableViewCell: self)
    }
    func invertButtonStyles() {
        let secondOptionButtonBackgroundColor = self.secondOptionButton.backgroundColor
        self.secondOptionButton.backgroundColor = self.firstOptionButton.backgroundColor
        self.firstOptionButton.backgroundColor = secondOptionButtonBackgroundColor
    }
}

protocol SettingsBooleanTableViewCellDelegate: class {
    func buttonStatesChanged(settingsTableViewCell: SettingsBooleanTableViewCell)
}

protocol SettingsHashtagCellDelegate: class {
    func selectedHashtag(id: String, tag: String)
    func showAlert(alert: UIAlertController)

}
