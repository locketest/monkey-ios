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
import Realm
import RealmSwift

typealias AKFVCType = UIViewController & AKFViewController

class WelcomeViewController: MonkeyViewController {
    @IBOutlet var nextButton: BigYellowButton!
    @IBOutlet var confettiView: ConfettiView!
    @IBOutlet var containerView: UIView!
	@IBOutlet weak var indicator: UIActivityIndicatorView!
	
	var accountKitAuthSuccess = false
	var accountKit = AKFAccountKit(responseType: .accessToken)
	var loginViewController: AKFVCType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
		indicator.isHidden = true
		
		loginViewController = accountKit.viewControllerForPhoneLogin() as? AKFVCType
		loginViewController?.delegate = self
		loginViewController?.title = "Verify phone number"
		loginViewController?.navigationItem.leftBarButtonItem = nil
		
        let theme = AKFTheme.default()
        theme.backgroundColor = UIColor.init(red:77.0 / 255.0 , green:79.0 / 255.0, blue:1.0, alpha: 1.0)
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop animating when view is not visible
        confettiView.isAnimating = false
		
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		indicator.stopAnimating()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Begin animating when view is about to appear
        
        if APIController.authorization != nil {
			self.dismiss(animated: false, completion: nil)
		}else if (accountKitAuthSuccess) {
			indicator.isHidden = false
			indicator.startAnimating()
		}else {
			confettiView.isAnimating = true
			self.containerView.layer.opacity = 1
		}
    }
    
    @IBAction func nextVC(_ sender: BigYellowButton) {
        UIView.animate(withDuration: 0.4, animations: {
            self.containerView.layer.opacity = 0
        }) { (Bool) in
			if let viewController = self.loginViewController {
				self.present(viewController, animated: false, completion: nil)
			}
        }
    }
	
	func validateAccountkitAuth(_ accountkit_token: String) {
		let parameters = ["accountkit_token": accountkit_token]
		
		JSONAPIRequest(url:"\(Environment.baseURL)/api/\(APIController.shared.apiVersion)/auth/accountkit", method:.post, parameters:parameters, options:nil).addCompletionHandler {[weak self] (response) in
			guard let `self` = self else { return }
			
			switch response {
			case .error( _):
				NSLog("error login")
			case .success(let jsonAPIDocument):
				if let attributes = jsonAPIDocument.dataResource?.json["attributes"] as? [String: String], let relationships = jsonAPIDocument.dataResource?.json["relationships"] as? [String: [String: [String: String]]] {
					guard let token = attributes["token"], let user = relationships["user"], let user_data = user["data"], let user_id = user_data["id"] else {
						NSLog("error login second")
						return
					}
					
					RealmDataController.shared.apply(jsonAPIDocument) { (result) in
						switch result {
						case .error( _):
							NSLog("error login")
						case .success( _):
							let authorization = "Bearer \(token)"
							let isNewUser = (jsonAPIDocument.dataResource?.json["action"] as? String) == "register"
							APIController.signCodeSended(isNewUser: isNewUser)
							
							APIController.authorization = authorization
							AnaliticsCenter.loginAccount()
							UserDefaults.standard.set(user_id, forKey: "user_id")
							
							Apns.update(callback: nil)
							self.dismiss(animated: false, completion: nil)
							
							UIView.animate(
								withDuration: 0.4,
								delay: 0.1,
								options:.curveEaseInOut,
								animations: {
									self.containerView.alpha = 0
									self.view.layoutIfNeeded()
							}){ (Bool) in
								self.dismiss(animated: false, completion: nil)
							}
						}
					}
				}
			}
		}
	}
}

extension WelcomeViewController: AKFViewControllerDelegate {
	func viewController(_ viewController: UIViewController!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
		print("Login succcess with AccessToken")
		accountKitAuthSuccess = true
		self.validateAccountkitAuth(accessToken.tokenString)
	}
	
	private func viewController(_ viewController: UIViewController!, didFailWithError error: NSError!) {
		print("We have an error \(error)")
	}
	
	func viewControllerDidCancel(_ viewController: UIViewController!) {
		print("The user cancel the login")
	}
}

