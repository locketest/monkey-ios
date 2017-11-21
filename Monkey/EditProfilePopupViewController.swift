//
//  EditProfilePopupViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire

class EditProfilePopupViewController: PopupViewController, UITextFieldDelegate, ProfilePhotoButtonViewDelegate {
    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var saveButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var addProfilePhotoButton: ProfilePhotoButtonView!
    @IBOutlet var nextButton: BigYellowButton!
    
    var isValid: Bool {
        get {
            return (self.addProfilePhotoButton.profileImage != nil || APIController.shared.currentUser?.profile_photo_url != nil) && firstNameTextField.charactersCount > 0
        }
    }
    override func viewDidLoad() {
        self.addProfilePhotoButton.delegate = self
        addProfilePhotoButton.presentingViewController = self
        addProfilePhotoButton.lightPlaceholderTheme = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        self.firstNameTextField.attributedPlaceholder = NSAttributedString(string: "Monkey", attributes: [NSForegroundColorAttributeName: Colors.black(0.08), NSFontAttributeName: UIFont.systemFont(ofSize: 32, weight: UIFontWeightSemibold)])
        self.nextButton.isEnabled = false
    }
    internal func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        self.saveButtonBottomConstraint.constant = keyboardRectangle.height + 20
        self.view.setNeedsLayout()
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !string.containsEmoji else {
            return false
        }
        textField.text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string).capitalizedFirstLetter
        self.nextButton.isEnabled = self.isValid
        return false
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillAppear(_ animated: Bool) {
        self.firstNameTextField.becomeFirstResponder()
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.firstNameTextField.resignFirstResponder()
    }
    @IBAction func nextVC(_ sender: BigYellowButton) {
        self.firstNameTextField.isEnabled = false
        self.addProfilePhotoButton.isUserInteractionEnabled = false
        self.nextButton.isLoading = true

        self.applyUpdates()
    }
    
    func loadingCancelled() {
        self.firstNameTextField.isEnabled = true
        self.addProfilePhotoButton.isUserInteractionEnabled = true
        self.nextButton.isLoading = false
    }
    func applyUpdates() {
        APIController.shared.currentUser?.update(attributes: [
            .first_name(self.firstNameTextField.text),
            ]) { (error: APIError?) in
                guard error == nil else {
                    if error?.status == "400" {
                        return self.present(error!.toAlert(onOK: { (UIAlertAction) in
                            self.loadingCancelled()
                        }), animated: true, completion: nil)
                    }
                    return self.present(error!.toAlert(onRetry: { (UIAlertAction) in
                        self.applyUpdates()
                    }), animated: true, completion: nil)
                }
                self.addProfilePhotoButton.uploadProfileImage {
                    self.nextVC()
                }
        }
    }

    
    func nextVC() {
        if APIController.shared.currentUser?.birth_date == nil {
            self.present(self.storyboard!.instantiateViewController(withIdentifier: "verifyBirthdayPopup"), animated: true, completion: nil)
        } else {
            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    func profilePhotoButtonView(_ profilePhotoButtonView: ProfilePhotoButtonView, selectedImage: UIImage) {
        self.nextButton.isEnabled = self.isValid
    }
}
