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
import SVProgressHUD
import Realm
import RealmSwift

class WelcomeViewController: MonkeyViewController,AKFViewControllerDelegate{
    @IBOutlet var nextButton: BigYellowButton!
//    @IBOutlet var termsTextView: UITextView!
    @IBOutlet var confettiView: ConfettiView!
    @IBOutlet var containerView: UIView!
    fileprivate var isAccountLogin = false
    
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)
    fileprivate var loginViewController: AKFViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginViewController = accountKit.viewControllerForPhoneLogin() as? AKFViewController
        var theme = AKFTheme.default()
        loginViewController?.delegate = self
        theme.backgroundColor = UIColor.init(red:77.0/255.0 , green: 79.0/255.0, blue: 1.0, alpha: 1.0)
        theme.buttonBackgroundColor = UIColor.yellow
        theme.buttonTextColor = UIColor.black
        theme.buttonDisabledBackgroundColor = UIColor.yellow.withAlphaComponent(0.4)
        theme.buttonBorderColor = UIColor.clear
        theme.buttonDisabledBorderColor = UIColor.clear
        theme.headerButtonTextColor = UIColor.init(red: 154.0/255.0, green: 154.0/255.0, blue: 154.0/255.0, alpha: 1.0)
        theme.headerBackgroundColor = theme.backgroundColor
        theme.headerTextColor = UIColor.yellow
        theme.inputTextColor = UIColor.white
        theme.inputBorderColor = UIColor.clear
        theme.titleColor = UIColor.white.withAlphaComponent(0.25)
        theme.inputBackgroundColor = UIColor.init(white: 0, alpha: 0.1);
        theme.textColor = UIColor.white.withAlphaComponent(0.25)
        loginViewController?.setTheme(theme)
        
        /* KEPT IN CASE BEN CHANGES HIS MIND
        let halfWhite = Colors.white(0.5)
        
        let center = NSMutableParagraphStyle()
        center.alignment = NSTextAlignment.center
        
        let part1 = NSAttributedString(string: "By continuing you agree to our\n",
                           attributes: [
                            NSFontAttributeName : UIFont.systemFont(ofSize: 12.0),
                            NSForegroundColorAttributeName : halfWhite,
                            NSParagraphStyleAttributeName : center
            ])
        
        let part2 = NSAttributedString(string: "Terms of Use",
                                       attributes: [
                                        NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12.0),
                                        NSForegroundColorAttributeName : halfWhite,
                                        NSParagraphStyleAttributeName : center
            ])
        
        let part3 = NSAttributedString(string: " and ",
                                       attributes: [
                                        NSFontAttributeName : UIFont.systemFont(ofSize: 12.0),
                                        NSForegroundColorAttributeName : halfWhite,
                                        NSParagraphStyleAttributeName : center
            ])
        
        let part4 = NSAttributedString(string: "Privacy Policy",
                                       attributes: [
                                        NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12.0),
                                        NSForegroundColorAttributeName : halfWhite,
                                        NSParagraphStyleAttributeName : center
            ])
        
        let concatenatedString = NSMutableAttributedString()
        concatenatedString.append(part1)
        concatenatedString.append(part2)
        concatenatedString.append(part3)
        concatenatedString.append(part4)
        termsTextView.attributedText = concatenatedString
        
        termsTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showLegal(sender:))))
         */
    }
    
    
    
    func showLegal(sender:UITapGestureRecognizer) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (UIAlertAction) in
        }))
        alertController.addAction(UIAlertAction(title: "Terms of Use", style: .default, handler: { (UIAlertAction) in
            self.openURL("http://monkey.cool/terms")
        }))
        alertController.addAction(UIAlertAction(title: "Privacy Policy", style: .default, handler: { (UIAlertAction) in
            self.openURL("http://monkey.cool/privacy")
        }))
        self.present(alertController, animated: true, completion: nil)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop animating when view is not visible
        confettiView.isAnimating = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Begin animating when view is about to appear
        confettiView.isAnimating = true
        
        if APIController.authorization != nil {
            self.dismiss(animated: false) {
                (self.presentingViewController as? AuthViewController)?.nextVC()
            }
        }

//        let label = UILabel.init(frame: CGRect.init(x: 0, y: 40, width: 1, height: 2))
//        label.text = Environment.baseURL + " ... " + Environment.environment.rawValue
//        label.sizeToFit()
//        self.view.addSubview(label)
    }
    
    @IBAction func nextVC(_ sender: BigYellowButton) {
//        guard let phoneVC = UIStoryboard(name: "Verification", bundle: nil).instantiateInitialViewController() else {
//            print("Error: Missing verification view controller.")
//            return
//        }
        if let viewController = loginViewController as? UIViewController {
            self.present(viewController, animated: false, completion: nil)
        }
//        UIView.animate(withDuration: 0.4, animations: {
//            self.containerView.layer.opacity = 0
//        }) { (Bool) in
//            self.present(phoneVC, animated: false, completion: nil)
//        }
    }
    var phoneAuthId:String?
    var realmPhoneAuth:RealmPhoneAuth? {
        let realm = try? Realm()
        return realm?.object(ofType: RealmPhoneAuth.self, forPrimaryKey: phoneAuthId)
    }
    func viewController(_ viewController: UIViewController!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
        print("Login succcess with AccessToken")
       
        let paramaters = ["accountkit_token": accessToken.tokenString]
        SVProgressHUD.show()
        JSONAPIRequest(url:"\(Environment.baseURL)/api/\(APIController.shared.apiVersion)/auth/accountkit",method:.post,parameters:paramaters,options:nil).addCompletionHandler { (response) in
            switch response {
            case .error(let error):
                NSLog("error login")
            case .success(let jsonAPIDocument):
                let data = jsonAPIDocument.dataResource?.json["attributes"] as! [String: String]
                let token:String = data["token"] as! String
                let phone_number:String = data["phone_number"] as! String
                RealmDataController.shared.apply(jsonAPIDocument) { (result) in
                    switch result {
                    case .error(let error):
                       NSLog("error login second")
                    case .success(let documentObjects):
                        let authorization = "Bearer \(token)"
                        let isNewUser = (jsonAPIDocument.dataResource?.json["action"] as? String) == "register"
                        APIController.signCodeSended(isNewUser: isNewUser)
                        
                        APIController.authorization = authorization
                        AnaliticsCenter.loginAccount()
                        let realmAuth:RealmPhoneAuth = (documentObjects[0] as! RealmPhoneAuth)
                        UserDefaults.standard.set(realmAuth.user?.user_id, forKey: "user_id")
                        Apns.update(callback: nil)
                        
                        UserDefaults.standard.set(true, forKey: "MonkeySignUp")
                        UserDefaults.standard.synchronize()
                        
                        UIView.animate(
                            withDuration: 0.4,
                            delay: 0.4,
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
                            if APIController.authorization != nil {
                                 (self.presentingViewController as? AuthViewController)?.startAuth()
                                
                            }
//                            var presentingVC = self.presentingViewController
//                            while presentingVC != nil && !(presentingVC is AuthViewController) {
//                                presentingVC = presentingVC?.presentingViewController
//                            }
//                            presentingVC?.dismiss(animated: false, completion: nil)
//                            self.dismiss(animated: fal, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
                        }
                        
                    }
                }
            }
            SVProgressHUD.dismiss()
        }
    }
    private func viewController(_ viewController: UIViewController!, didFailWithError error: NSError!) {
        print("We have an error \(error)")
    }
    
    func viewControllerDidCancel(_ viewController: UIViewController!) {
        print("The user cancel the login")
    }
}
