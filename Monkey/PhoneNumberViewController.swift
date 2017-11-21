//
//  PhoneNumberViewController.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/22/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import SafariServices
import Amplitude_iOS

class PhoneNumberViewController: MonkeyViewController, UITextViewDelegate {
    @IBOutlet var phoneNumberTextField: MakeTextFieldGreatAgain!
    @IBOutlet var countryCodeButton: UIButton!
    @IBOutlet var sendButton: BigYellowButton!
    @IBOutlet var termsTextView: UITextView!
    /// The picker view for selecting a Country.
    @IBOutlet var countryPickerView: UIPickerView!
    
    let countries = Country.allCountries
    var selectedCountry: Country? {
        didSet {
            var countryCodeButtonTitle = ""
            if let selectedCountry = self.selectedCountry {
                self.countryPickerView.selectRow(self.countries?.index(of: selectedCountry) ?? 0, inComponent: 0, animated: false)
                countryCodeButtonTitle = "\(selectedCountry.emoji) +\(selectedCountry.code)"
                if let oldValue = oldValue {
                    Amplitude.shared.logEvent("Changed Phone Verification Country", withEventProperties: [
                        "from_country": oldValue.code,
                        "to_country": selectedCountry.code
                        ])
                }
            } else {
                self.countryPickerView.selectRow(0, inComponent: 0, animated: false)
            }
            self.countryCodeButton.setTitle(countryCodeButtonTitle, for: .normal)
        }
    }
    
    /// The view containing all the subviews, its trailingMarginConstraint will be animated
    @IBOutlet var containerView: UIView!
    /// The speed the UI animates into view after displaying Colors.blue.
    let transitionTime = 0.4
    /// The delay before the UI animates into view after displaying Colors.blue.
    let transitionDelay = 0.1
    /// The trailing margin of the container view housing all the views. Its value is changed to simulate a sliding animation
    @IBOutlet var containerViewTrailingMarginConstraint: NSLayoutConstraint!
    /// The space between the bottom of the view and the send secret code button.
    /// Having a reference allows us to set it to 20 above keyboard height no matter what screen size we're using
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    /// True when user has confirmed number is correct
    var hasUserConfirmedNumber = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        // Do any additional setup after loading the view.
        // Most efficient way to get a left pad on the text field while still performing masking corner radius
        
        // Creates and sets the attributed string
        let termsString = NSMutableAttributedString()
        termsString.append(NSAttributedString(string: "By tapping “Send secret emoji code” below, Monkey will send you an SMS to confirm your phone number. On the next screen, you can choose “Resend Code” to initiate another SMS. Message & data rates may apply. By continuing you agree to our "))
        // Adds link attributes, and the underline style. The UITextView takes care of the link color.
        termsString.append(NSAttributedString(string: "Terms of Use", attributes: [
            NSUnderlineStyleAttributeName:NSUnderlineStyle.styleSingle.rawValue,
            NSLinkAttributeName:"monkey://terms"
            ]))
        termsString.append(NSAttributedString(string: " and "))
        termsString.append(NSAttributedString(string: "Privacy Policy", attributes: [
            NSUnderlineStyleAttributeName:NSUnderlineStyle.styleSingle.rawValue,
            NSLinkAttributeName:"monkey://privacy"
            ]))

        termsString.append(NSAttributedString(string: "."))
        termsString.addAttributes([
            NSForegroundColorAttributeName: Colors.white(0.25),
            NSFontAttributeName: UIFont.systemFont(ofSize: 13),
            ], range: NSRange(location: 0, length: termsString.length))
        self.termsTextView.attributedText = termsString
        self.selectedCountry = self.countries?.country(forLocale: .current) ?? self.countries?.country(withISO: "US")
    }
    
    internal func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        guard let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardRectangle = keyboardFrame.cgRectValue
        self.nextButtonBottomConstraint.constant = keyboardRectangle.height + 20
        self.view.setNeedsLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.containerView.layer.opacity = 0
        self.sendButton.setTitle("Send secret code", for: .normal)
        self.sendButton.emojiLabel?.layer.removeAllAnimations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.phoneNumberTextField.becomeFirstResponder()
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
    
    
    /// Send SMS message, triggered by the BigYellowButton in the UI, ensures we have text & then sends message to server requesting an sms code that we can verify
    @IBAction func sendButtonPressed(sender:BigYellowButton) {
        
        guard self.hasUserConfirmedNumber else {
            var phoneNumberConfirmationAlertTitle = "📲 Is this number correct?"
            if let selectedCountry = self.selectedCountry {
                phoneNumberConfirmationAlertTitle += " +\(selectedCountry.code)\(self.phoneNumberTextField.text ?? "")"
            }
            let phoneNumberConfirmationAlert = UIAlertController(title: phoneNumberConfirmationAlertTitle, message: nil, preferredStyle: .alert)
            phoneNumberConfirmationAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.sendButtonPressed(sender: sender)
            }))
            phoneNumberConfirmationAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
                self.hasUserConfirmedNumber = false
            }))
            
            /// to avoid the keyboard dismissing we need to present on different window (See: https://stackoverflow.com/questions/28564710/keep-keyboard-on-when-uialertcontroller-is-presented-in-swift)
            UIApplication.shared.windows.last?.rootViewController?.present(phoneNumberConfirmationAlert, animated: true)
            
            self.hasUserConfirmedNumber = true
            return
        }
        
        guard let phoneNumber = self.phoneNumberTextField.text?.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined() else {
            return
        }

        guard let countryCode = self.selectedCountry?.code else {
            print("Attempting to send a phone number with no country code")
            return
        }
        self.requestVerificationCode(phoneNumber, countryCode: countryCode)
    }
    
    @IBAction func pickCountryCode() {
        self.phoneNumberTextField.resignFirstResponder()
    }
    
    /// Requests verification code from server, takes phone number and country code as input.
    /// Makes JSONAPIRequest and then moves the user onto the next screen with information we get from the response (character set).
    /// Returns no value. phoneNumber and countryCode are implicitly unwrapped, should guard against nil values before calling this function.
    func requestVerificationCode(_ phoneNumber:String, countryCode:String) {
        Amplitude.shared.logEvent("Requested Phone Verification Code", withEventProperties: [
            "country_code": countryCode,
            "phone_number": phoneNumber,
            ])
        let parameters:[String:Any] = ["data":["type":"phone_auths", "attributes":["country_code":countryCode, "phone_number":phoneNumber]]]
        
        self.sendButton.setTitle("Sending secret code", for: .normal)

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(.pi * 2.0)
        rotateAnimation.duration = 1.5
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.repeatCount = .infinity
        
        self.sendButton.emojiLabel?.layer.add(rotateAnimation, forKey: nil)
        
        RealmPhoneAuth.create(parameters: parameters) { (result: JSONAPIResult<[RealmPhoneAuth]>) in
            switch result {
            case .success(let phoneAuths):
                guard let authObject = phoneAuths.first else {
                    self.showConnectionErrorAlert(message:"Uh oh! Something went wrong. Try again")
                    return
                }
                
                guard let verifyViewController = self.storyboard?.instantiateViewController(withIdentifier: "verifyVC") as? ConfirmNumberViewController else {
                    print("Could not instantiate verify view controller from storyboard")
                    return
                }
                
                verifyViewController.phoneAuthId = authObject.phone_auth_id
                
                UIView.animate(
                    withDuration: self.transitionTime,
                    delay: self.transitionDelay,
                    options:.curveEaseInOut,
                    animations: {
                        let widthConstant = self.containerView.frame.width
                        self.containerViewTrailingMarginConstraint.constant = widthConstant
                        self.containerView.layer.opacity = 0
                        self.view.endEditing(true)
                        self.view.layoutIfNeeded()
                }){(Bool) in
                    self.present(verifyViewController, animated: false)
                }

            case .error(let error):
                error.log()
                self.showConnectionErrorAlert(message:error.message)
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sendButton.emojiLabel?.layer.removeAllAnimations()
    }
    
    func showConnectionErrorAlert(message: String) {
        Amplitude.shared.logEvent("Error Requesting Phone Verification Code", withEventProperties: [
            "message": message,
            ])
        self.hasUserConfirmedNumber = false
        self.sendButton.titleLabel?.text = "Send secret code"
        self.sendButton.emojiLabel?.layer.removeAllAnimations()
        
        let sendCodeConfirmationAlert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        sendCodeConfirmationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        /// to avoid the keyboard dismissing we need to present on different window (See: https://stackoverflow.com/questions/28564710/keep-keyboard-on-when-uialertcontroller-is-presented-in-swift)
        UIApplication.shared.windows.last?.rootViewController?.present(sendCodeConfirmationAlert, animated: true)
    }
    
    /// Always returns no because we don't want the URL to open. The URL's 'host' property will contain the action we are trying to perform. 'terms' and 'privacy'
    /// For iOS 7...9
    @available(iOS, deprecated: 10.0)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        self.openTextViewURL(url)
        return false
    }
    
    /// For iOS 10
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.openTextViewURL(url)
        return false
    }
    
    /// The attributed links in the UITextView that show our terms etc. have links which `host` value is equal to the destination we are trying to open (terms or privacy)
    func openTextViewURL(_ url:URL) {
        let action = url.host
        
        if action == "terms" { // show terms
            self.openURL("http://monkey.cool/terms", inVC: true)
        } else if action == "privacy" { // show privacy
            self.openURL("http://monkey.cool/privacy", inVC: true)
        }
    }
    
    /// Presents a safari view controller over the passed view controller, and opens to the passed url
    ///
    /// parameter urlString - The string value for the URL to be opened in the safari view controller
    /// parameter inVC - The view controller that we present the safari view controller over

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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
