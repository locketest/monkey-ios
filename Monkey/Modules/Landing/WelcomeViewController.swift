//
//  WelcomeViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 12/5/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices
import AccountKit
import ObjectMapper
import RealmSwift

typealias AKFVCType = UIViewController & AKFViewController

class WelcomeViewController: MonkeyViewController {
	
    @IBOutlet var nextButton: BigYellowButton!
    @IBOutlet var confettiView: ConfettiView!
    @IBOutlet var containerView: UIView!
	@IBOutlet weak var termsTextView: UITextView!
	@IBOutlet weak var indicator: UIActivityIndicatorView!
	
	fileprivate var accountKitAuthSuccess = false
	
	private var enterTime: Date!
	private var accountKit = AKFAccountKit(responseType: .accessToken)
	private var loginViewController: AKFVCType?

    override func viewDidLoad() {
        super.viewDidLoad()
		indicator.isHidden = true

		loginViewController = accountKit.viewControllerForPhoneLogin() as? AKFVCType
		loginViewController?.delegate = self
		loginViewController?.title = "Verify phone number"
		loginViewController?.navigationItem.leftBarButtonItem = nil

        let theme = AKFTheme.default()
        theme.backgroundColor = UIColor.init(red:100.0 / 255.0 , green:74.0 / 255.0, blue:241.0/255.0, alpha: 1.0)
        theme.buttonBackgroundColor = UIColor.yellow
        theme.buttonTextColor = UIColor.black
        theme.buttonDisabledBackgroundColor = UIColor.yellow.withAlphaComponent(0.4)
        theme.buttonBorderColor = UIColor.clear
        theme.buttonDisabledBorderColor = UIColor.clear
        theme.headerButtonTextColor = UIColor.init(red:154.0 / 255.0, green:154.0 / 255.0, blue:154.0 / 255.0, alpha:1.0)
        theme.headerBackgroundColor = theme.backgroundColor
		theme.headerTextType = .appName
        theme.headerTextColor = UIColor.yellow
        theme.inputTextColor = UIColor.white
        theme.inputBorderColor = UIColor.clear
        theme.titleColor = UIColor.white.withAlphaComponent(0.25)
        theme.inputBackgroundColor = UIColor.init(white: 0, alpha: 0.1);
        theme.textColor = UIColor.white.withAlphaComponent(0.25)
        loginViewController?.setTheme(theme)

		configTermsView()
		
		enterTime = Date.init()
		AnalyticsCenter.log(event: .landingPageShow)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		enterTime = Date.init()
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Begin animating when view is about to appear
		
        if (accountKitAuthSuccess) {
			indicator.isHidden = false
			indicator.startAnimating()
		}else {
			confettiView.isAnimating = true
			self.containerView.layer.opacity = 1
		}
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Stop animating when view is not visible
		confettiView.isAnimating = false
		indicator.stopAnimating()
	}
	
	deinit {
		confettiView.isAnimating = false
		indicator.stopAnimating()
		loginViewController = nil
	}

    @IBAction func nextVC(_ sender: BigYellowButton) {
		AnalyticsCenter.log(withEvent: .landingPageClick, andParameter: [
			"session": Int(Date.init().timeIntervalSince1970 - enterTime.timeIntervalSince1970),
			])
        UIView.animate(withDuration: 0.4, animations: {
            self.containerView.layer.opacity = 0
        }) { (Bool) in
			if let viewController = self.loginViewController {
				self.present(viewController, animated: false, completion: nil)
			}
        }
    }
	
	private func goBack() {
		UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseInOut, animations: {
			self.containerView.alpha = 0
		}) { (_) in
			self.dismiss(animated: false, completion: nil)
		}
	}

	fileprivate func validateAccountkitAuth(_ accountkit_token: String) {
		var parameters = ["accountkit_token": accountkit_token]
        if Achievements.shared.deeplink_source.isEmpty == false {
            parameters["source"] = Achievements.shared.deeplink_source
        }
		
        JSONAPIRequest(url:"\(Environment.baseURL)/api/\(Authorization.api_version.rawValue)/\(Authorization.requst_subfix)", method: .post, parameters: parameters, options: [
            .header("version", Environment.appVersion),
            .header("lang", Environment.languageString),
            .header("device", "ios"),
            ]).addCompletionHandler {[weak self] (response) in
			guard let `self` = self else { return }

			switch response {
			case .error(_):
				self.goBack()
			case .success(let jsonAPIDocument):
                // clean deep link source
                Achievements.shared.deeplink_source = ""
				// create authorization
				if let authorization = Mapper<Authorization>().map(JSON: jsonAPIDocument.json), let threadSafeRealm = RealmDataController.shared.mainRealm {
					// set flag to log event
					UserManager.shared.loginMethod = LoginMethod(rawValue: authorization.action)
					
					try! threadSafeRealm.write {
						threadSafeRealm.create(RealmUser.self, value: [RealmUser.primaryKey(): authorization.user_id], update: true)
						threadSafeRealm.add(authorization, update: true)
					}
				}
				self.goBack()
			}
		}
	}
}

extension WelcomeViewController: AKFViewControllerDelegate {
	func viewController(_ viewController: UIViewController!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
		print("Login succcess with AccessToken")
		self.accountKitAuthSuccess = true
		self.validateAccountkitAuth(accessToken.tokenString)
		
		AnalyticsCenter.log(withEvent: .loginCompletion, andParameter: [
			"type": "success",
			])
	}

	private func viewController(_ viewController: UIViewController!, didFailWithError error: NSError!) {
		AnalyticsCenter.log(withEvent: .loginCompletion, andParameter: [
			"type": error.localizedDescription,
			])
		print("We have an error \(error)")
	}

	func viewControllerDidCancel(_ viewController: UIViewController!) {
		AnalyticsCenter.log(withEvent: .loginCompletion, andParameter: [
			"type": "cancel",
			])
		print("The user cancel the login")
	}
}

extension WelcomeViewController: UITextViewDelegate {
	func configTermsView() {
		let termsString = "Tap \"Agree & Continue\" to accept the Monkey Terms of Service and  Privacy Policy."
		let termsAttributeString = NSMutableAttributedString.init(string: termsString)
		let termsNSString = NSString.init(string: termsString)

		let termsRange = termsNSString.range(of: "Terms of Service")
		let privacyRange = termsNSString.range(of: "Privacy Policy")

		let paragraphStyle = NSMutableParagraphStyle.init()
		paragraphStyle.alignment = NSTextAlignment.center
		termsAttributeString.addAttributes([
			NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
			NSLinkAttributeName: "monkey://terms",
			], range: termsRange)
		termsAttributeString.addAttributes([
			NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
			NSLinkAttributeName: "monkey://privacy",
			], range: privacyRange)
		termsAttributeString.addAttributes([
			NSForegroundColorAttributeName: UIColor.init(red: 1, green: 1, blue: 0, alpha: 0.7),
			NSFontAttributeName: UIFont.systemFont(ofSize: 19, weight: UIFontWeightSemibold),
			NSParagraphStyleAttributeName: paragraphStyle,
			], range: NSMakeRange(0, termsNSString.length))
		termsTextView.attributedText = termsAttributeString;
		termsTextView.isSelectable = false

		let linkAttributes = [
			NSForegroundColorAttributeName: UIColor.init(red: 1, green: 1, blue: 0, alpha: 0.7),
			NSUnderlineColorAttributeName: UIColor.init(red: 1, green: 1, blue: 0, alpha: 0.7),
			] as [String : Any]
		termsTextView.linkTextAttributes = linkAttributes;
	}

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

	func openTextViewURL(_ URL: URL) {
		let host = URL.host
		if host?.compare("terms") == ComparisonResult.orderedSame {
			openURL(Environment.MonkeyAppTermsURL)
		}else if host?.compare("privacy") == ComparisonResult.orderedSame {
			openURL(Environment.MonkeyAppPrivacyURL)
		}
	}

	func openURL(_ urlString: String) {
		guard let url = URL(string: urlString) else {
			return
		}
		
		let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
		vc.modalPresentationCapturesStatusBarAppearance = true
		vc.modalPresentationStyle = .overFullScreen
		present(vc, animated: true, completion: nil)
	}
}
