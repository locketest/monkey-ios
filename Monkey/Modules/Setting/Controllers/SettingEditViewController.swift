//
//  SettingEditViewController.swift
//  Monkey
//
//  Created by fank on 2018/5/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  设置编辑页

import UIKit
import ObjectMapper

typealias UploadImgClosure = () -> Void

class SettingEditViewController: SwipeableViewController, UITextFieldDelegate {
    
    let DurationTime = 0.25
    
    var uploadImgClosure: UploadImgClosure?
    
    let SaveButtonAlpha : CGFloat = 0.25
    
    var datePicker: BirthdatePicker!
    
    var dataArray : [DataTupleArray] = []
    
    let SectionTitleArray = ["🐵 YOUR PROFILE", "✏️ PROFILE EDITING"]
    
    var editInitialValueTuple = (firstName:"", birthadyString:"", snapchatString:"")
    
    @IBOutlet weak var nameTipsLabel: UILabel!
    
    @IBOutlet weak var birthdayTipsLabel: UILabel!
    
    @IBOutlet weak var snapchatTipsLabel: UILabel!
    
    @IBOutlet weak var nameTextField: UsernameTextField!
    
    @IBOutlet weak var birthdayTextField: UsernameTextField!
    
    @IBOutlet weak var snapchatTextField: UsernameTextField!
    
    @IBOutlet weak var cancelButton: BigYellowButton!
    
    @IBOutlet weak var saveButton: BigYellowButton!
    
    @IBOutlet weak var editBgView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
        
        self.initData()
    }
    
    var isValidBool : Bool {
        return self.snapchatTextField.isValid && self.nameTextField.charactersCount > 2
    }
    
    @IBAction func saveBtnClickFunc(_ sender: BigYellowButton) {
        
        guard let currentUser = APIController.shared.currentUser else {
            return
        }
        
        let alpha : Bool = self.saveButton.alpha == 1.0
        
        guard alpha else {
            self.handleCancelStateFunc()
            return
        }
        
        var attributes: [RealmUser.Attribute] = []
        
        if let newNameString = self.nameTextField.text, newNameString != currentUser.first_name {
            attributes.append(.first_name(newNameString))
        }
        
        if let newBirthdayString = self.birthdayTextField.text {
            if let oldBirthday = currentUser.birth_date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                let oldBirthdayDate = Date.init(timeIntervalSince1970: oldBirthday.timeIntervalSince1970)
                let oldBirthdayString = dateFormatter.string(from: oldBirthdayDate)
                if (newBirthdayString != oldBirthdayString) {
                    attributes.append(.birth_date(self.datePicker.date as NSDate))
                }
            }
        }
        
        if let newSnapchatName = self.snapchatTextField.text, newSnapchatName != currentUser.snapchat_username {
            attributes.append(.snapchat_username(newSnapchatName))
        }
        
        if attributes.count > 0 {
            self.saveButton.isLoading = true
            
            currentUser.update(attributes: attributes) { (error) in
                
                self.saveButton.isLoading = false
                
                guard error == nil else {
                    if error?.status == "400" {
                        return self.present(error!.toAlert(onOK: { (UIAlertAction) in
                        }), animated: true, completion: nil)
                    }
                    
                    self.present(error!.toAlert(onRetry: { (UIAlertAction) in
                        self.saveBtnClickFunc(sender)
                    }), animated: true, completion: nil)
                    return
                }
                
                // 保存成功
                var userProperty = [String: Any]()
                currentUser.first_name.then {
                    userProperty["first_name"] = $0
                }
                
                currentUser.snapchat_username.then {
                    userProperty["snapchat_username"] = $0
                }
                
                currentUser.birth_date.then {
                    userProperty["birth_date"] = $0
                }
                
                self.initData()
                
                self.handleCancelStateFunc()
                
                AnalyticsCenter.update(userProperty: userProperty)
            }
        } else {
            self.handleCancelStateFunc()
        }
        
        self.handleEditBgViewHiddenStateFunc(isHidden: true)
    }
    
    @IBAction func cancelBtnClickFunc(_ sender: BigYellowButton) {
        self.handleEditBgViewHiddenStateFunc(isHidden: true)
        self.handleCancelStateFunc()
    }

    @IBAction func dismissBtnClickFunc(_ sender: UIButton) {
        self.dismissViewControllerFunc()
    }
    
    func handleCancelStateFunc() {
        
//        if self.nameTextField.isUserInteractionEnabled {
//            self.nameTipsLabel.text = ""
//        }
//
//        self.birthdayTipsLabel.text = ""
//        self.snapchatTipsLabel.text = ""
        
        self.saveButton.alpha = SaveButtonAlpha
    }
    
    func dateChangedFunc(datePicker:BirthdatePicker) {
        self.birthdayTextField.text = datePicker.formattedDate
        
        self.saveButton.isUserInteractionEnabled = true
        self.saveButton.alpha = 1.0
        
        if !self.isValidBool {
            self.saveButton.alpha = SaveButtonAlpha
        }
    }
    
    func handleEditBgViewHiddenStateFunc(isHidden:Bool) {
        self.editBgView.isHidden = isHidden
        self.tableView.isHidden = !isHidden
        self.view.endEditing(isHidden)
    }
    
    func dismissViewControllerFunc() {
        self.panningTowardsSide = .right
        self.dismiss(animated: true, completion: nil)
    }
    
    func keyboardWillShowFunc(notification:NSNotification) {
//        let value = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        let keyboardRect = value.cgRectValue
//        print("*** keyboardRect.show = \(keyboardRect)")
        
        // 根据keyboardRect的height对比tableview contentsize的位置计算tableview上移的高度，此处暂加固定值处理
        UIView.animate(withDuration: DurationTime) {
            self.tableViewHeightConstraint.constant = 633 + 45
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHideFunc(notification:NSNotification) {
//        let value = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        let keyboardRect = value.cgRectValue
//        print("*** keyboardRect.hide = \(keyboardRect)")
        
        UIView.animate(withDuration: DurationTime) {
            self.tableViewHeightConstraint.constant = 633
            self.view.layoutIfNeeded()
        }
    }
    
    func addProfileDataFunc() {
        
        var profileArray : DataTupleArray = []
        
        let profileTextString = APIController.shared.currentUser?.first_name ?? ""
        
        let photoPathString = APIController.shared.currentUser?.profile_photo_upload_url ?? ""
        
        var localizedTimeString = ""
        if let secondsInApp = APIController.shared.currentUser?.seconds_in_app.value {
            if secondsInApp < 60 {
                localizedTimeString = "1 min"
            } else if secondsInApp < 3600 {
                localizedTimeString = "\(secondsInApp / 60) min"
            } else if secondsInApp < 7200 {
                localizedTimeString = "1 hour"
            } else {
                localizedTimeString = "\(secondsInApp / 60 / 60) hours"
            }
        }
        
        profileArray.append((.profile, cellType:.editProfile, text: profileTextString, image: photoPathString, other: localizedTimeString + " on Monkey"))
        
        self.dataArray.append(profileArray)
    }
    
    func formattedDate(date:Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.string(from: date)
    }
    
    func addEditDataFunc() {
        
        var editArray : DataTupleArray = []
        
        let user = APIController.shared.currentUser
        
        let birthdayDate = Date(timeIntervalSince1970: (user?.birth_date?.timeIntervalSince1970)!)
        
        editArray.append((.textFieldRight, cellType:.firstName, text: "😊 Name :", image: "", other: user?.first_name ?? ""))
        editArray.append((.textFieldRight, cellType:.birthday, text: "🎂 Birthday :", image: "", other: self.formattedDate(date: birthdayDate)))
        editArray.append((.textFieldRight, cellType:.snapchatName, text: "👻 Snapchat :", image: "", other: user?.snapchat_username ?? ""))
        
        self.initNameTextFieldInputViewFunc(date: birthdayDate)
        
        self.editInitialValueTuple = (user?.first_name ?? "", self.formattedDate(date: birthdayDate), user?.snapchat_username ?? "")
        
        self.dataArray.append(editArray)
    }
    
    func initNameTextFieldInputViewFunc(date:Date) {
        
        self.datePicker = BirthdatePicker(frame: CGRect(x:0, y:0, width:ScreenWidth, height:216))
        self.datePicker.date = date
        self.datePicker.datePickerMode = UIDatePickerMode.date
        self.datePicker.addTarget(self, action: #selector(dateChangedFunc), for: .valueChanged)
        self.birthdayTextField.inputView = self.datePicker
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        self.snapchatTipsLabel.text = ""
        
        if textField == self.nameTextField {
            self.nameTipsLabel.sizeToFit()
            self.nameTipsLabel.text = "You can change your name once every 2 months"
            self.nameTipsLabel.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
            if self.birthdayTextField.isUserInteractionEnabled {
                self.birthdayTipsLabel.text = ""
            }
        } else if textField == self.birthdayTextField {
            if self.nameTextField.isUserInteractionEnabled {
                self.nameTipsLabel.text = ""
            }
            
            self.birthdayTipsLabel.sizeToFit()
            self.birthdayTipsLabel.text = "Better make sure yo, you can only change this once"
            self.birthdayTipsLabel.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
        } else if textField == self.snapchatTextField {
            if self.nameTextField.isUserInteractionEnabled {
                self.nameTipsLabel.text = ""
            }
            
            if self.birthdayTextField.isUserInteractionEnabled {
                self.birthdayTipsLabel.text = ""
            }
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let currentUser : RealmUser = APIController.shared.currentUser {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                
                if let birthday = currentUser.birth_date {
                    if self.nameTextField.text != currentUser.first_name || self.datePicker.formattedDate != dateFormatter.string(from: birthday as Date) || self.snapchatTextField.text != currentUser.snapchat_username {
                        self.saveButton.isUserInteractionEnabled = true
                        self.saveButton.alpha = 1
                        
                        if !self.isValidBool {
                            self.saveButton.alpha = 0.25
                        }
                    } else {
                        self.saveButton.alpha = self.SaveButtonAlpha
                    }
                } else {
                    self.saveButton.alpha = self.SaveButtonAlpha
                }
                
                self.updateTipsFunc(textField: textField)
            }
        }
        
        return true
    }
    
    func updateTipsFunc(textField:UITextField) {
        
        if textField == self.nameTextField {
            if self.nameTextField.charactersCount <= 2 {
                self.nameTipsLabel.text = "Invalid format"
                self.nameTipsLabel.textColor = UIColor.init(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
            } else {
                self.nameTipsLabel.text = "You can change your name once every 2 months"
                self.nameTipsLabel.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
            }
        } else if textField == self.snapchatTextField {
            if !self.snapchatTextField.isValid {
                self.snapchatTipsLabel.text = "Invalid format"
                self.snapchatTipsLabel.textColor = UIColor.init(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
            } else {
                self.snapchatTipsLabel.text = ""
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func loadEditBgViewDataFunc() {
        JSONAPIRequest(url: "\(Environment.baseURL)/api/\(UserOptions.api_version.rawValue)/\(UserOptions.requst_subfix)", options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler {[weak self] (response) in
                switch response {
                case .error( _): break
                case .success(let jsonAPIDocument):
                    
                    if let userOption = Mapper<UserOptions>().map(JSON: jsonAPIDocument.json) {
                        
                        if userOption.update_birth_date {
                            self?.birthdayTextField.isUserInteractionEnabled = true
                            self?.birthdayTextField.textColor = UIColor.white.withAlphaComponent(0.7);
                        } else {
                            self?.birthdayTextField.isUserInteractionEnabled = false
                            self?.birthdayTextField.textColor = UIColor.white.withAlphaComponent(0.5);
                        }
                        
                        // 服务器返回的时间是 未来能修改的那一天的日期,不是返回的修改日期
                        let time = userOption.update_username.timeIntervalSince1970
                        let now = Date().timeIntervalSince1970 * 1000
                        
                        let canEditBool = time - now  < 0
                        let sec : Double = abs(now - time) / 1000
                        let min : Double = floor(sec / 60)
                        let hour : Double = floor(min / 60)
                        var day : Int = Int(floor(hour / 24))
                        
                        if canEditBool {
                            self?.nameTextField.text = ""
                            self?.nameTextField.isUserInteractionEnabled = true
                            self?.nameTextField.textColor = UIColor.init(white: 1, alpha: 0.7)
                        } else {
                            day = day < 1 ? 1 : day
                            self?.nameTextField.isUserInteractionEnabled = false
                            self?.nameTextField.textColor = UIColor.init(white: 1, alpha: 0.5)
                            self?.nameTipsLabel.text = "You can change your name after \(day) days"
                        }
                    }
                }
        }
    }
    
    func initData() {
        
        self.dataArray.removeAll()
        
        self.addProfileDataFunc()
        
        self.addEditDataFunc()
        
        self.tableView.reloadData()
        
        self.loadEditBgViewDataFunc()
    }
    
    func initView() {
        
        self.panningTowardsSide = .right
        
        self.tableViewHeightConstraint.constant = ScreenHeight < 666 ? (ScreenHeight - 44) : 633
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowFunc), name: .UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideFunc), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

}

extension SettingEditViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let dataTuple = self.dataArray[indexPath.section][indexPath.row]
        
        switch dataTuple.cellStyle {
        case .profile:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell") as! SettingProfileCell
            
            cell.delegate = self
            
            cell.viewController = self
            
            cell.settingModel = SettingModel.settingModel(data: dataTuple)
            
            return cell
        case .textFieldRight:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "editCell") as! SettingEditCell
            
            cell.settingModel = SettingModel.settingModel(data: dataTuple)
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section != 0 {
            
            self.handleEditBgViewHiddenStateFunc(isHidden: false)
            
            self.nameTextField.text = self.editInitialValueTuple.firstName
            self.birthdayTextField.text = self.editInitialValueTuple.birthadyString
            self.snapchatTextField.text = self.editInitialValueTuple.snapchatString
            
            if self.nameTextField.isUserInteractionEnabled {
                self.nameTipsLabel.text = ""
            }
            
            self.birthdayTipsLabel.text = ""
            self.snapchatTipsLabel.text = ""
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headView = Bundle.main.loadNibNamed("Setting", owner: self, options: nil)![0] as! SettingHeadView
        headView.headTitleButton.setTitle(self.SectionTitleArray[section], for: .normal)
        return headView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 83 : 64
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
}

/**
 * cell代理相关
 */
extension SettingEditViewController : SettingProfileCellDelegate {
    
    func uploadedProfileImageSuccessFunc() {
        if self.uploadImgClosure != nil {
            self.uploadImgClosure!()
        }
    }
    
    func editProfileBtnClickFunc() {
        self.dismissViewControllerFunc()
    }
    
}
