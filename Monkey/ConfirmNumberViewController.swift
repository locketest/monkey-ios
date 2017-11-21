//
//  ConfirmNumberViewController.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/22/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Amplitude_iOS

class ConfirmNumberViewController: MonkeyViewController {
    
    /// These buttons are to provide input for the quasi textfields to confirm a users number
    @IBOutlet var keypadButtons:[KeypadButton]!
    
    
    /// These buttons displaying the input used to confirm a user's number
    @IBOutlet var inputLabelOne: InputLabel!
    @IBOutlet var inputLabelTwo: InputLabel!
    @IBOutlet var inputLabelThree: InputLabel!
    @IBOutlet var inputLabelFour: InputLabel!
    @IBOutlet var inputLabelFive: InputLabel!
    @IBOutlet var inputLabelSix: InputLabel!
    
    lazy var inputLabels:[InputLabel] = [self.inputLabelOne, self.inputLabelTwo, self.inputLabelThree, self.inputLabelFour, self.inputLabelFive, self.inputLabelSix]
    
    /// The container view holding all subviews. It's trailing margin constraint is used to animate the controller in and out
    @IBOutlet var containerView: UIView!
    /// The trailing margin of the container view housing all the views. Its value is changed to simulate a sliding animation
    @IBOutlet var containerViewTrailingMarginConstraint: NSLayoutConstraint!
    /// The speed the UI animates into view after displaying Colors.blue.
    let transitionTime = 0.4
    /// The delay before the UI animates into view after displaying Colors.blue.
    let transitionDelay = 0.1
    /// The button responsible for resending a code
    @IBOutlet var resendCodeButton: UIButton!
    /// This string contains the current code the user has input, converted from emojis to numbers if necessary
    var userInputCode = "" {
        didSet {
            for (index, element) in self.inputLabels.enumerated() {
                if self.userInputCode.characters.count > index {
                    let stringValue = String(self.userInputCode.characters[self.userInputCode.index(userInputCode.startIndex, offsetBy: index)])
                    element.text = keypadButton(for: stringValue)?.titleLabel?.text
                } else {
                    element.text = ""
                }
            }
        }
    }
    /// The ID of the realmPhoneAuth object identifying the user's current attempt to verify their phone
    var phoneAuthId:String?
    /// Number of seconds before refresh
    var secondsRemainingBeforeResendCodeIsEnabled:Double?
    /// Timer that ticks down 1 second at a time from the # of seconds passed by PhoneViewController, when it reaches 0 it is invalidated
    var resendTimer:Timer?
    /// This button enables when the user has input 'codeLength' times, and validates the code
    @IBOutlet var nextButton: BigYellowButton!
    /// Button to delete the last input text
    @IBOutlet var deleteButton:UIButton!
    /// RealmPhoneAuth reference for resending & verifying phone numberby
    var realmPhoneAuth:RealmPhoneAuth? {
        let realm = try? Realm()
        return realm?.object(ofType: RealmPhoneAuth.self, forPrimaryKey: phoneAuthId)
    }
    @IBOutlet var phoneNumberTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.secondsRemainingBeforeResendCodeIsEnabled = self.realmPhoneAuth?.resend_after.value
        if let countryCode = self.realmPhoneAuth?.country_code, let phoneNumber = self.realmPhoneAuth?.phone_number {
            self.phoneNumberTitleLabel.text = "Code sent to " + "+" + countryCode + phoneNumber
        } else {
            // default value for top text
            self.phoneNumberTitleLabel.text = "We sent you a secret code"
        }
        
        if let characterSet = realmPhoneAuth?.character_set?.components(separatedBy: ",") {
                    self.updateButtonTitles(with: characterSet)
        }
        self.nextButton.isEnabled = false

        if realmPhoneAuth?.code_length.value == 4 {
            self.inputLabelFive.removeFromSuperview()
            self.inputLabelSix.removeFromSuperview()
        }
        
        resendTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(tickResend), userInfo: nil, repeats: true)
        RunLoop.main.add(resendTimer!, forMode: .commonModes)
        self.resendCodeButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.containerViewTrailingMarginConstraint.constant = -self.containerView.frame.size.width
        // layer is animated back to 1 in viewDidAppaer as part of the present animation
        self.containerView.layer.opacity = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(
            withDuration: transitionTime,
            delay: transitionDelay,
            options: .curveEaseInOut,
            animations: {
                self.containerView.layer.opacity = 1
                self.containerViewTrailingMarginConstraint.constant = 0
                self.view.layoutIfNeeded()
        })
    }
    
    /// Counts down 1 second from the `secondsToResendCode`, when it reaches 0 it enables the resend button & invalidates the timer
    func tickResend() {
        guard var secondsRemaining = self.secondsRemainingBeforeResendCodeIsEnabled else {
            return
        }
        secondsRemaining -= 1
        self.secondsRemainingBeforeResendCodeIsEnabled = secondsRemaining
        
        if secondsRemaining <= 0 {
            self.resendCodeButton.isEnabled = true
            self.resendTimer?.invalidate()
            self.resendTimer = nil
            self.resendCodeButton.setTitle("Resend code", for: .normal)
            return
        }
        
        UIView.performWithoutAnimation {
            self.resendCodeButton.setTitle("Resend code in \(String(format: "%.0f", secondsRemaining))", for: .normal)
        }
    }
    
    private func updateButtonTitles(with characterSet:[String]) {
        
        guard characterSet.count == 10 else {
            print("ConfirmNumberViewController: Server failed to return a valid authentication character set")
            return
        }
        
        for keypadButtonValue in 0...9 {
            self.keypadButton(for: "\(keypadButtonValue)")?.setTitle(characterSet[keypadButtonValue], for: .normal)
        }
    }
    
    func keypadButton(for value: String) -> KeypadButton? {
        return self.keypadButtons.first { $0.value == value }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Types a character from the keypad. All keypadButtons trigger this action.
    ///
    /// parameter sender - The keypad button pressed. It's property `value` will be appended to `userInputCode`
    @IBAction func userDidInputValue(sender: KeypadButton) {
        
        guard let codeLength = realmPhoneAuth?.code_length.value else {
            print("Server did not return the expected code length")
            return
        }
    
        if self.userInputCode.characters.count >= codeLength { // don't want to do anything if already full
            return
        }
        
        guard let keyboardIndex = sender.value else {
            print("KeypadButton does not have a value. Please set value in storyboard")
            return
        }
        
        TapticFeedback.impact(style: .heavy)
        self.userInputCode = self.userInputCode + keyboardIndex
        self.nextButton.isEnabled = self.userInputCode.characters.count == realmPhoneAuth?.code_length.value
    }
    
    // Sent by the 'deleteButton', this method simply removes the last written user input. If we have no user inputs, the method should end without execution.
    @IBAction func keypadBackspace(sender: UIButton) {
        if self.userInputCode.isEmpty { // don't want to do anything if already empty
            return
        }

        self.userInputCode = String(self.userInputCode.characters.dropLast())
        self.nextButton.isEnabled = false
    }
    
    @IBAction func submitUserCode(_ sender: BigYellowButton) {
        self.nextButton.isLoading =  true
        self.view.isUserInteractionEnabled = false
        guard self.userInputCode.characters.count == realmPhoneAuth?.code_length.value else {
            print("Next button was improperly enabled in ConfirmViewController. User attempted to validate a code with incorrect length")
            self.clearUserInput()
            self.displayInvalidCodeAlert(title:"Incorrect Code:", message:"😬 Please check your code and try again", responseStatus: nil)
            return
        }
        
        guard let phoneAuthID = self.phoneAuthId else {
            print("A phone auth ID was not passed to the ConfirmNumberViewController")
            return
        }
        
        self.validatePhoneAuth(phoneAuthID, code: self.userInputCode)
        
    }
    
    @IBAction func dismiss(sender: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }
    
    func validatePhoneAuth(_ phoneAuthId:String, code:String) {
        let parameters:[String:Any] = ["code":code]
        self.realmPhoneAuth?.update(attributesJSON: parameters, completion: { [weak self] (error:APIError?) in
            guard let `self` = self else { return }
            guard error == nil else {
                error?.log()
                self.clearUserInput()
                self.displayInvalidCodeAlert(title:"Uh oh!", message: error?.message ?? "😬 Please check your code and try again", responseStatus: error?.status)
                Amplitude.shared.logEvent("Error Validating Phone Verification Code", withEventProperties: [
                    "code": code,
                    "message": error?.message ?? "😬 Please check your code and try again"
                    ])
                return
            }
            
            guard let token = self.realmPhoneAuth?.token, let user = self.realmPhoneAuth?.user else {
                print("RealmPhoneAuth object was not properly synced. Unable to validate phone auth because missing token or user")
                self.clearUserInput()
                self.displayInvalidCodeAlert(title:"Incorrect Code:", message:"😬 Please check your code and try again", responseStatus:nil)
                return
            }
            Amplitude.shared.logEvent("Validated Phone Verification Code", withEventProperties: [
                "code": code,
                ])
            let authorization = "Bearer \(token)"

            Amplitude.shared.setUserId(user.user_id!)
                
            UserDefaults.standard.set(user.user_id!, forKey: "user_id")
            APIController.authorization = authorization
            
            Apns.update(callback: nil)
            
            UIView.animate(
                withDuration: self.transitionTime,
                delay: self.transitionDelay,
                options:.curveEaseInOut,
                animations: {
                    self.containerView.alpha = 0
                    self.view.layoutIfNeeded()
            }){ (Bool) in
                var presentingVC = self.presentingViewController
                while presentingVC != nil && !(presentingVC is AuthViewController) {
                    presentingVC = presentingVC?.presentingViewController
                }
                presentingVC?.dismiss(animated: false, completion: nil)
            }
        })
    }

    @IBAction func requestResendCode(_ sender: UIButton) {
        
        let parameters:[String:Any] = ["resend_count":1]
        self.resendCodeButton.setTitle("Code sent to +\(self.realmPhoneAuth?.country_code ?? "")\(self.realmPhoneAuth?.phone_number ?? "")", for: .normal)
        self.resendCodeButton.isEnabled = false

        self.realmPhoneAuth?.update(attributesJSON: parameters, completion: { [weak self] (error:APIError?) in
            guard error == nil else {
                error?.log()
                let alert = UIAlertController(title: "Something went wrong", message: error?.message ?? "Please try again.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: {
                    (UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self?.present(alert, animated: true, completion: nil)
                Amplitude.shared.logEvent("Error Resending Phone Verification Code", withEventProperties: [
                    "message": error?.message ?? "Please try again."
                    ])
                return
            }
            Amplitude.shared.logEvent("Resent Phone Verification Code")
        })
    }
    
    fileprivate func displayInvalidCodeAlert(title:String, message:String, responseStatus:String?) {
        let confirmation = UIAlertController(title: title, message: message, preferredStyle: .alert)
        confirmation.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // to avoid the keyboard dismissing we need to present on different window
        // (See: https://stackoverflow.com/questions/28564710/keep-keyboard-on-when-uialertcontroller-is-presented-in-swift)
        let rootViewController: UIViewController = (UIApplication.shared.windows.last?.rootViewController)!
        rootViewController.present(confirmation, animated: true, completion: {
            guard let status = responseStatus else {
                return
            }
            if status != "401" {
                self.dismiss(animated: true)
            }
        })
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: self.transitionTime,
            delay: self.transitionDelay,
            options: .curveEaseInOut,
            animations: {
                self.containerView.layer.opacity = 0
                self.containerViewTrailingMarginConstraint.constant = -self.containerView.frame.size.width
                self.view.layoutIfNeeded()
        },
            completion: { (Bool) in
                super.dismiss(animated: false, completion: nil)
        })
    }
    
    /// Resets all userInputs so that they may enter a code again from scratch.
    /// Called most commonly when user inputs wrong code but also if an error occurs
    private func clearUserInput() {
        self.userInputCode = "" // automatically clears labels on didSet
        self.nextButton.isLoading = false
        self.view.isUserInteractionEnabled = true
        self.nextButton.isEnabled = false
    }
}
