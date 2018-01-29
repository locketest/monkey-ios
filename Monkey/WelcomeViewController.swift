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

class WelcomeViewController: MonkeyViewController {
    @IBOutlet var nextButton: BigYellowButton!
//    @IBOutlet var termsTextView: UITextView!
    @IBOutlet var confettiView: ConfettiView!
    @IBOutlet var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        guard let phoneVC = UIStoryboard(name: "Verification", bundle: nil).instantiateInitialViewController() else {
            print("Error: Missing verification view controller.")
            return
        }
        UIView.animate(withDuration: 0.4, animations: {
            self.containerView.layer.opacity = 0
        }) { (Bool) in
            self.present(phoneVC, animated: false, completion: nil)
        }
    }
}
