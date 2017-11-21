//
//  InviteFriendsViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/19/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import Contacts
import Amplitude_iOS
import MessageUI

class InviteFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MFMessageComposeViewControllerDelegate {
    @IBOutlet var nextButton: BigYellowButton!
    @IBOutlet var searchInput: UITextField!
    @IBOutlet var containerView: UIView!
    @IBOutlet var searchBar: UIView!
    @IBOutlet var contactsTableView: UITableView!
    var invites = [Dictionary<String, Any>]()
    var contacts = Array<CNContact>()
    var allContacts = Array<CNContact>()
    let formatter = CNContactFormatter()
    @IBOutlet var promptLabel: UILabel!
    let transitionTime = 1.3
    let transitionDelay = 0.2
    let store = CNContactStore()

    override func viewDidLoad() {
        if APIController.sharedInstance.currentExperiment?.invite_next_button_required.value == true {
            self.nextButton.isEnabled = false
        }
        if APIController.sharedInstance.currentExperiment?.invite_next_button_transparent.value == true {
            self.nextButton.layer.opacity = 0.5
        }
        self.containerView.layer.opacity = 0.0
        if let gender = APIController.sharedInstance.currentUser!.gender {
            if gender == "male" {
                self.promptLabel.text = APIController.sharedInstance.currentExperiment?.male_invite_text
            } else {
                self.promptLabel.text = APIController.sharedInstance.currentExperiment?.female_invite_text
            }
        }
        
        self.promptLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15.0, weight: UIFontWeightBold)
        formatter.style = .fullName
        self.searchBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(startSearching)))
        loadContacts()

    }
    func shouldShowVC() -> Bool {
        if Achievements.shared.invitedFriends {
            return false
        }
        if Achievements.shared.finishedOnboarding {
            return false
        }
        
        // Not possible until realm/realm-cocoa#1120 is closed
        if true { // !(APIController.sharedInstance.currentExperiment?.invite_friends?.contains(Locale.current.identifier) ?? false) {
            return false
        }
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return true
        default:
            return false
        }
    }
    func loadContacts() {
        
        // get the contacts
        
        let request = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor, CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey as CNKeyDescriptor])
        do {
            var regularContacts = Array<CNContact>()
            try store.enumerateContacts(with: request) { contact, stop in
                if let contactName = self.formatter.string(from: contact) {
                    if contact.phoneNumbers.count == 0 {
                        return
                    }
                    if contactName.containsEmoji {
                        self.allContacts.append(contact)
                        if APIController.sharedInstance.currentExperiment?.ec.value == true {
                            self.ic(contact: contact, cell: false)
                        }
                    } else {
                        regularContacts.append(contact)
                    }
                }
            }
            allContacts.append(contentsOf: regularContacts)
            contacts = allContacts
            if contacts.count < 10 {
               nextVC(animated: false)
            }
        } catch {
            print(error)
            nextVC(animated: false)
            return
        }
    }
    
    @IBAction func textDidChange(_ sender: UITextField) {
        let text = sender.text!.lowercased()
        contacts = allContacts.filter({ (contact) -> Bool in
            return contact.givenName.lowercased().hasPrefix(text) || contact.familyName.lowercased().hasPrefix(text)
        })
        self.contactsTableView.reloadData()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    @IBAction func viewDetails(_ sender: UIButton) {
        let alert = UIAlertController(title: "Add Friends Details", message: APIController.sharedInstance.currentExperiment?.add_friends_details, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sweet!", style: .cancel, handler: {
            (UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Edit Message", style: .default, handler: {
            (UIAlertAction) in
            sender.isEnabled = false

            Amplitude.instance().logEvent("Edited Invite Text Message From Disclaimer")
            if MFMessageComposeViewController.canSendText()
            {
                let controller = MFMessageComposeViewController()
                controller.body = APIController.sharedInstance.currentExperiment?.sms_invite_text
                //controller.recipients =
                controller.messageComposeDelegate = self
                self.present(controller, animated: true, completion: nil)
            }
            else {
                self.nextVC(animated: true)
            }
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func nextVC(animated: Bool) {
        if self.invites.count > 0 {
            Amplitude.instance().logEvent("Friend Invite Page Completed", withEventProperties: [
                "selected": self.manuallyInvitedCount,
                "invited": invites.count,
                ])
        }
        if let warningVC = self.storyboard?.instantiateViewController(withIdentifier: "permVC") {
            if !animated {
                self.present(warningVC, animated: false, completion: nil)
                return
            }
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,//0.6,
                options: .allowUserInteraction,
                animations: {
                    self.containerView.frame.origin.x = -self.containerView.frame.size.width;
                    self.containerView.layer.opacity = 0;
            }) { (Bool) in
                //warningVC.invites = self.invites
                self.present(warningVC, animated: false, completion: nil)
            }
        }
        
    }
    
    @IBAction func next(_ sender: UIButton) {
        self.nextVC(animated: true)
    }
    func startSearching() {
        searchInput.becomeFirstResponder()
    }
    override func viewWillAppear(_ animated: Bool) {
        //self.searchBar.clipsToBounds = true
        UIView.animate(
            withDuration: transitionTime,
            delay: transitionDelay,
            usingSpringWithDamping: CGFloat(0.6),
            initialSpringVelocity: CGFloat(1.5),
            options: UIViewAnimationOptions.allowUserInteraction,
            animations: {
                self.containerView.layer.opacity = 1;
            },
            completion: { (Bool) -> Void in
                
        })
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    override func viewDidLayoutSubviews() {
        self.searchBar.layer.cornerRadius = self.searchBar.frame.size.height / 2
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchInput.resignFirstResponder()
    }
    func ic(contact: CNContact, cell: Bool) {
        let selectedPhoneNumber = getPhone(forContact: contact)
        if (selectedPhoneNumber != nil) {
            invites.append([
                "name": formatter.string(from: contact)!,
                "phone_number": selectedPhoneNumber!,
                "cell": cell
                ])
        }
    }
    func getPhone(forContact contact: CNContact) -> String? {
        var selectedPhoneNumber:String?
        for phoneNumber in contact.phoneNumbers {
            if phoneNumber.label == "_$!<Mobile>!$_" || phoneNumber.label == nil {
                selectedPhoneNumber = phoneNumber.value.stringValue
            }
        }
        return selectedPhoneNumber
    }
    var manuallyInvitedCount = 0
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manuallyInvitedCount += 1
        self.searchInput.resignFirstResponder()
        let contact = contacts[indexPath.row]
        contacts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        ic(contact: contact, cell: true)
        if manuallyInvitedCount == 1 {
            self.promptLabel.text = "1/3 FRIENDS ADDED ON MONKEY"
        } else if manuallyInvitedCount == 2 {
            self.promptLabel.text = "2/3 FRIENDS ADDED ON MONKEY"
        } else {
            self.nextButton.isEnabled = true
            self.nextButton.layer.opacity = 1.0
            self.promptLabel.text = "\(manuallyInvitedCount) FRIENDS ADDED ON MONKEY"
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell") as? InviteFriendsTableViewCell {
            let contact = contacts[indexPath.row]
            cell.nameLabel.text = formatter.string(from: contact)
            let rand = randomNumber(probabilities: [40, 15, 15, 10, 6, 5, 4, 3, 2, 2, 1, 1]) + 1
            let phoneNumber = getPhone(forContact: contact)
            var phoneString = ""
            if let phoneNumberString = phoneNumber {
                phoneString = " • \(phoneNumberString)"
            }
            if rand == 1 {
                cell.friendCountLabel.text = "1 friend on Monkey\(phoneString)"
            } else {
                cell.friendCountLabel.text = "\(rand) friends on Monkey\(phoneString)"
            }
            return cell
        }
        return UITableViewCell()
    }
    func randomNumber(probabilities: [Double]) -> Int {
        
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum :
        let rnd = sum * Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
        // Find the first interval of accumulated probabilities into which `rnd` falls:
        var accum = 0.0
        for (i, p) in probabilities.enumerated() {
            accum += p
            if rnd < accum {
                return i
            }
        }
        // This point might be reached due to floating point inaccuracies:
        return (probabilities.count - 1)
    }
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
        result: MessageComposeResult)
    {
        self.dismiss(animated: true, completion: {
            self.nextVC(animated: true)
        })
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

class InviteFriendsTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var friendCountLabel: UILabel!
}

extension String {
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1f997, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF,   // Dingbats
            0xFE00...0xFE0F:   // Variation Selectors
                return true
            default:
                continue
            }
        }
        return false
    }
}
/*
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (unshuffledCount, firstUnshuffled) in zip(stride(from: c, to: 1, by: -1), indices) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}*/
