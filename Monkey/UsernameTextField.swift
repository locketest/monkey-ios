//
//  UsernameTextField.swift
//  Monkey
//
//  Created by Isaiah Turner on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import UIKit
/**
 A TextField that rejects input which is not valid in a Snapchat username.
 */
@IBDesignable class UsernameTextField: MakeTextFieldGreatAgain, UITextFieldDelegate {

    /// The current text in the TextField.
    var username: String {
        get {
            return self.text ?? ""
        }
        set {
            self.text = newValue
        }
    }

    /// Returns true when the username is in snapchat username format.
    var isValid: Bool {
        return self.username.characters.count >= 3
    }

    var keyboardHeight: CGFloat = 0 {
        didSet {
            self.keyboardHeightChanged?()
        }
    }

    /// Called when the next/send/return button is pressed (regardless of validity).
    var didSelect: ((_ snapchat: String) -> Void)?

    /// Called when a username is in snapchat format and can be submitted.
    var didValidate: ((_ isValid: Bool) -> Void)? {
        didSet {
            // Call with the current value whenever a hook is added.
            self.didValidate?(self.isValid)
        }
    }

    /// Called when the keyboard height changes and the UserNameTextField is the firstResponder
    var keyboardHeightChanged: (() -> Void)?


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.afterInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.afterInit()
    }

    /// Sets the delegate to self and customizes any view elements.
    private func afterInit() {
        self.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.didSelect?(self.username)
        return false
    }

    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = self.username as NSString
        let newTextCharacters = text
            .replacingCharacters(in: range, with: string)
            .characters
            .filter { String($0).rangeOfCharacter(from: .snapchat) != nil }
        let newText = String(newTextCharacters)

        if newText.utf16.count <= 30 {
            self.username = newText
            self.didValidate?(self.isValid)
        }

        return false
    }

    internal func keyboardWillShow(notification: NSNotification) {
        guard self.isFirstResponder else {
            // Don't update view if the keyboard height changes due to something such as an alert.
            return
        }
        let userInfo = notification.userInfo!
        let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        self.keyboardHeight = keyboardRectangle.height
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
