//
//  IntroducingProfilesPopupViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class IntroducingProfilesPopupViewController: PopupViewController {
    @IBOutlet var textLabel: UILabel!
    override func viewDidLoad() {
        let font = UIFont.systemFont(ofSize: 28.0, weight: UIFontWeightSemibold)
        let introducing = NSAttributedString(string: "Introducing",
                                             attributes: [
                                                NSFontAttributeName: font,
                                                NSForegroundColorAttributeName: Colors.black,
            ])
        let profiles = NSAttributedString(string: " Profiles ",
                                             attributes: [
                                                NSFontAttributeName: font,
                                                NSForegroundColorAttributeName: Colors.blue,
            ])
        let onMonkey = NSAttributedString(string: "on Monkey!",
                                             attributes: [
                                                NSFontAttributeName: font,
                                                NSForegroundColorAttributeName: Colors.black,
            ])
        let attributedText = NSMutableAttributedString()
        attributedText.append(introducing)
        attributedText.append(profiles)
        attributedText.append(onMonkey)
        self.textLabel.attributedText = attributedText
    }
    @IBAction func nextVC(_ sender: BigYellowButton) {
        if APIController.shared.currentUser?.first_name == nil || APIController.shared.currentUser?.profile_photo_url == nil {
            self.present(self.storyboard!.instantiateViewController(withIdentifier: "editProfilePopup"), animated: true, completion: nil)
        } else {
            self.present(self.storyboard!.instantiateViewController(withIdentifier: "verifyBirthdayPopup"), animated: true, completion: nil)
        }
    }
}
