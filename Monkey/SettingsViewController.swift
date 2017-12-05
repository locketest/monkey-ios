//
//  SettingsViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 1/9/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Alamofire
import Amplitude_iOS
import SafariServices
import MessageUI
import SafariServices

class SettingsViewController: SwipeableViewController, UITableViewDelegate, SettingsBooleanTableViewCellDelegate, SettingsHashtagCellDelegate, MFMessageComposeViewControllerDelegate, UITableViewDataSource, ProfilePhotoButtonViewDelegate {

    @IBOutlet var containerView: MakeUIViewGreatAgain!

    @IBOutlet weak var timeOnMonkey: UILabel!
    @IBOutlet weak var firstName: UILabel!

    @IBOutlet weak var profilePhoto: ProfilePhotoButtonView!

    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleButton: UIButton!

    @IBOutlet weak var profileView:UIView!

    @IBOutlet weak var dismissTapGestureRecognizer:UITapGestureRecognizer!

    var inviteFriendsViewController: MFMessageComposeViewController?

    /// A reference to the presented instagramVC. Currently used to forward longPressGestureRecognizer updates
    weak var instagramViewController: InstagramPopupViewController?
    /// The long press gesture responsible for presenting the instagram popover
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    /// The location of the user's finger when instagram popup is presented, used to calculate displacement to pass to instagramVC if they do not lift finger to pan
    var initialLongPressLocation: CGPoint?
    /// The previous location of the user's finger, used to calculate velocity to pass to instagramVC if they do not lift finger to pan
    var previousLongPressLocation: CGPoint?

    /// Returns the content size of the view, is a getter because TODO: replace with actual calculation of content within view
    override var contentHeight:CGFloat {
        return 500
    }

    var lastY: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.bounces = true
        self.setupInviteFriendsViewController()

        self.profilePhoto.delegate = self
        profilePhoto.presentingViewController = self
        profilePhoto.lightPlaceholderTheme = true

        NotificationCenter.default.addObserver(self, selector: #selector(instagramNotificationReceived(_:)), name: .instagramLoginNotification, object: nil)

        if let firstName = APIController.shared.currentUser?.first_name {
            self.firstName.text = firstName
        }

        if let secondsInApp = APIController.shared.currentUser?.seconds_in_app.value {
            var localizedTime = ""
            if secondsInApp < 60 {
                localizedTime = "1 min"
            } else if secondsInApp < 3600 {
                localizedTime = "\(secondsInApp / 60) min"
            } else if secondsInApp < 7200 {
                localizedTime = "1 hour"
            } else {
                localizedTime = "\(secondsInApp / 60 / 60) hours"
            }
            timeOnMonkey.text = localizedTime + " on Monkey"
        }

        switch Gender(rawValue: APIController.shared.currentUser?.show_gender ?? "") {
        case .male?:
            self.genderPreferenceButton.setImage(#imageLiteral(resourceName: "Guys"), for: .normal)
        case .female?:
            self.genderPreferenceButton.setImage(#imageLiteral(resourceName: "Girls"), for: .normal)
        default:
            self.genderPreferenceButton.setImage(#imageLiteral(resourceName: "GenderPreferenceButton"), for: .normal)
        }
    }

    internal func showAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }

    @IBOutlet weak var genderPreferenceButton: UIButton!
    func selectedHashtag(id: String, tag: String) {
        fatalError("Not implemented")
    }

    func profilePhotoButtonView(_ profilePhotoButtonView: ProfilePhotoButtonView, selectedImage: UIImage) {
        self.profilePhoto.profileImage = selectedImage
        self.profilePhoto.uploadProfileImage {
            print("Uploaded profile image")
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // false so that swiping to side during longPress does not try to dismiss friendsVC (to go to mainVC) while instagramVC is presented
        if gestureRecognizer == self.panGestureRecognizer && gestureRecognizer != self.longPressGestureRecognizer  {
            return false
        }

        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }

    func instagramNotificationReceived(_ notification:Notification) {
        guard let loginParameters = notification.object as? [String:Any] else {
            print("Error: notification posted without an object")
            return
        }
        guard loginParameters["error_reason"] as? String != "user_denied" else {
            return // Web view will be dismissed.
        }
        guard let code = loginParameters["code"] as? String else {
            let errorMessage = loginParameters["error_description"] as? String
            let instagramFailedAlert = UIAlertController(title: "😬 Couldn't link Instagram", message: errorMessage?.replacingOccurrences(of: "+", with: " ") ?? "Try again", preferredStyle: .alert)
            instagramFailedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(instagramFailedAlert, animated: true)
            return
        }

        self.linkInstagramToUser(code)
    }

    func linkInstagramToUser(_ code:String) {

        let parameters:[String:Any] = [
            "data": [
                "type": "instagram_accounts",
                "attributes": ["code":code],
                ]
        ]

        RealmInstagramAccount.create(parameters: parameters) { [weak self] (result: JSONAPIResult<[RealmInstagramAccount]>) in
            switch result {
            case .success(_):
                break
            case .error(let error):
                error.log()
                let instagramFailedAlert = UIAlertController(title: "😬 Error linking Instagram", message: "Please try again", preferredStyle: .alert)
                instagramFailedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self?.present(instagramFailedAlert, animated: true)
            }
        }
    }

    @IBAction func genderPreferenceTapped(_ sender: Any) {

        let alertController = UIAlertController(title: "Talk to", message: APIController.shared.currentExperiment?.talk_to_alert_message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alertController.addAction(UIAlertAction(title: "👫 Both", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender(nil)], completion: { $0?.log() })

            self.genderPreferenceButton.setImage(#imageLiteral(resourceName: "GenderPreferenceButton"), for: .normal)
        }))

        alertController.addAction(UIAlertAction(title: "👱 Guys", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("male")], completion: { $0?.log() })

            self.genderPreferenceButton.setImage(#imageLiteral(resourceName: "Guys"), for: .normal)
        }))

        alertController.addAction(UIAlertAction(title: "👱‍♀️ Girls", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("female")], completion: { $0?.log() })

            self.genderPreferenceButton.setImage(#imageLiteral(resourceName: "Girls"), for: .normal)
        }))

        self.present(alertController, animated: true, completion: nil)
    }

    func saveGenderPreference(gender : String?) {

    }

    @IBAction func presentInstagramController(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let locationPoint = longPressGestureRecognizer.location(in: self.longPressGestureRecognizer.view)

        switch longPressGestureRecognizer.state {
        case .began:

            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil

            guard let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as? InstagramPopupViewController else {
                return
            }
            instagramVC.userId = APIController.shared.currentUser?.user_id
            self.present(instagramVC, animated: true, completion: {
                self.initialLongPressLocation = locationPoint
                self.previousLongPressLocation = locationPoint
            })

            self.instagramViewController = instagramVC

        case .changed:
            guard let instagramVC = self.instagramViewController else {
                print("Error: can not forward touches to instagramVC since reference is invalid")
                return
            }
            guard let initialLocation = self.initialLongPressLocation else {
                print("Error: can not calculate displacement since no initialLongPressLocation")
                return
            }
            guard let previousLocation = self.previousLongPressLocation else {
                print("Error: can not caluclate velocity since no previousLongPressLocation")
                return
            }

            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y

            instagramVC.adjustInstagramConstraints(displacement, velocity)

            self.previousLongPressLocation = locationPoint
        case .cancelled, .ended:
            guard let instagramVC = self.instagramViewController else {
                print("Error: can not forward touches to instagramVC since reference is invalid (.ended)")
                return
            }
            guard let initialLocation = self.initialLongPressLocation else {
                print("Error: can not calculate displacement since no initialLongPressLocation (.ended)")
                return
            }
            guard let previousLocation = self.previousLongPressLocation else {
                print("Error: can not caluclate velocity since no previousLongPressLocation (.ended)")
                return
            }
            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y

            instagramVC.adjustInstagramConstraints(displacement, velocity, isEnding: true)

            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil
            self.instagramViewController = nil // no longer need a reference to it
        default:
            break
        }
    }

    @IBAction func editProfileTapped(_ sender: Any) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "🐵 Change profile picture", style: .default, handler: { [weak self] (UIAlertAction) in
            self?.profilePhoto.setProfilePhoto()
        }))        

        if APIController.shared.currentUser?.instagram_account != nil { // remove instagram account
            alertController.addAction(UIAlertAction(title: "🌅 Unlink Instagram", style: .destructive, handler: { [weak self] (UIAlertAction) in
                self?.unlinkInstagram()
                Amplitude.shared.logEvent("Unlinked Instagram")

            }))
        } else { // add instagram account
            alertController.addAction(UIAlertAction(title: "🌅 Link Instagram", style: .default, handler: { [weak self] (UIAlertAction) in
                self?.linkInstagram()
                Amplitude.shared.logEvent("Linked Instagram")

            }))
        }



        if let urlToOpen = APIController.shared.currentExperiment?.edit_account_request_url {
            alertController.addAction(UIAlertAction(title: "🤷‍♀️ Change something else", style: .default, handler: { (UIAlertAction) in
                let vc = SFSafariViewController(url: URL(string: urlToOpen)!, entersReaderIfAvailable: false)
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true, completion: nil)
            }))
        }

        self.present(alertController, animated: true, completion: nil)
    }

    func linkInstagram() {
        guard let loginUrl = APIController.shared.currentExperiment?.instagram_login_url else {
            return
        }

        let instagramWebViewController = SFSafariViewController(url: URL(string:loginUrl)!, entersReaderIfAvailable: false)
        instagramWebViewController.modalPresentationStyle = .overFullScreen
        instagramWebViewController.delegate = self
        self.present(instagramWebViewController, animated: true, completion: nil)
    }

    func unlinkInstagram() {
        guard let user = APIController.shared.currentUser else {
            return
        }

        user.update(relationship:"instagram_account", resourceIdentifier:nil) { (error:APIError?) in
            guard error == nil else {
                error?.log()
                return
            }

            print("Instagram account unlinked & deleted")
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
        result: MessageComposeResult)
    {
        self.dismiss(animated: true, completion: {
            self.setupInviteFriendsViewController()
        })
    }
    func setupInviteFriendsViewController() {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        self.inviteFriendsViewController = MFMessageComposeViewController()
        self.inviteFriendsViewController?.body = APIController.shared.currentExperiment?.sms_invite_friends
        self.inviteFriendsViewController?.messageComposeDelegate = self
    }

    override func viewDidLayoutSubviews() {
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        // Code below will make height correct
        // 100 is height of other content besides table view content we need to account for
        if self.tableView.contentSize.height > UIScreen.main.bounds.height - 100 {
            // On small devices, we want to fill the screen with the table view
            self.view.addConstraints([
                NSLayoutConstraint(item: self.containerView,
                                   attribute: .top, relatedBy: .equal,
                                   toItem: self.view, attribute: .top,
                                   multiplier: 1, constant: 22),
                ])
         } else {
            let settingsHeight = self.tableView.contentSize.height + 34
            self.view.addConstraints([
                NSLayoutConstraint(item: self.containerView,
                                   attribute: .height, relatedBy: .equal,
                                   toItem: nil, attribute: .notAnAttribute,
                                   multiplier: 1, constant: settingsHeight),
                ])
        }
        super.viewDidLayoutSubviews()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell else {
            return
        }
        guard let data = cell.data else {
            return
        }
        switch data.type {
        case .followUs:
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "👻 Snapchat", style: .default, handler: { (UIAlertAction) in
                if (UIApplication.shared.canOpenURL(URL(string:"snapchat://")!)) {
                    UIApplication.shared.openURL(URL(string: "snapchat://add/monkeyapp")!)
                } else {
                    UIApplication.shared.openURL(URL(string: "http://snapchat.com/add/monkeyapp")!)
                }
            }))
            alertController.addAction(UIAlertAction(title: "🐦 Twitter", style: .default, handler: { (UIAlertAction) in
                if (UIApplication.shared.canOpenURL(URL(string:"twitter://")!)) {
                    UIApplication.shared.openURL(URL(string: "twitter://user?screen_name=monkey")!)
                } else {
                    self.openURL("http://twitter.com/monkey", inVC: true)
                }
            }))
            alertController.addAction(UIAlertAction(title: "📸 Instagram", style: .default, handler: { (UIAlertAction) in
                if (UIApplication.shared.canOpenURL(URL(string:"instagram://")!)) {
                    UIApplication.shared.openURL(URL(string: "instagram://user?username=chatonmonkey")!)
                } else {
                    self.openURL("http://instagram/chatonmonkey", inVC: true)
                }
            }))
            self.present(alertController, animated: true, completion: nil)
        case .safety:
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            }))
            alertController.addAction(UIAlertAction(title: "😐 Terms of Use", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/terms", inVC: true)
            }))
            alertController.addAction(UIAlertAction(title: "☹️ Privacy Policy", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/privacy", inVC: true)
            }))
            alertController.addAction(UIAlertAction(title: "😇 Safety Center", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/safety", inVC: true)
            }))
            alertController.addAction(UIAlertAction(title: "😁 Community Guidelines", style: .default, handler: { (UIAlertAction) in
                self.openURL("http://monkey.cool/community", inVC: true)
            }))
            if let creditsURL = APIController.shared.currentExperiment?.credits_url {
                alertController.addAction(UIAlertAction(title: "Credits", style: .default, handler: { (UIAlertAction) in
                    self.openURL(creditsURL, inVC: true)
                }))
			}
            self.present(alertController, animated: true, completion: nil)
        case .rateUs:
            self.openURL("https://itunes.apple.com/us/app/id1165924249?action=write-review", inVC: false)
        case .signOut:
            RealmDataController.shared.deleteAllData() { (error) in
                guard error == nil else {
                    error?.log()
                    return
                }
                APIController.authorization = nil
                UserDefaults.standard.removeObject(forKey: "user_id")
                Apns.update(callback: nil)


                let rootVC = self.view.window?.rootViewController
                rootVC?.presentedViewController?.dismiss(animated: false, completion: {
                    DispatchQueue.main.async {
                        rootVC?.dismiss(animated: true, completion: nil)
                    }
                })
            }
        case .editProfile:
            // Edit profile has been combined with editAccount, the information is all on one page
            // The logic actually hasnt been rewritten, however, since currently we do not allow for the user to edit these values (this is legacy code)
            break
        case .inviteFriends:
            Amplitude.shared.logEvent("Invited Friends Manually")
            guard let inviteFriendsViewController = self.inviteFriendsViewController else {
                return
            }
            self.present(inviteFriendsViewController, animated: true, completion: nil)
        }
    }

    func openURL(_ urlString: String, inVC: Bool)
    {
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


    internal func buttonStatesChanged(settingsTableViewCell: SettingsBooleanTableViewCell) {
        if settingsTableViewCell.data?.firstOption?.isSelected == true {
            UserDefaults.standard.set("female", forKey: "show_gender")
        } else if settingsTableViewCell.data?.firstOption?.isSelected == true {
            UserDefaults.standard.set("male", forKey: "show_gender")
        }
    }
    var secretButtonTimer:Timer?
    func showSecret() {
        // Ben told me to get
        //self.hideSettingsView()
        //self.present(self.storyboard!.instantiateViewController(withIdentifier: "secretsVC"), animated: true, completion: nil)
    }
    @IBAction func secretsButtonStartHolding(_ sender: UIButton) {
        self.secretButtonTimer = Timer.scheduledTimer(timeInterval: 2,
                                                      target: self,
                                                      selector: #selector(self.showSecret),
                                                      userInfo: nil,
                                                      repeats: false)
    }
    @IBAction func secretsButtonStopHolding(_ sender: UIButton) {
        self.secretButtonTimer?.invalidate()
    }

    let inviteFriendsData = SettingsTableViewCellData(for: .inviteFriends, title: "🎉  Invite friends")
    let rateOnAppStoreData = SettingsTableViewCellData(for: .rateUs, title: "💖  Rate us")
    let addOnSnapchatData = SettingsTableViewCellData(for: .followUs, title: "📲  Follow us")
    let legalStuffData = SettingsTableViewCellData(for: .safety, title: "🚑  Safety")
    let signOutData = SettingsTableViewCellData(for: .signOut, title: "🙈  Sign out")
    var cells: [SettingsTableViewCellData] {
        return [
            inviteFriendsData,
            rateOnAppStoreData,
            addOnSnapchatData,
            legalStuffData,
            signOutData]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = cells[indexPath.row]
        switch data.style {
        case .basic:
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath) as! SettingsBasicTableViewCell
            cell.titleLabel?.text = data.title
            cell.data = data
            return cell
        case .booleanButtons:
            let cell = tableView.dequeueReusableCell(withIdentifier: "booleanCell", for: indexPath) as! SettingsBooleanTableViewCell
            cell.titleLabel?.text = data.title
            cell.data = data
            cell.delegate = self
            return cell
        case .textField:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! SettingsTextFieldTableViewCell

            cell.hashtagField.delegate = cell
            cell.hashtagField.text = data.text
            if let placeholderText = data.placeholderText {
                cell.hashtagField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: Colors.white(0.5), NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)])
            }
            cell.titleLabel?.text = data.title
            cell.data = data
            cell.delegate = self
            return cell
        }
    }

    /// Dismiss settings view controller if tapped in empty area
    @IBAction func dismissTapped(sender:UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }

        let location = sender.location(in: self.view)
        let remainingSpace = self.view.bounds.height - self.contentHeight

        if location.y < remainingSpace {
            self.panningTowardsSide = .top
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension SettingsViewController: SFSafariViewControllerDelegate {

}

enum SettingsTableViewCellStyle {
    case basic
    case booleanButtons
    case textField
}
struct SettingsTableViewCellData {
    var title: String
    var style: SettingsTableViewCellStyle
    var type: SettingsTableViewCellType
    var firstOption: SettingsTableViewCellOption?
    var secondOption: SettingsTableViewCellOption?
    var text: String?
    var placeholderText: String?
    var isEditing = false

    init(for type: SettingsTableViewCellType, title: String) {
        self.type = type
        self.title = title
        self.style = .basic
    }

    init(for type: SettingsTableViewCellType, title: String, text: String, placeholderText: String) {
        self.type = type
        self.title = title
        self.style = .textField
        self.text = text
        self.placeholderText = placeholderText
    }
    init(for type: SettingsTableViewCellType, title: String, firstOption: SettingsTableViewCellOption, secondOption: SettingsTableViewCellOption) {
        self.type = type
        self.title = title
        self.style = .booleanButtons
        // custom to this type
        self.firstOption = firstOption
        self.secondOption = secondOption
    }
    mutating func set(text: String?) {
        self.text = text
    }
    mutating func setFirstOption(isSelected: Bool) {
        self.firstOption?.isSelected = isSelected
    }
    mutating func setSecondOption(isSelected: Bool) {
        self.secondOption?.isSelected = isSelected
    }
}
class SettingsTableViewCellOption {
    let emoji: String
    let title: String
    var isSelected = false
    init(title: String, emoji: String, isSelected: Bool) {
        self.emoji = emoji
        self.title = title
        self.isSelected = isSelected
    }
}
enum SettingsTableViewCellType {
    case rateUs
    case followUs
    case safety
    case signOut
    case editProfile
    case inviteFriends
}

class SettingsTableViewCell: UITableViewCell {
    var data: SettingsTableViewCellData?
    @IBOutlet var titleLabel: UILabel!
}

class SettingsBasicTableViewCell: SettingsTableViewCell {
}

class BooleanButton: BigYellowButton {
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.backgroundColor = UIColor(red: 107.0 / 255.0, green: 68.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)

            } else {
                self.backgroundColor = UIColor(red: 35.0 / 255.0, green: 35.0 / 255.0, blue: 35.0 / 255.0, alpha: 1.0)
            }
        }
    }
}

class SettingsBooleanTableViewCell: SettingsTableViewCell {
    weak var delegate:SettingsBooleanTableViewCellDelegate?
    override var data: SettingsTableViewCellData? {
        didSet {
            self.firstOptionButton.isSelected = self.data?.firstOption?.isSelected ?? false
            self.secondOptionButton.isSelected = self.data?.secondOption?.isSelected ?? false
        }
    }
    @IBOutlet private var firstOptionButton: BooleanButton!
    @IBOutlet private var secondOptionButton: BooleanButton!
    @IBAction func firstOptionSelected() {
        self.data?.setFirstOption(isSelected: true)
        self.data?.setSecondOption(isSelected: false)
        self.delegate?.buttonStatesChanged(settingsTableViewCell: self)
    }
    @IBAction func secondOptionSelected() {
        self.data?.setFirstOption(isSelected: false)
        self.data?.setSecondOption(isSelected: true)
        self.delegate?.buttonStatesChanged(settingsTableViewCell: self)
    }
    func invertButtonStyles() {
        let secondOptionButtonBackgroundColor = self.secondOptionButton.backgroundColor
        self.secondOptionButton.backgroundColor = self.firstOptionButton.backgroundColor
        self.firstOptionButton.backgroundColor = secondOptionButtonBackgroundColor
    }
}

protocol SettingsBooleanTableViewCellDelegate: class {
    func buttonStatesChanged(settingsTableViewCell: SettingsBooleanTableViewCell)
}

protocol SettingsHashtagCellDelegate: class {
    func selectedHashtag(id: String, tag: String)
    func showAlert(alert: UIAlertController)

}
