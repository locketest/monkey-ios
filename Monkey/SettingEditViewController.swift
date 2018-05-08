//
//  SettingEditViewController.swift
//  Monkey
//
//  Created by fank on 2018/5/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  设置编辑页

import UIKit

class SettingEditViewController: SwipeableViewController {
    
    let DurationTime = 0.25
    
    var saveButton: BigYellowButton!
    
    /**
     *  isEditting: 是否正在编辑
     */
    var isEdittingBool = false
    
    /**
     *  isEditting: 是否是初次进入编辑状态，处理编辑状态下多次reload事件
     */
    var isFirstEditBool = true
    
    var dataArray : [DataTupleArray] = []
    
    let SectionTitleArray = ["🐵 YOUR PROFILE", "✏️ PROFILE EDITING"]
    
    var editInitialValueTuple = (firstName:"", birthadyString:"", snapchatString:"")
    
    var tempEditInitialValueTuple = (firstName:"", birthadyString:"", snapchatString:"")
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
        
        self.initData()
    }
    
    @IBAction func dismissBtnClickFunc(_ sender: UIButton) {
        self.dismissViewControllerFunc()
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
            self.tableViewHeightConstraint.constant = 569 + 45
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHideFunc(notification:NSNotification) {
//        let value = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        let keyboardRect = value.cgRectValue
//        print("*** keyboardRect.hide = \(keyboardRect)")
        
        UIView.animate(withDuration: DurationTime) {
            self.tableViewHeightConstraint.constant = 569
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
        
        self.editInitialValueTuple = (user?.first_name ?? "", self.formattedDate(date: birthdayDate), user?.snapchat_username ?? "")
        self.tempEditInitialValueTuple = (user?.first_name ?? "", self.formattedDate(date: birthdayDate), user?.snapchat_username ?? "")
        
        if self.isEdittingBool {
            editArray.append((.cancelSaveButton, cellType:.cancelSave, text: "", image: "", other: ""))
        }
        
        self.dataArray.append(editArray)
    }
    
    func editReloadFunc() {
        
        self.dataArray.removeAll()
        
        self.addEditDataFunc()
        
        self.tableView.reloadData()
    }
    
    func unEditReloadFunc() {
        
        self.dataArray.removeAll()
        
        self.addProfileDataFunc()
        
        self.addEditDataFunc()
        
        self.tableView.reloadData()
    }
    
    func initData() {
        self.unEditReloadFunc()
    }
    
    func initView() {
        
        self.tableViewHeightConstraint.constant = ScreenHeight < 666 ? (ScreenHeight - 44) : 569
        
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
            
            cell.delegate = self
            
            cell.dataTuple = dataTuple // 传到cell里用于判断inputView的类型
            
            cell.settingModel = SettingModel.settingModel(data: dataTuple)
            
            return cell
        case .cancelSaveButton:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cancelSaveCell") as! SettingCancelSaveCell
            
            self.saveButton = cell.saveButton // 此cell不复用，拉出来控制透明度及是否允许点击
            
            cell.delegate = self
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // normal页面时点击profile cell不做处理
        if self.isFirstEditBool && indexPath.section == 0 {
            return
        }
        
        // 在edit页面点击cell时将此cell的textfield变成第一响应者
        if self.isFirstEditBool {
            self.isEdittingBool = true
            self.isFirstEditBool = false
            self.editReloadFunc()
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? SettingEditCell {
                cell.cellTappedFunc()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headView = Bundle.main.loadNibNamed("Setting", owner: self, options: nil)![0] as! SettingHeadView
        let headTitleString = self.isEdittingBool ? self.SectionTitleArray[1] : self.SectionTitleArray[section]
        headView.headTitleButton.setTitle(headTitleString, for: .normal)
        return headView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.isEdittingBool {
            return indexPath.row == 3 ? 83 : 64
        } else {
            return indexPath.section == 0 ? 83 : 64
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
}

/**
 * cell代理相关
 */
extension SettingEditViewController : SettingProfileCellDelegate, SettingCancelSaveCellDelegate, SettingEditCellDelegate {
    
    func saveButtonEnableFunc() {
        if self.saveButton != nil {
            self.saveButton.alpha = 1
            self.saveButton.isUserInteractionEnabled = true
        }
    }
    
    func saveButtonDisableFunc() {
        if self.saveButton != nil {
            self.saveButton.alpha = 0.25
            self.saveButton.isUserInteractionEnabled = false
        }
    }
    
    func nameTextTypeAndValueDelegateFunc(dataTuple: DataTuple, valueString: String) {
        print("*** dataTuple.cellType = \(dataTuple.cellType), valueString = \(valueString)")
        
        switch dataTuple.cellType {
        case .firstName:
            tempEditInitialValueTuple.firstName = valueString
        case .birthday:
            tempEditInitialValueTuple.birthadyString = valueString
        case .snapchatName:
            tempEditInitialValueTuple.snapchatString = valueString
        default:
            break
        }
        
        if self.editInitialValueTuple == self.tempEditInitialValueTuple {
            self.saveButtonDisableFunc()
        } else {
            self.saveButtonEnableFunc()
        }
    }
    
    func editProfileBtnClickFunc() {
        self.dismissViewControllerFunc()
    }
    
    func cancelSaveBtnClickFunc(isCancel: Bool) {
        
        if isCancel {
            self.isEdittingBool = false
            self.isFirstEditBool = true
            self.unEditReloadFunc()
        } else {
            print("*** save success")
        }
    }
    
}
