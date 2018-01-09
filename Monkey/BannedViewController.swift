//
//  BannedViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/21/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import SafariServices

class BannedViewController: UIViewController {
    @IBOutlet var blockedTextView: MakeTextViewGreatAgain!
    override func viewDidLoad() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        if let blockedText = APIController.shared.currentExperiment?.blocked_text {
            self.blockedTextView.updateText(blockedText)
        }
    }
    func appMovedToBackground() {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func addSnapchat(_ sender: BigYellowButton) {
        guard let urlString = APIController.shared.currentExperiment?.banned_url else {
            return
        }
        guard let url = URL(string: urlString) else {
            return
        }
        let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true, completion: nil)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
