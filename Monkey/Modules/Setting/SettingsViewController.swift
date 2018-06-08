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

class SettingsViewController: SwipeableViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, ProfilePhotoButtonViewDelegate, UITextFieldDelegate, InstagramAuthDelegate {

	@IBOutlet var containerView: MakeUIViewGreatAgain!
	@IBOutlet weak var stuffView: MakeUIViewGreatAgain!

    @IBOutlet weak var remindPointView: UIView!
    
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentScrollview: UIScrollView!
	@IBOutlet weak var editButtons: UIButton!
	@IBOutlet weak var timeOnMonkey: UILabel!
	@IBOutlet weak var firstName: UILabel!

	@IBOutlet weak var linkInstgramLabel: UILabel!

	@IBOutlet weak var profilePhoto: ProfilePhotoButtonView!
	@IBOutlet var tableView: UITableView!
	@IBOutlet var titleButton: UIButton!

	@IBOutlet weak var profileView:UIView!

	var editProfileView: UIView!
	var editProfileContentView: UIView!
	/// edit Profile UI
	var firstNameField: UITextField! //名字
	var birthdayField: UITextField!  //生日
	var snapChatUserName: UsernameTextField! //snap chat
	var editStatus: Bool! //编辑状态，控制手势滑动
	var firstNameTipLab: UILabel! //名字提示lab
	var birthdayTipLab: UILabel! //生日提示
	var snchatTipLab: UILabel! //生日提示
	var pickerContainerView: UIView! //年龄选择
	var editBirthdayStatus: Bool!
	var cancelBtn: UIButton!
	var saveBtn: BigYellowButton!
	var datePicker: BirthdatePicker!
	var userOption: UserOptions?
	var keyBoardWasShow: Bool!
    ///end edit Profile UI

    /// Returns the content size of the view
    override var contentHeight: CGFloat {
        if self.keyBoardWasShow {
            return UIScreen.main.bounds.size.height
        }else {
            return ScreenHeight - self.contentScrollview.frame.minY
        }
    }

    var headImageInited = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.keyBoardWasShow = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.bounces = false
		self.tableView.rowHeight = 64
        self.tableView.register(SettingTalkToCell.self, forCellReuseIdentifier: "SettingTalkToCell")
        self.tableView.register(SettingAcceptButtonCell.self, forCellReuseIdentifier: "AcceptBtnCell")
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
        blurView.frame = CGRect(x: 0, y: 30, width: UIScreen.main.bounds.size.width, height: self.editProfileView.frame.size.height)
        blurView.autoresizingMask = UIViewAutoresizing.flexibleHeight
        self.editProfileView.addSubview(blurView)

        editProfileContentView =  UIView.init(frame: CGRect(x: 0, y: 30, width: self.editProfileView.frame.size.width, height: self.editProfileView.frame.size.height - 30))
        editProfileContentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		editProfileContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.editProfileView.addSubview(editProfileContentView)
        self.editBirthdayStatus = false
		self.contentScrollview.showsVerticalScrollIndicator = false

		self.crateEditProfileUI()
        self.contentScrollview.bounces = false
		let containerViewHeight: CGFloat = RemoteConfigManager.shared.app_in_review ? 233 : 0
		self.scrollViewHeightConstraint.constant = min(ScreenHeight - 44, 642 - containerViewHeight)
		if RemoteConfigManager.shared.app_in_review {
			self.containerView.removeFromSuperview()
		}

        let tapGesture = UITapGestureRecognizer(target: self,action:#selector(handleTapGesture))
        self.profileView.addGestureRecognizer(tapGesture)
        
        self.handleYelloPointStateFunc()
        
        APIController.shared.currentUser!.reload { (error) in
            error?.log()
            print("*** = \(APIController.shared.currentUser?.profile_photo_url)")
        }
    }
    
    func handleYelloPointStateFunc() {
        
        if APIController.shared.currentUser?.profile_photo_url != nil {
            self.remindPointView.isHidden = true
        } else {
            
            let anyArray = UserDefaults.standard.array(forKey: AccessUserAvatarArrayTag)
            
            let currentUserId = (APIController.shared.currentUser?.user_id)!
            
            if anyArray != nil {
                
                let stringArray = anyArray as! StringArray
                
                stringArray.forEach { (string) in
                    let array = string.split(separator: StringArraySplitCharacter)
                    if array.first?.description == currentUserId {
                        self.remindPointView.isHidden = array.last?.description == "1" ? true : false
                    }
                }
            }
            
        }
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
    }

    func resetEditProfileFrame(){
        self.pickerContainerView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width, height: 220);
        self.editProfileView.frame = CGRect(x:UIScreen.main.bounds.size.width,y:self.contentScrollview.frame.origin.y+self.profileView.frame.size.height+5,width:ScreenWidth-10,height:self.contentScrollview.frame.size.height-self.profileView.frame.size.height-5)
        self.editButtons.setImage(UIImage(named:"EditProfileButtton"), for: .normal)
        self.editButtons.isSelected = false
        self.containerView.isHidden = false

        self.containerView.frame.origin.x = 0
        self.stuffView.frame.origin.x = 0
        self.contentScrollview.isScrollEnabled = true
        self.profileView.isHidden = false
        self.stuffView.isHidden = false
        if APIController.shared.currentUser?.instagram_account != nil {
            self.linkInstgramLabel.text = "🌅 Unlink instagram"
        }else {
            self.linkInstgramLabel.text = "📸 Link instagram"
        }
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

		self.addKeyboardListenFunc()
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		self.removeKeyboardListenFunc()
	}
    
    func addKeyboardListenFunc() {
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyBoardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyBoardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboardListenFunc() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

	func refreshEditStatus() {
		JSONAPIRequest(url: "\(Environment.baseURL)/api/\(UserOptions.api_version.rawValue)/\(UserOptions.requst_subfix)", options: [
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

    func profilePhotoButtonView(_ profilePhotoButtonView: ProfilePhotoButtonView, selectedImage: UIImage) {
        self.profilePhoto.profileImage = selectedImage
        self.remindPointView.isHidden = true
        self.profilePhoto.uploadProfileImage {
            print("Uploaded profile image")
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // false so that swiping to side during longPress does not try to dismiss friendsVC (to go to mainVC) while instagramVC is presented
        if gestureRecognizer == self.panGestureRecognizer {
            return false
        }

        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
	
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !self.editStatus
    }

    func instagramNotificationReceived(_ notification: Notification) {
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

    func linkInstagramToUser(_ code: String) {
        let parameters: [String: Any] = [
            "data": [
                "type": "instagram_accounts",
                "attributes": ["code": code],
                ]
        ]

		RealmInstagramAccount.create(method: .post, parameters: parameters) { (result: JSONAPIResult<RealmInstagramAccount>) in
			switch result {
			case .success(_):
				self.linkInstgramLabel.text = "🌅 Unlink instagram"
				AnalyticsCenter.log(withEvent: .settingLinkInsComplete, andParameter: [
					"type": "true",
					])
				break
			case .error(let error):
				error.log()
				AnalyticsCenter.log(withEvent: .settingLinkInsComplete, andParameter: [
					"type": "false",
					])
				let instagramFailedAlert = UIAlertController(title: "😬 Error linking Instagram", message: "Please try again", preferredStyle: .alert)
				instagramFailedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
				self.present(instagramFailedAlert, animated: true)
			}
		}
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
		var editFirstName: Bool = false
		var editBirthDay: Bool = false
		
		var event_info = ""
		if let newFirstName = self.firstNameField.text, newFirstName != currentUser.first_name {
			attributes.append(.first_name(newFirstName))
			editFirstName = true
			event_info.append("name=\(newFirstName)")
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
					event_info.append("birth=\(newBirthdayStr)")
				}
			}
		}
		
		if let newSnapchatName = self.snapChatUserName.text, newSnapchatName != currentUser.snapchat_username {
			attributes.append(.snapchat_username(newSnapchatName))
			event_info.append("snapchat=\(newSnapchatName)")
		}
		
		if attributes.count > 0 {
			saveBtn.isLoading = true
			
			let isAccountNew = APIController.userDef.bool(forKey: APIController.kNewAccountCodeVerify)
			AnalyticsCenter.log(withEvent: .settingEditProfileClick, andParameter: [
				"type": isAccountNew ? "new" : "old",
				"info": event_info,
				])
			
			currentUser.update(attributes: attributes) { (error) in
				// 保存请求返回结果
				self.saveBtn.isLoading = false
				
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
				
				// 保存成功
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
					
					if editFirstName {
						self.firstNameField.isUserInteractionEnabled = false
						self.firstName.text = currentUser.first_name
					}
					self.editCancelButtonClick()
					self.refreshEditStatus()
					self.view.endEditing(true)
				}
				AnalyticsCenter.update(userProperty: userProperty)
			}
		}else {
			self.editCancelButtonClick()
		}
	}

    @IBAction func editProfileTapped(_ sender: UIButton) {
		AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
			"type": "edit",
			])
		
		let  settingRect:CGRect = CGRect(x:-self.view.frame.size.width,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height);
		sender.isUserInteractionEnabled = false
		self.view.layoutIfNeeded()
		self.view.bringSubview(toFront: self.editProfileView)
		let profileHeigh:CGFloat = self.profileView.frame.size.height
		let  editprofileRect:CGRect = CGRect(x:5,y:self.contentScrollview.frame.origin.y+profileHeigh+5,width:ScreenWidth-10,height:ScreenHeight-(self.contentScrollview.frame.origin.y+profileHeigh+5)-26)
		self.keyBoardWasShow = false
		self.editProfileView.frame = CGRect(x:self.editProfileView.frame.origin.x,y:self.contentScrollview.frame.origin.y+profileHeigh+5,width:self.editProfileView.frame.size.width,height:ScreenHeight-(self.contentScrollview.frame.origin.y+profileHeigh+5)-26)
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
				self.editProfileView.frame.origin.x = ScreenWidth
				self.view.layoutIfNeeded()
				self.containerView.frame.origin.x = 0
				self.stuffView.frame.origin.x = 0
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

        let inscontroller = InstagramAuthViewController.init()
        let authurl =  URL.init(string:loginUrl)

        inscontroller.webURL = authurl
        inscontroller.authDelegate = self
        let insnav = UINavigationController.init(rootViewController: inscontroller)
        insnav.modalPresentationStyle = .overFullScreen
        self.present(insnav, animated: true, completion: nil)
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

            self.linkInstgramLabel.text = "📸 Link instagram"
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
        result: MessageComposeResult) {
		if result == .sent {
			AnalyticsCenter.log(event: .inviteFriendSuccess)
			AnalyticsCenter.log(withEvent: .settingInviteClick, andParameter: [
				"type": "true",
				])
		}else {
			AnalyticsCenter.log(withEvent: .settingInviteClick, andParameter: [
				"type": "false",
				])
		}
		controller.dismiss(animated: true, completion: nil)
    }

    func showInviteFriendsViewController() {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let inviteFriendsViewController = MFMessageComposeViewController()
        inviteFriendsViewController.body = APIController.shared.currentExperiment?.sms_invite_friends
        inviteFriendsViewController.messageComposeDelegate = self
		self.present(inviteFriendsViewController, animated: true)
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

    @IBAction func inviteFriendsBtnClickFunc(_ sender: UIButton) {
		AnalyticsCenter.log(event: .inviteFriendClick)
		AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
			"type": "invite_friends",
			])
		
		self.showInviteFriendsViewController()
    }

    @IBAction func linkInstgramBtnClickFunc(_ sender: UIButton) {
		AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
			"type": "link_Ins",
			])
		AnalyticsCenter.log(event: .settingLinkInsClick)
		
        if self.linkInstgramLabel.text == "📸 Link instagram" {
            self.linkInstagram()
        } else {
            self.unlinkInstagram()
        }
    }
	
    func authInstagramSuccess(code: String) {
        self.refreshEditStatus()
        self.resetEditProfileFrame()
    }
	
    func authInstagramFailure() {
		AnalyticsCenter.log(withEvent: .settingLinkInsComplete, andParameter: [
			"type": "false",
			])
		
		self.refreshEditStatus()
		self.resetEditProfileFrame()
    }
	
    @IBAction func safetyClickFunc(_ sender: UIButton) {
        
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
        alertController.addAction(UIKit.UIAlertAction(title: "❌ Delete Account", style: .default, handler: { (UIAlertAction) in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DeleteAccountPopupViewController") as! DeleteAccountPopupViewController
            vc.modalPresentationStyle = .overFullScreen
            vc.keyboardClosure = {
                $0 ? self.addKeyboardListenFunc() : self.removeKeyboardListenFunc()
            }
            self.present(vc, animated: true, completion: nil)
        }))
        if let creditsURL = APIController.shared.currentExperiment?.credits_url {
            alertController.addAction(UIKit.UIAlertAction(title: "Credits", style: .default, handler: { (UIAlertAction) in
                self.openURL(creditsURL, inVC: true)
            }))
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func signOutClickFunc(_ sender: UIButton) {
		AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
			"type": "sign_out",
			])
		
		let alertController = UIAlertController(title: "You sure you want to log out?", message: nil, preferredStyle: .actionSheet)
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (cancelAlert) in
			AnalyticsCenter.log(withEvent: .settingSignOutClick, andParameter: [
				"type": "cancel",
				])
		}))
		
		alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
			(UIAlertAction) in
			
			AnalyticsCenter.log(event: .signOut)
			AnalyticsCenter.log(withEvent: .settingSignOutClick, andParameter: [
				"type": "yes",
				])
			RealmDataController.shared.deleteAllData() { (error) in
				guard error == nil else {
					error?.log()
					return
				}
				APIController.authorization = nil
				Socket.shared.fetchCollection = false
				UserDefaults.standard.removeObject(forKey: "user_id")
				UserDefaults.standard.removeObject(forKey: "apns_token")
				
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

    let cells: [SettingsTableViewCellData] = [
		SettingsTableViewCellData(for: .talkTo, title: "💬 Talk to", style: .talkToCell),
		SettingsTableViewCellData(for: .acceptButton, title: "🤙 Auto accept matches", style: .accetpBtnCell),
		SettingsTableViewCellData(for: .acceptButton, title: "🏡 Nearby", style: .accetpBtnCell),
		]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = cells[indexPath.row]
        switch data.style {
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
					
					AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
						"type": "auto_match",
						])
				}else {
					Achievements.shared.nearbyMatch = $0
					
					AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
						"type": "nearby",
						])
				}
			}
            return cell;
		}
    }

    /// Dismiss settings view controller if tapped in empty area
    @IBAction func dismissTapped(sender: UITapGestureRecognizer) {
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

    func crateEditProfileUI() {
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
                    self.editProfileView.frame = CGRect(x:5,y:self.contentScrollview.frame.origin.y+self.profileView.frame.size.height+5,width:self.editProfileView.frame.size.width,height:ScreenHeight-self.contentScrollview.frame.origin.y-self.profileView.frame.size.height-5-26)

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

    func updateTextFieldTip(textField: UITextField){
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
		let editProfileStartPointY = UIScreen.main.bounds.size.height - deltaY - editProfileHeight-12
		
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
                    self.editProfileView.frame = CGRect(x:5,y:editProfileStartPointY,width:self.editProfileView.frame.size.width,height:editProfileHeight)
            },
                completion: { Void in()
                    print("keyBoardWillShow self.editprofileframe\(self.editProfileView.frame)")
                    self.view.layoutIfNeeded()
                    print("keyBoardWillShow=== self.editprofileframe\(self.editProfileView.frame)")
            }
            )
        }else{
           self.editProfileView.frame = CGRect(x:5,y:editProfileStartPointY,width:self.editProfileView.frame.size.width,height:editProfileHeight)
        }
        self.pickerContainerView.frame.origin.y = ScreenHeight
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

        self.editProfileView.frame = CGRect(x:5,y:self.contentScrollview.frame.origin.y+self.profileView.frame.size.height+5,width:self.editProfileView.frame.size.width,height:ScreenHeight-self.contentScrollview.frame.origin.y-self.profileView.frame.size.height-5-26)

        self.cancelBtn.isHidden = true
        self.saveBtn.isHidden = true
    }
}

extension SettingsViewController: SFSafariViewControllerDelegate {

}

enum SettingsTableViewCellStyle {
    case talkToCell
    case accetpBtnCell
}

struct SettingsTableViewCellData {
    var title: String
    var style: SettingsTableViewCellStyle
    var type: SettingsTableViewCellType

    init(for type: SettingsTableViewCellType, title: String, style: SettingsTableViewCellStyle) {
        self.type = type
        self.title = title
        self.style = style
    }
}

enum SettingsTableViewCellType {
    case talkTo
    case acceptButton
}

class SettingAcceptButtonCell: UITableViewCell {
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
	
    func genderPerferenceBtnClick() {
		AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
			"type": "talk_to",
			])
		
        let alertController = UIAlertController(title: "Talk to", message: "Tap who you'd rather talk to", preferredStyle: .actionSheet)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (cancelAlert) in
			
			AnalyticsCenter.log(withEvent: .settingTalkToClick, andParameter: [
				"type": "cancel",
				])
		}))

        alertController.addAction(UIAlertAction(title: "👫 Both", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender(nil)], completion: { $0?.log() })

            self.genderButton.setImage(#imageLiteral(resourceName: "GenderPreferenceButton"), for: .normal)
			
			AnalyticsCenter.log(withEvent: .settingTalkToClick, andParameter: [
				"type": "Both",
				])
        }))

        alertController.addAction(UIAlertAction(title: "👱 Guys", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("male")], completion: { $0?.log() })

            self.genderButton.setImage(#imageLiteral(resourceName: "Guys"), for: .normal)

            self.handleSubAlertFunc(isGirls: false)
			
			AnalyticsCenter.log(withEvent: .settingTalkToClick, andParameter: [
				"type": "Guys",
				])
        }))

        alertController.addAction(UIAlertAction(title: "👱‍♀️ Girls", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("female")], completion: { $0?.log() })

            self.genderButton.setImage(#imageLiteral(resourceName: "Girls"), for: .normal)

            self.handleSubAlertFunc(isGirls: true)
			
			AnalyticsCenter.log(withEvent: .settingTalkToClick, andParameter: [
				"type": "Girls",
				])
        }))

        self.alertKeyAndVisibleFunc(alert: alertController)
    }

    func handleSubAlertFunc(isGirls: Bool) {
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
