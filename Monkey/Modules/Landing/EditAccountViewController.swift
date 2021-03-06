//
//  EditProfileViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/13/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift

class EditAccountViewController: MonkeyViewController, UITextFieldDelegate {
    
    /// A scroll view which contains all content except for the pickerContainerView.
    @IBOutlet var contentScrollView: UIScrollView!
    /// Contains the agePickerView as well as a Colors.yellow border line at the top.
    @IBOutlet var pickerContainerView: UIView!
    @IBOutlet var birthDateTextField: MakeTextFieldGreatAgain!
    @IBOutlet var snapchatTextField: UsernameTextField!
    @IBOutlet var nameTextField: MakeTextFieldGreatAgain!
    
    @IBOutlet var girlButton: SelectableButton!
    @IBOutlet var nextButton: BigYellowButton!
    @IBOutlet var boyButton: SelectableButton!
    
    @IBOutlet var snapchatEmoji: UILabel!
    @IBOutlet var nameEmoji: UILabel!
    @IBOutlet var birthdayEmoji: UILabel!
    /// Change to animate page left/right
    @IBOutlet var scrollViewRightConstraint: NSLayoutConstraint!

    /// Change to move picker up and down
    @IBOutlet var pickerViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var titleLabel: UILabel!
    /// The speed the UI animates into view after displaying Colors.blue.
    var smallScreenBackBtn: UIButton?
    let transitionTime = 0.4
    /// The delay before the UI animates into view after displaying Colors.blue.
    let transitionDelay = 0.1
    
    /// The currently selected gender. When set, the gender buttons displayed will update.
    var selectedGender: Gender? {
        didSet {
            self.nextButton.isEnabled = self.isValid
            self.boyButton.isSelected = false
            self.girlButton.isSelected = false
            switch selectedGender {
            case .male?:
                self.boyButton.isSelected = true
            case .female?:
                self.girlButton.isSelected = true
            default:
                break
            }
        }
    }
    
    /// True when all inputs have been properly filled out and the data can be submitted
    var isValid: Bool {
        if self.isOnSecondPageIfSmall {
            return self.selectedGender != nil && self.birthDateTextField.charactersCount > 0
        } else if self.isSmallScreen {
            return self.snapchatTextField.isValid && self.nameTextField.charactersCount > 2
        }
        return self.selectedGender != nil && self.snapchatTextField.isValid && self.nameTextField.charactersCount > 2 && self.birthDateTextField.charactersCount > 0
    }
    
    var isSmallScreen: Bool {
        return (self.view.window?.frame.height ?? 0.0) < 667.0
    }
    var isOnSecondPageIfSmall: Bool = false
    
    @IBOutlet var datePicker: BirthdatePicker!

    @IBAction func changeBirthday(_ sender: UIDatePicker) {
        self.birthDateTextField.text = datePicker.formattedDate
        self.birthdayEmoji.alpha = 1.0
        self.nextButton.isEnabled = self.isValid
    }
    
    override func viewDidLoad() {
     //   self.nextButton.isEnabled = self.isValid == true
        super.viewDidLoad()
		
		guard let currentUser = UserManager.shared.currentUser else {
			return
		}
		currentUser.gender.then { self.selectedGender = Gender(rawValue: $0) }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        self.nameTextField.delegate = self
        self.snapchatTextField.delegate = self
        self.birthDateTextField.delegate = self
        
        // input views need to be removed from any existing superview or app will crash (storyboard automatically sets a superview)
        // removing from superview also removes all constraints, so we need to save and readd them back
        let pickerConstraints = self.datePicker.constraints
        self.datePicker.removeFromSuperview()
        self.datePicker.addConstraints(pickerConstraints)
        self.datePicker.setDate(NSCalendar.current.date(byAdding: .year, value: RemoteConfigManager.shared.app_in_review ? -20 : -16, to: Date()) ?? Date(), animated: false)
        self.birthDateTextField.inputView = self.datePicker
        
        self.snapchatTextField.addTarget(self, action: #selector(snapchatDidChange), for: .editingChanged)
        self.birthDateTextField.selectable = false
        
        if self.isSmallScreen {
            self.smallScreenBackBtn = UIButton()
            self.smallScreenBackBtn!.frame = CGRect(x:10,y:41,width:22,height:22)
            self.smallScreenBackBtn!.setImage(UIImage.init(named: "back"), for: .normal)
            self.smallScreenBackBtn!.isHidden = true
            self.smallScreenBackBtn!.addTarget(self, action: #selector(smallScreenBackBtnClocked(_:)), for: .touchUpInside)
            self.view.addSubview(self.smallScreenBackBtn!)
        }

        UIView.animate(
            withDuration: transitionTime / 2,
            delay: 0.0,
            options: UIViewAnimationOptions.allowUserInteraction,
            animations: {
                self.pickerContainerView.layer.opacity = 1
                self.view.layoutIfNeeded()
        })

        self.prefillFields(with: currentUser)
    }
    
    @IBAction func editBirthday(sender:UITapGestureRecognizer) {
        self.birthDateTextField.becomeFirstResponder()
    }
    /**
     Fills in user data from the current `RealmUser` pulled from APIController's sharedInstance.
     
     - Parameter: user - the user (representing the current user from APIController) that is used to prefill in data
     
     */
    func prefillFields(with user:RealmUser) {
        self.nameTextField.text = user.first_name
        
        self.snapchatTextField.text = user.snapchat_username
        
        if let birthday = user.birth_date {
            self.datePicker.date = Date(timeIntervalSinceNow: birthday.timeIntervalSinceNow)
            self.changeBirthday(self.datePicker)
        }
        
        if let gender = user.gender {
            self.selectedGender = Gender(rawValue: gender)
        }
        
        self.snapchatEmoji.alpha = snapchatTextField.text?.count == 0 ? 0.35 : 1.0
        self.nameEmoji.alpha = nameTextField.text?.count == 0 ? 0.35 : 1.0
        self.birthdayEmoji.alpha = birthDateTextField.text?.count == 0 ? 0.35 : 1.0
    }
    
    func keyboardWillShow(_ notification: Notification) {
        guard self.view.window != nil else {
            return
        }
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double ?? 0.3
        let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt ?? 1
        
        guard let keyboardSize = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect else {
            return
        }
        
        self.pickerViewBottomConstraint.constant = keyboardSize.height + 30
            
        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {() -> Void in
            self.view.layoutIfNeeded()
        })
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func snapchatDidChange(textField: UITextField) {
        self.snapchatEmoji.alpha = textField.text?.count == 0 ? 0.35 : 1.0
        self.nextButton.isEnabled = self.isValid
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.nameTextField {
            self.snapchatTextField.becomeFirstResponder()
        } else if textField == self.snapchatTextField {
            if self.isSmallScreen {
                self.nextButton.isEnabled = self.isValid
            } else {
                self.birthDateTextField.becomeFirstResponder()
            }
        }
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //datePicker.setDate(NSCalendar.current.date(byAdding: .year, value: -16, to: Date())!, animated: false)

        // Move items off screen to animate in
        self.scrollViewRightConstraint.constant = -self.view.frame.size.width
        self.pickerContainerView.layer.opacity = 0
        self.contentScrollView.layer.opacity = 0
        self.nextButton.alpha = 0
        self.view.layoutIfNeeded()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.layoutIfNeeded()
        
        // Animate views in
        UIView.animate(
            withDuration: transitionTime,
            delay: transitionDelay,
            options: .curveEaseInOut,
            animations: {
                self.nameTextField.becomeFirstResponder()
                self.scrollViewRightConstraint.constant = 0
                self.contentScrollView.layer.opacity = 1
                self.nextButton.isEnabled = self.isValid
                self.view.layoutIfNeeded()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
    
    @IBAction func selectMaleGender(_ sender: SelectableButton) {
        self.selectedGender = .male
    }
    
    @IBAction func selectFemaleGender(_ sender: SelectableButton) {
        self.selectedGender = .female
    }

    /**
     Will trigger data submission except when the provided data is invalid.
     */
    func smallScreenBackBtnClocked(_ sender: Any) {
        if self.isSmallScreen {self.smallScreenBackBtn!.isHidden = true}
        self.nextButton.isEnabled = (self.snapchatTextField.isValid && self.nameTextField.charactersCount > 2) // reset for second page
        self.isOnSecondPageIfSmall = false
        self.contentScrollView.setContentOffset(CGPoint(x:0, y:0), animated:true)
        self.nameTextField.becomeFirstResponder()
    }
    
    @IBAction func nextVC(_ sender: BigYellowButton) {
        
        if self.isOnSecondPageIfSmall { // called first to avoid setup of small screen below on second time around
            self.view.isUserInteractionEnabled = false
            self.nextButton.isLoading = true
            self.uploadProfile()
        } else if !self.isSmallScreen { // if it's a big screen they've completed everything in one
            self.view.isUserInteractionEnabled = false
            self.nextButton.isLoading = true
            self.uploadProfile()
        } else {
            if self.isSmallScreen {self.smallScreenBackBtn!.isHidden = false}
            self.nextButton.isEnabled = (self.selectedGender != nil && self.birthDateTextField.charactersCount > 0) // reset for second page
            self.isOnSecondPageIfSmall = true
            self.contentScrollView.setContentOffset(CGPoint(x:self.contentScrollView.frame.size.width, y:0), animated:true)
            self.birthDateTextField.becomeFirstResponder()
        }
    }
    
    /**
     Uploads a users profile and then navigates to the next VC.
     */
    private func uploadProfile() {
        
        // You should not be able to access edit profile when not signed in.
        guard let currentUser = APIController.shared.currentUser else {
            print("can't get current user!")
            return
        }
        
        var attributes: [RealmUser.Attribute] = [
            .first_name(self.nameTextField.text),
            .snapchat_username(self.snapchatTextField.username),
			.birth_date(self.datePicker.date),
            ]
        self.selectedGender.then {
			attributes.append(.gender($0.rawValue))
		}
        
        currentUser.update(attributes: attributes) { (error) in
            guard error == nil else {
                if error?.status == "400" {
                    return self.present(error!.toAlert(onOK: { (UIAlertAction) in
                        self.view.isUserInteractionEnabled = true
                        self.nextButton.isLoading = false
                    }), animated: true, completion: nil)
                }
                self.present(error!.toAlert(onRetry: { (UIAlertAction) in
                    self.uploadProfile()
                }), animated: true, completion: nil)
                return
            }
			
            self.nextVC()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if self.isSmallScreen && textField == self.snapchatTextField && self.nameTextField.charactersCount > 0 {
            self.nextButton.isEnabled = textField.charactersCount > 2
        }
        
        if textField != self.nameTextField { // only want to filter on name controller
            return true                      // snapchat auto filters itself. We dont have to call super because we didnt override this implimentation
        }
        
        let text = (textField.text ?? "") as NSString
        let newTextCharacters = text
            .replacingCharacters(in: range, with: string)
            .filter { String($0).rangeOfCharacter(from: CharacterSet.letters) != nil }
        let newText = String(newTextCharacters)
        
        textField.text = newText
        
        self.nameEmoji.alpha = newText.count == 0 ? 0.35 : 1.0
        self.nextButton.isEnabled = self.isValid

        return false
    }

    
    /**
     Transitions to the next VC or dismisses depending on context.
     */
    private func nextVC() {
        self.nextButton.layer.opacity = 0
        
        // Dismiss picker
        self.view.endEditing(true)
        self.scrollViewRightConstraint.constant = self.view.frame.size.width
        
        UIView.animate(
            withDuration: transitionTime,
            delay: transitionDelay,
            options: UIViewAnimationOptions.allowUserInteraction,
            animations: {
                self.pickerContainerView.layer.opacity = 0
                self.view.layoutIfNeeded()
        })
        
        // 0.7 seconds refers to the delay for content to move to the side before allowing the next view controller to appear without animation (but appear smooth)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (Double(0.7))) {
            if Achievements.shared.grantedPermissionsV2 {
                self.present(UIStoryboard.init(name: "Match", bundle: nil).instantiateInitialViewController()!, animated: false)
            } else {
                let permissionVC = self.storyboard!.instantiateViewController(withIdentifier: "permVC")
                self.present(permissionVC, animated: false)
            }
        }
    }
    
}
