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

    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var editButtons: UIButton!
    @IBOutlet weak var timeOnMonkey: UILabel!
    @IBOutlet weak var firstName: UILabel!

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
        if self.editStatus {
            return UIScreen.main.bounds.size.height
        }else {
            return 500
        }
    }
    
    var headImageInited = false

    var lastY: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
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

        self.editProfileView = UIView.init(frame: CGRect(x: 10 + self.containerView.frame.size.width, y: self.containerView.frame.origin.y, width: self.containerView.frame.size.width, height: self.containerView.frame.size.height))
        self.editProfileView.backgroundColor = UIColor.clear
        self.view.addSubview(self.editProfileView)
        self.editProfileView.layer.cornerRadius = self.containerView.layer.cornerRadius
        self.editProfileView.layer.masksToBounds = true
        
        let editProfileTitleLab:UILabel = UILabel.init(frame: CGRect(x:0,y:0,width:editProfileView.frame.size.width,height:30))
        //foregroundColor
        editProfileTitleLab.backgroundColor = UIColor.init(white: 0, alpha: 0.56)
        let attributedString = NSMutableAttributedString(string: " ✏️ Edit Profile", attributes: [
            NSFontAttributeName: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightMedium),
            NSForegroundColorAttributeName: UIColor(white: 154.0 / 255.0, alpha: 1.0)
            ])
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: 3))
        editProfileTitleLab.attributedText = attributedString
        self.editProfileView.addSubview(editProfileTitleLab)
        
        editProfileContentView =  UIView.init(frame: CGRect(x: 0, y: 30, width: self.editProfileView.frame.size.width, height: self.editProfileView.frame.size.height - 30))
        editProfileContentView.backgroundColor = UIColor.black
        self.editProfileView.addSubview(editProfileContentView)
		self.crateEditProfileUI()
    }
	
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		self.refreshEditStatus()
		
        self.pickerContainerView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width, height: 220);
        self.editProfileView.frame = CGRect(x:UIScreen.main.bounds.size.width,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height)
        self.editButtons.setImage(UIImage(named:"EditProfileButtton"), for: .normal)
        self.editButtons.isSelected = false
        self.containerView.isHidden = false
    }
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
		JSONAPIRequest(url: "\(Environment.baseURL)/api/\(UserOptions.api_version)/\(UserOptions.type)", options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler {[weak self] (response) in
			switch response {
				case .error( _): break
				case .success(let jsonAPIDocument):
					do {
					self?.userOption = Mapper<UserOptions>().map(JSON: jsonAPIDocument.json)
					
					let time = self?.userOption?.update_username.timeIntervalSince1970 ?? 0
					let now = Date().timeIntervalSince1970
					let isPast = now - time > 0
					
					let sec:Double = abs(now - time)
					let min:Double = round(sec/60)
					let hr:Double = round(min/60)
					let d:Double = round(hr/24)
					
					if isPast == true && d >= 60 {
						
					}
				}
			}
		}
	}

    internal func showAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
		
		var attributes: [RealmUser.Attribute] = []
		
		if let newFirstName = self.firstNameField.text, newFirstName != currentUser.first_name {
			attributes.append(.first_name(newFirstName))
		}
		
		if let newBirthdayStr = self.birthdayField.text {
			if let oldBirthday = currentUser.birth_date {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "MM/dd/yyyy"
				let oldBirthdayDate = Date.init(timeIntervalSince1970: oldBirthday.timeIntervalSince1970)
				let oldBirthdayStr = dateFormatter.string(from: oldBirthdayDate)
				if (newBirthdayStr != oldBirthdayStr) {
					attributes.append(.birth_date(self.datePicker.date as NSDate))
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
					// 保存失败
					
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
				
				AnaliticsCenter.update(userProperty: userProperty)
				// 保存成功
			}
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

    @IBAction func editProfileTapped(_ sender: Any) {
        let  settingRect:CGRect = CGRect(x:-self.view.frame.size.width,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height);
        
        let  editprofileRect:CGRect = CGRect(x:5,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:containerView.frame.size.height)
        
        self.editProfileView.frame = CGRect(x:self.editProfileView.frame.origin.x,y:self.containerView.frame.origin.y,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
        self.editProfileView.setNeedsLayout()
        if self.editButtons.isSelected {
            self.editButtons.setImage(UIImage(named:"EditProfileButtton"), for: .normal)
            self.editButtons.isSelected = false
            self.containerView.isHidden = false
            self.editStatus = false
            UIView.animate(withDuration:0.35, animations: {
                self.editProfileView.frame = CGRect(x:UIScreen.main.bounds.size.width,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height)
                self.view.layoutIfNeeded()
//                self.containerView.frame = CGRect(x:5,y:self.containerView.frame.origin.y,width:self.containerView.frame.size.width,height:self.containerView.frame.size.height)
            }) { (completed) in
            }
        }else{
            self.editStatus = true
            self.editButtons.isSelected = true
            self.editButtons.setImage(UIImage(named:"edit_profile_backbtn_icon"), for: .normal)
            
            if let currentUser:RealmUser = APIController.shared.currentUser{
                self.firstNameField.text = currentUser.first_name
                self.snapChatUserName.text = currentUser.snapchat_username;
                
                if let birthday = currentUser.birth_date {
                    self.datePicker.date = Date.init(timeIntervalSince1970: birthday.timeIntervalSince1970)
                    self.birthdayField.text = self.datePicker.formattedDate
                }
            }
            
            
            UIView.animate(withDuration:0.35, animations: {
                self.view.layoutIfNeeded()
                self.editProfileView.frame = editprofileRect
                self.containerView.frame = settingRect
            }) { (completed) in
                UIView.animate(withDuration: 0.15, animations: {
                    self.rightMargin.constant = 5
                    self.leftMargin.constant = 5
                    self.containerView.isHidden = true
                }, completion: { done in
                    
                })
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

            print("Instagram account unlinked & deleted")
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
        result: MessageComposeResult)
    {
        self.dismiss(animated: true, completion: {
            self.setupInviteFriendsViewController()
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
        
        case .aboutUS:
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "💖 Rate Us", style: .default, handler: { (UIAlertAction) in
                self.openURL("https://itunes.apple.com/us/app/id1165924249?action=write-review", inVC: true)
            }))
            alertController.addAction(UIAlertAction(title: "📲 Support", style: .default, handler: { (UIAlertAction) in
                self.openURL("https://monkey.canny.io/requests", inVC: true)
            }))
            alertController.addAction(UIAlertAction(title: "👻 Follow Us Snapchat", style: .default, handler: { (UIAlertAction) in
                if (UIApplication.shared.canOpenURL(URL(string:"snapchat://")!)) {
                    UIApplication.shared.openURL(URL(string: "snapchat://add/monkeyapp")!)
                } else {
                    UIApplication.shared.openURL(URL(string: "http://snapchat.com/add/monkeyapp")!)
                }
            }))
            alertController.addAction(UIAlertAction(title: "📸 Follow Us Instgram", style: .default, handler: { (UIAlertAction) in
                if (UIApplication.shared.canOpenURL(URL(string:"instagram://")!)) {
                    UIApplication.shared.openURL(URL(string: "instagram://user?username=chatonmonkey")!)
                } else {
                    self.openURL("http://instagram/chatonmonkey", inVC: true)
                }
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

    let inviteFriendsData = SettingsTableViewCellData(for: .inviteFriends, title: "🎉 Invite friends")
    let talkToData = SettingsTableViewCellData(for: .talkTo, title: "💬 Talk to", style: .talkToCell) //SettingsTableViewCellData(for: .talkTo, title: "💖 Talk to")
    let acceptButtonData = SettingsTableViewCellData(for: .acceptButton, title: "😊 Accept control", style: .accetpBtnCell)
    
    let aboutUSData = SettingsTableViewCellData(for: .aboutUS, title: "🐒 About us")
    let signOutData = SettingsTableViewCellData(for: .signOut, title: "🙈 Sign out")
    var cells: [SettingsTableViewCellData] {
        return [
            talkToData,
            acceptButtonData,
            inviteFriendsData,
//            rateOnAppStoreData,
//            addOnSnapchatData,
//            legalStuffData,
            aboutUSData,
            signOutData]
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
			cell.acceptSwitch.open = !Achievements.shared.closeAcceptButton
			cell.acceptSwitch.switchValueChanged = {
				Achievements.shared.closeAcceptButton = !$0
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
        let firstNameLab:UILabel = UILabel.init(frame:CGRect(x: 16, y: 16, width: 119, height: 27))
        firstNameLab.text = "😊 Name :"
        firstNameLab.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        firstNameLab.textColor = UIColor.white
        self.editProfileContentView.addSubview(firstNameLab)
        
        
        self.firstNameTipLab = UILabel.init(frame: CGRect(x:45,y:16+28,width:UIScreen.main.bounds.size.width-60,height:14))
        self.firstNameTipLab.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.firstNameTipLab)
        
        self.firstNameTipLab.text = "You can change your name once every 2 months"
        self.firstNameTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
        
        let textFieldWidth:CGFloat = UIScreen.main.bounds.size.width-205-20
        
        self.firstNameField = UITextField.init(frame: CGRect(x:205,y:20,width:textFieldWidth,height:20))
        self.firstNameField.textColor = UIColor.init(white: 1, alpha: 0.7)
        self.firstNameField.text = ""
        self.firstNameField.delegate = self
        self.firstNameField.textAlignment = .right
        self.firstNameField.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.firstNameField)
        
        let birthdayLab:UILabel = UILabel.init(frame:CGRect(x:16,y:59,width:119,height:27))
        birthdayLab.text = "🎂 Birthday :"
        birthdayLab.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        birthdayLab.textColor = UIColor.white
        self.editProfileContentView.addSubview(birthdayLab)
        
        self.birthdayTipLab = UILabel.init(frame: CGRect(x:45,y:59+28,width:UIScreen.main.bounds.size.width-60,height:14))
        self.birthdayTipLab.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.birthdayTipLab)
        
        self.birthdayField = UITextField.init(frame: CGRect(x:205,y:63,width:textFieldWidth,height:20))
        self.birthdayField.textColor = UIColor.init(white: 1, alpha: 0.7)
        self.birthdayField.text = ""
        self.birthdayField.delegate = self
        self.birthdayField.textAlignment = .right
        self.birthdayField.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.birthdayField)
        
        let snapchatLab:UILabel = UILabel.init(frame:CGRect(x:16,y:59*2,width:200,height:27))
        snapchatLab.text = "👻 Snapchat :"
        snapchatLab.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        snapchatLab.textColor = UIColor.white
        self.editProfileContentView.addSubview(snapchatLab)
        
        self.snchatTipLab = UILabel.init(frame: CGRect(x:45,y:59*2+28,width:UIScreen.main.bounds.size.width-60,height:14))
        self.snchatTipLab.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.snchatTipLab)
        
        self.snapChatUserName = UsernameTextField.init(frame: CGRect(x:205,y:59*2+4,width:textFieldWidth,height:20))
        self.snapChatUserName.textColor = UIColor.init(white: 1, alpha: 0.7)
        self.snapChatUserName.text = ""
        self.snapChatUserName.delegate = self
        self.snapChatUserName.textAlignment = .right
        self.snapChatUserName.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        self.editProfileContentView.addSubview(self.snapChatUserName)
        
        self.cancelBtn = UIButton.init(type: .custom)
        self.cancelBtn.frame = CGRect(x:41,y:59*2+88,width:140,height:49)
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
        self.saveBtn.frame = CGRect(x: 195,y: 59 * 2 + 88, width: 140, height: 49)
        self.saveBtn.setTitle("Save", for: .normal)
        self.saveBtn.setTitleColor(UIColor.black, for: .normal)
        self.saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight:UIFontWeightMedium)
        self.saveBtn.layer.cornerRadius = 49/2.0;
        self.saveBtn.backgroundColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
        self.saveBtn.layer.masksToBounds = true
        self.editProfileContentView.addSubview(self.saveBtn)
		self.editStatus = false
        self.saveBtn.alpha = 0.25
        self.saveBtn.isUserInteractionEnabled = false
		self.saveBtn.addTarget(self, action: #selector(savePreferenceClick), for: UIControlEvents.touchUpInside)
        
        self.pickerContainerView = UIView.init(frame: CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220))
        self.pickerContainerView.backgroundColor = UIColor.white
        self.view.addSubview(self.pickerContainerView)
        
        self.datePicker = BirthdatePicker(frame: CGRect(x:0, y:0, width:self.pickerContainerView.frame.size.width, height:216))
        self.datePicker.addTarget(self, action: #selector(dateChanged),
                             for: .valueChanged)
        self.datePicker.datePickerMode = UIDatePickerMode.date
        self.pickerContainerView.addSubview(self.datePicker)
        
        self.cancelBtn.isHidden = true
        self.saveBtn.isHidden = true
    }
    func editCancelButtonClick(){
        self.view.endEditing(true)
        if self.editBirthdayStatus{
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220);
                    self.editProfileView.frame = CGRect(x:5,y:self.containerView.frame.origin.y,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
            },
                completion: { Void in()  }
            )
        }else{
         self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220);
         self.editProfileView.frame = CGRect(x:5,y:self.containerView.frame.origin.y,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
        }
        self.cancelBtn.isHidden = true
        self.saveBtn.isHidden = true
        self.firstNameTipLab.text = ""
        self.birthdayTipLab.text = ""
    }
    func dateChanged(datePicker : BirthdatePicker){
        self.birthdayField.text = datePicker.formattedDate
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == self.firstNameField{
            self.firstNameTipLab.text = ""
        }
        if textField == self.birthdayField{
            self.birthdayTipLab.text = ""
        }
        return true
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.firstNameTipLab.text = ""
        self.birthdayTipLab.text = ""
        self.editBirthdayStatus = false
        self.cancelBtn.isHidden = false
        self.saveBtn.isHidden = false
        if textField == self.firstNameField{
            self.firstNameTipLab.text = "You can change your name once every 2 months"
            self.firstNameTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
        }
        if textField == self.birthdayField{
            self.editBirthdayStatus = true
            self.firstNameTipLab.text = ""
            self.birthdayTipLab.text = "Better make sure yo, you can only change this once"
            self.birthdayTipLab.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
            self.view.endEditing(true)
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height-5-self.pickerContainerView.frame.size.height,width:self.pickerContainerView.frame.size.width,height:self.pickerContainerView.frame.size.height)
                    self.editProfileView.frame = CGRect(x:5,y:self.pickerContainerView.frame.origin.y-5-self.editProfileView.frame.size.height,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
            },
                completion: { Void in()  }
            )
            return  false
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
                            self.saveBtn.isUserInteractionEnabled = false
                            self.saveBtn.alpha = 0.25
                        }
                    }else{
                        self.saveBtn.isUserInteractionEnabled = false
                        self.saveBtn.alpha = 0.25
                    }
                }else{
                    self.saveBtn.isUserInteractionEnabled = false
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
        
        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue:UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: options,
                animations: {
                    self.editProfileView.frame = CGRect(x:5,y:UIScreen.main.bounds.size.height-deltaY-5-self.editProfileView.frame.size.height,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
            },
                completion: { Void in()  }
            )
        }else{
           self.editProfileView.frame = CGRect(x:5,y:UIScreen.main.bounds.size.height-deltaY-5-self.editProfileView.frame.size.height,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
        }
    }
    func keyBoardWillHide(notification: Notification){
        if self.editBirthdayStatus {
            return
        }
        self.pickerContainerView.frame = CGRect(x:0,y:UIScreen.main.bounds.size.height,width:UIScreen.main.bounds.size.width,height:220);
        self.editProfileView.frame = CGRect(x:5,y:self.containerView.frame.origin.y,width:self.editProfileView.frame.size.width,height:self.editProfileView.frame.size.height)
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
        self.titleLabel.frame = CGRect(x: 16, y: 0, width: 150, height: 64)
        self.titleLabel.text = ""
        self.titleLabel.textColor = UIColor.white
        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.textAlignment = NSTextAlignment.left
        self.contentView.addSubview(self.titleLabel)
		
		self.acceptSwitch = MonkeySwitch.init(frame: CGRect(x: self.contentView.frame.size.width - 40 - 18, y: 17, width: 40, height: 30))
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
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17)
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
        let alertController = UIAlertController(title: "Talk to", message: APIController.shared.currentExperiment?.talk_to_alert_message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "👫 Both", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender(nil)], completion: { $0?.log() })
            
            self.genderButton.setImage(#imageLiteral(resourceName: "GenderPreferenceButton"), for: .normal)
        }))
        
        alertController.addAction(UIAlertAction(title: "👱 Guys", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("male")], completion: { $0?.log() })
            
            self.genderButton.setImage(#imageLiteral(resourceName: "Guys"), for: .normal)
        }))
        
        alertController.addAction(UIAlertAction(title: "👱‍♀️ Girls", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("female")], completion: { $0?.log() })
            
            self.genderButton.setImage(#imageLiteral(resourceName: "Girls"), for: .normal)
        }))
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = AlertViewController()
        alertWindow.windowLevel = UIWindowLevelAlert ;
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true, completion: nil)
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
