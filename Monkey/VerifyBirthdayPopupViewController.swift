//
//  EditProfilePopupViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class VerifyBirthdayPopupViewController: PopupViewController {

    @IBOutlet var nextButton: BigYellowButton!
    @IBOutlet var birthDateTextField: UITextField!
    let dateFormatter = DateFormatter()
    @IBOutlet var datePicker: BirthdatePicker!
    override func viewDidLoad() {
        dateFormatter.dateFormat = "MM/dd/yyyy"
        datePicker.setDate(NSCalendar.current.date(byAdding: .year, value: RemoteConfigManager.shared.app_in_review ? -20 : -16, to: Date())!, animated: false)
        self.birthDateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    @IBAction func changeBirthday(_ sender: UIDatePicker) {
        self.birthDateTextField.text = dateFormatter.string(from: sender.date)
    }
    var isConfirmed = false
    @IBAction func nextVC(_ sender: BigYellowButton) {
        guard isConfirmed else {
            isConfirmed = true
            let alertController = UIAlertController(title: "yo you can’t change this later so make sure its all good 💁", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "kk", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        sender.isEnabled = false
        self.nextButton.isLoading = true
        self.applyUpdates()
    }
    func applyUpdates() {
        APIController.shared.currentUser?.update(attributes: [
            .birth_date(self.datePicker.date as NSDate),
        ]) { (error: APIError?) in
            guard error == nil else {
                return self.present(error!.toAlert(onRetry: { (UIAlertAction) in
                    self.applyUpdates()
                }), animated: true, completion: nil)
            }
            if self.presentingViewController is IntroducingProfilesPopupViewController {
                self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            } else {
                self.presentingViewController?.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
