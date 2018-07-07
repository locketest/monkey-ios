//
//  SettingMainViewController.swift
//  Monkey
//
//  Created by fank on 2018/5/2.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  设置主页

import UIKit
import MessageUI
import SafariServices

enum SettingsCellStyle {
    case basic
    case profile
    case imageRight
    case buttonRight
    case textFieldRight
}

enum SettingsCellType {
    case editProfile
    case talkTo
    case acceptButton
    case nearbyButton
    case inviteFriends
    case safety
    case linkInstagram
    case signOut

    case firstName
    case birthday
    case snapchatName

    case cancelSave
}

/**
 * cell类型、cell文本、图片，头像或右边图片，其他，地区
 */
typealias DataTuple = (cellStyle: SettingsCellStyle, cellType: SettingsCellType,  text: String, image: String, other: String)

typealias DataTupleArray = [DataTuple]

//class SettingMainViewController: SwipeableViewController, MFMessageComposeViewControllerDelegate, InstagramAuthDelegate {
//
//    let FootView = UIView()
//
//    var dataArray : [DataTupleArray] = []
//
//    var linkInstagramIndexPath : IndexPath? // ins当前索引
//
//    var inviteFriendsViewController: MFMessageComposeViewController?
//
//    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
//
//    let SectionTitleArray = ["🐵 YOUR PROFILE", "🕹 MATCH CONTROL", "🤷‍♀️ STUFF"]
//
//    @IBOutlet weak var tableView: UITableView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.initView()
//
//        self.initData()
//    }
//
//    @IBAction func dismissBtnClickFunc(_ sender: UIButton) {
//        self.dismiss(animated: true, completion: nil)
//    }
//    
//    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
//        result: MessageComposeResult)
//    {
//        if result == .sent {
//            AnalyticsCenter.log(event: .inviteFriendSuccess)
//        }
//        self.dismiss(animated: true, completion: nil)
//    }
//
//    func addProfileDataFunc() {
//
//        var profileArray : DataTupleArray = []
//
//        let profileTextString = APIController.shared.currentUser?.first_name ?? ""
//
//        let photoPathString = APIController.shared.currentUser?.profile_photo_upload_url ?? ""
//
//        var localizedTimeString = ""
//        if let secondsInApp = APIController.shared.currentUser?.seconds_in_app.value {
//            if secondsInApp < 60 {
//                localizedTimeString = "1 min"
//            } else if secondsInApp < 3600 {
//                localizedTimeString = "\(secondsInApp / 60) min"
//            } else if secondsInApp < 7200 {
//                localizedTimeString = "1 hour"
//            } else {
//                localizedTimeString = "\(secondsInApp / 60 / 60) hours"
//            }
//        }
//
//        profileArray.append((.profile, cellType:.editProfile, text: profileTextString, image: photoPathString, other: localizedTimeString + " on Monkey"))
//
//        self.dataArray.append(profileArray)
//    }
//
//    func addMatchControlDataFunc() {
//
//        var matchControlArray : DataTupleArray = []
//
//        matchControlArray.append((.imageRight, cellType:.talkTo, text: "💬 Talk to", image: "", other: ""))
//        matchControlArray.append((.buttonRight, cellType:.acceptButton, text: "🤙 Auto accept matches", image: "", other: ""))
//        matchControlArray.append((.buttonRight, cellType:.nearbyButton, text: "🏡 Nearby", image: "", other: ""))
//
//        self.dataArray.append(matchControlArray)
//    }
//
//    func addStuffDataFunc() {
//
//        var stuffArray : DataTupleArray = []
//
//        let linstagramAccountState = APIController.shared.currentUser?.instagram_account
//
//        stuffArray.append((.basic, cellType:.inviteFriends, text: "🎉 Invite friends", image: "", other: ""))
//        stuffArray.append((.basic, cellType:.linkInstagram, text: linstagramAccountState == nil ? "📸 Link instagram" : "🌅 Unlink instagram", image: "", other: ""))
//        stuffArray.append((.basic, cellType:.safety, text: "🚑 Safety", image: "", other: ""))
//        stuffArray.append((.basic, cellType:.signOut, text: "🙈 Sign out", image: "", other: ""))
//
//        self.dataArray.append(stuffArray)
//    }
//
//    func authInstagramSuccess(code: String) {
//
//    }
//
//    func authInstagramFailure() {
//
//    }
//
//    func initInviteFriendsVcFunc() {
//
//        guard MFMessageComposeViewController.canSendText() else {
//            return
//        }
//        self.inviteFriendsViewController = MFMessageComposeViewController()
//        self.inviteFriendsViewController?.body = APIController.shared.currentExperiment?.sms_invite_friends
//        self.inviteFriendsViewController?.messageComposeDelegate = self
//    }
//
//    func initData() {
//
//        self.addProfileDataFunc()
//
//        self.addMatchControlDataFunc()
//
//        self.addStuffDataFunc()
//
//        self.tableView.reloadData()
//    }
//
//    func initView() {
//
//        self.initInviteFriendsVcFunc()
//
//        self.tableViewHeightConstraint.constant = ScreenHeight < 666 ? (ScreenHeight - 44) : 633
//    }
//}
//
//extension SettingMainViewController : UITableViewDelegate, UITableViewDataSource {
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return self.dataArray.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.dataArray[section].count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let dataTuple = self.dataArray[indexPath.section][indexPath.row]
//
//        switch dataTuple.cellStyle {
//        case .basic:
//
//            let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell") as! SettingBasicCell
//
//            cell.settingModel = SettingModel.settingModel(data: dataTuple)
//
//            return cell
//        case .profile:
//
//            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell") as! SettingProfileCell
//
//            cell.delegate = self
//            cell.viewController = self
//            cell.settingModel = SettingModel.settingModel(data: dataTuple)
//
//            return cell
//        case .imageRight:
//
//            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell") as! SettingImageCell
//
//            cell.settingModel = SettingModel.settingModel(data: dataTuple)
//
//            return cell
//        case .buttonRight:
//
//            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell") as! SettingButtonCell
//
//            cell.dataTuple = dataTuple
//
//            cell.settingModel = SettingModel.settingModel(data: dataTuple)
//
//            return cell
//        default:
//            return UITableViewCell()
//        }
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let dataTuple = self.dataArray[indexPath.section][indexPath.row]
//
//        switch dataTuple.cellType {
//        case .editProfile:
//            print("*** editProfile")
//            break
//        case .talkTo:
//            self.tolkToFunc(tableView: tableView, indexPath: indexPath)
//        case .acceptButton, .nearbyButton:
//            print("*** monkey button")
//            break
//        case .inviteFriends:
//            self.presentToInviteFriendsVcFunc()
//        case .safety:
//            self.safetyClickFunc()
//        case .linkInstagram:
//            self.linkInstgramFunc(tableView: tableView, indexPath: indexPath)
//        case .signOut:
//            self.signOutClickFunc()
//        default:
//            break
//        }
//    }
//
//    func safetyClickFunc() {
//
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alertController.addAction(UIKit.UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
//        }))
//        alertController.addAction(UIKit.UIAlertAction(title: "😐 Terms of Use", style: .default, handler: { (UIAlertAction) in
//            self.openURL("http://monkey.cool/terms", inVC: true)
//        }))
//        alertController.addAction(UIKit.UIAlertAction(title: "☹️ Privacy Policy", style: .default, handler: { (UIAlertAction) in
//            self.openURL("http://monkey.cool/privacy", inVC: true)
//        }))
//        alertController.addAction(UIKit.UIAlertAction(title: "😇 Safety Center", style: .default, handler: { (UIAlertAction) in
//            self.openURL("http://monkey.cool/safety", inVC: true)
//        }))
//        alertController.addAction(UIKit.UIAlertAction(title: "😁 Community Guidelines", style: .default, handler: { (UIAlertAction) in
//            self.openURL("http://monkey.cool/community", inVC: true)
//        }))
//        alertController.addAction(UIKit.UIAlertAction(title: "❌ Delete Account", style: .default, handler: { (UIAlertAction) in
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DeleteAccountPopupViewController") as! DeleteAccountPopupViewController
//            vc.modalPresentationStyle = .overFullScreen
//            self.present(vc, animated: true, completion: nil)
//        }))
//        if let creditsURL = APIController.shared.currentExperiment?.credits_url {
//            alertController.addAction(UIKit.UIAlertAction(title: "Credits", style: .default, handler: { (UIAlertAction) in
//                self.openURL(creditsURL, inVC: true)
//            }))
//        }
//        self.present(alertController, animated: true, completion: nil)
//    }
//
//    func openURL(_ urlString: String, inVC: Bool)
//    {
//        guard let url = URL(string: urlString) else {
//            return
//        }
//        if !inVC {
//            UIApplication.shared.openURL(url)
//            return
//        }
//        let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
//        vc.modalPresentationCapturesStatusBarAppearance = true
//        vc.modalPresentationStyle = .overFullScreen
//        present(vc, animated: true, completion: nil)
//    }
//
//    func tolkToFunc(tableView: UITableView, indexPath: IndexPath) {
//        if let cell = tableView.cellForRow(at: indexPath) as? SettingImageCell {
//            cell.cellTappedFunc()
//        }
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headView = Bundle.main.loadNibNamed("Setting", owner: self, options: nil)![0] as! SettingHeadView
//        headView.headTitleButton.setTitle(self.SectionTitleArray[section], for: .normal)
//        return headView
//    }
//
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        self.FootView.backgroundColor = UIColor.clear
//        return self.FootView
//    }
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return indexPath.section == 0 ? 83 : 64
//    }
//
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 30
//    }
//
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return section == 2 ? 1 : 5
//    }
//
//    func presentToInviteFriendsVcFunc() {
//
//        guard let inviteFriendsViewController = self.inviteFriendsViewController else {
//            return
//        }
//        self.present(inviteFriendsViewController, animated: true, completion: nil)
//    }
//
//    func linkInstgramFunc(tableView: UITableView, indexPath: IndexPath) {
//
//        self.linkInstagramIndexPath = indexPath // 用于ins授权后刷新cell里文本内容
//
//        let textLabel = (tableView.dequeueReusableCell(withIdentifier: "basicCell") as! SettingBasicCell).itemLabel!
//
//        if textLabel.text == "📸 Link instagram" {
//            guard let loginURL = APIController.shared.currentExperiment?.instagram_login_url else {
//                return
//            }
//
//            let insController = InstagramAuthViewController()
//            let authURL =  URL(string: loginURL)
//
//            insController.webURL = authURL
//            insController.authDelegate = self
//
//            let insNav = UINavigationController(rootViewController: insController)
//            insNav.modalPresentationStyle = .overFullScreen
//            self.present(insNav, animated: true, completion: nil)
//        } else {
//            guard let user = APIController.shared.currentUser else {
//                return
//            }
//
//            user.update(relationship:"instagram_account", resourceIdentifier:nil) { (error:APIError?) in
//                guard error == nil else {
//                    error?.log()
//                    return
//                }
//
//                textLabel.text = "🌅 Unlink instagram"
//
//                print("Instagram account unlinked & deleted")
//            }
//        }
//
//    }
//
//    func signOutClickFunc() {
//
//        let alertController = UIAlertController(title: "You sure you want to log out?", message: nil, preferredStyle: .actionSheet)
//
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//        alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
//            (UIAlertAction) in
//
//            AnalyticsCenter.log(event: .signOut)
//            RealmDataController.shared.deleteAllData() { (error) in
//                guard error == nil else {
//                    error?.log()
//                    return
//                }
//                APIController.authorization = nil
//                UserDefaults.standard.removeObject(forKey: "user_id")
////				Socket.shared.fetchCollection = false
//
//                let rootVC = self.view.window?.rootViewController
//                rootVC?.presentedViewController?.dismiss(animated: false, completion: {
//                    DispatchQueue.main.async {
//                        rootVC?.dismiss(animated: true, completion: nil)
//                    }
//                })
//            }
//        }))
//
//        self.present(alertController, animated: true, completion: nil)
//    }
//
//}
//
///**
// * cell代理相关
// */
//extension SettingMainViewController : SettingProfileCellDelegate {
//
//    func uploadedProfileImageSuccessFunc() {
//    }
//
//    func editProfileBtnClickFunc() {
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingEditViewController") as! SettingEditViewController
//        vc.uploadImgClosure = {
//            self.dataArray[0][0].image = (APIController.shared.currentUser?.profile_photo_upload_url)!
//            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//        }
//        self.swipableViewControllerPresentFromRight = vc
//        self.present(vc, animated: true)
//    }
//
//}
//
///**
// * instagram回调
// */
//extension SettingMainViewController {
//
//    func instagramNotificationReceived(_ notification:Notification) {
//        guard let loginParameters = notification.object as? [String:Any] else {
//            print("Error: notification posted without an object")
//            return
//        }
//        guard loginParameters["error_reason"] as? String != "user_denied" else {
//            return // Web view will be dismissed.
//        }
//        guard let code = loginParameters["code"] as? String else {
//            let errorMessage = loginParameters["error_description"] as? String
//            let instagramFailedAlert = UIAlertController(title: "😬 Couldn't link Instagram", message: errorMessage?.replacingOccurrences(of: "+", with: " ") ?? "Try again", preferredStyle: .alert)
//            instagramFailedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(instagramFailedAlert, animated: true)
//            return
//        }
//
//        self.linkInstagramToUser(code)
//    }
//
//    func linkInstagramToUser(_ code:String) {
//
//        let parameters:[String:Any] = [
//            "data": [
//                "type": "instagram_accounts",
//                "attributes": ["code":code],
//            ]
//        ]
//
//		RealmInstagramAccount.create(method: .post, parameters: parameters) { [weak self] (result: JSONAPIResult<RealmInstagramAccount>) in
//            switch result {
//            case .success(_):
//
//                if let instagramIndexPath = self?.linkInstagramIndexPath {
//                    // 该更新user里的link状态再取link状态？
//                    self?.dataArray[2][1].text = "📸 Link instagram"
//                    self?.tableView.reloadRows(at: [instagramIndexPath], with: .automatic)
//                }
//                break
//            case .error(let error):
//                error.log()
//                let instagramFailedAlert = UIAlertController(title: "😬 Error linking Instagram", message: "Please try again", preferredStyle: .alert)
//                instagramFailedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                self?.present(instagramFailedAlert, animated: true)
//            }
//        }
//    }
//}
