//
//  DeleteAccountPopupViewController.swift
//  Monkey
//
//  Created by fank on 2018/5/29.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  删除账号popup，三个子视图，由右滑入

import UIKit

class DeleteAccountPopupViewController: MonkeyViewController, UITextFieldDelegate {
    
    let DurationTime = 0.35
    
    var isIntoStepThreeBool = false
    
    let ShowXValue : CGFloat = 5
    
    let HiddenXValue = -ScreenWidth
    
    let ButtonAlpha : CGFloat = 0.5
    
    var checkBoxBgViewHeight : CGFloat!
    
    var selectedReasonBtn = UIButton()
    
    @IBOutlet weak var checkBoxBgView: UIView!
    
    @IBOutlet weak var textFieldBgView: UIView!
    
    @IBOutlet weak var stepThreeLabel: UILabel!
    
    @IBOutlet weak var stepTwoTextView: UITextView!
    
    @IBOutlet weak var stepThreeTextField: UITextField!
    
    @IBOutlet weak var stepTwoDeleteButton: BigYellowButton!
    
    @IBOutlet weak var stepThreeDeleteButton: BigYellowButton!
    
    @IBOutlet weak var warningBgView: MakeUIViewGreatAgain!
    
    @IBOutlet weak var reasonBgView: MakeUIViewGreatAgain!
    
    @IBOutlet weak var confirmBgView: MakeUIViewGreatAgain!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
    }
    
    @IBAction func warningBtnClickFunc(_ sender: BigYellowButton) {
        
        if sender.tag == 1 {
            
            UIView.animate(withDuration: DurationTime, animations: {
                self.warningBgView.x = self.HiddenXValue
                self.reasonBgView.x = self.ShowXValue
            }) { (bool) in
                self.warningBgView.isHidden = true
            }
        } else {
            self.hiddenFunc()
        }
    }
    
    @IBAction func reasonBtnClickFunc(_ sender: BigYellowButton) {
        
        if sender.tag == 1 {
            
            self.confirmBgView.x = -self.HiddenXValue
            self.confirmBgView.isHidden = false
            
            UIView.animate(withDuration: DurationTime, animations: {
                self.reasonBgView.x = self.HiddenXValue
                self.confirmBgView.x = self.ShowXValue
            }) { (bool) in
                self.reasonBgView.isHidden = true
                self.isIntoStepThreeBool = true
            }
        } else {
            self.hiddenFunc()
        }
    }
    
    @IBAction func confirmBtnClickFunc(_ sender: BigYellowButton) {
        
        if sender.tag == 1 {
            self.confirmRequestFunc()
        } else {
            self.hiddenFunc()
        }
    }
    
    @IBAction func reasonDetailBtnClickFunc(_ sender: UIButton) {
        self.selectedReasonBtn.isSelected = false
        sender.isSelected = true
        self.selectedReasonBtn = sender
        
        if self.stepTwoDeleteButton.alpha == ButtonAlpha {
            self.stepTwoDeleteButton.alpha = 1
        }
        
        if !self.stepTwoDeleteButton.isEnabled {
            self.stepTwoDeleteButton.isEnabled = true
        }
        
        if sender.tag == 6 { // other btn
            self.stepTwoTextView.isUserInteractionEnabled = true
            self.stepTwoTextView.becomeFirstResponder()
        } else {
            if self.stepTwoTextView.isUserInteractionEnabled {
                self.stepTwoTextView.isUserInteractionEnabled = false
            }
        }
    }
    
    @IBAction func endEditBtnClickFunc(_ sender: UIButton) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func hiddenFunc() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func confirmRequestFunc() {
        
        let reason = self.selectedReasonBtn.tag == 6 ? self.selectedReasonBtn.currentTitle ?? "" : self.selectedReasonBtn.tag.description
        
        let parameters : [String:Any] = [
            "data": [
                "type": "deleteAccount",
                "attributes": [
                    "reason": reason
                ]
            ]
        ]
        
        guard APIController.shared.currentUser?.user_id != nil else {
            print("error: user_id is nil")
            return
        }
        
        JSONAPIRequest(url: "\(Environment.baseURL)/api/v1.3/accounts/me", method: .delete, parameters: parameters, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler {[weak self] (response) in
                switch response {
                case .error(_):
                    break
                case .success(_):
                    
                    if self?.selectedReasonBtn.tag != 6 {
                        AnaliticsCenter.log(withEvent: .deleteAccount, andParameter: ["reason":self?.selectedReasonBtn.currentTitle ?? ""])
                    }
                    
                    RealmDataController.shared.deleteAllData() { (error) in
                        guard error == nil else {
                            error?.log()
                            return
                        }
                        
                        APIController.authorization = nil
                        UserDefaults.standard.removeObject(forKey: "user_id")
                        Apns.update(callback: nil)
                        
                        let rootVC = self?.view.window?.rootViewController
                        rootVC?.presentedViewController?.dismiss(animated: false, completion: {
                            DispatchQueue.main.async {
                                rootVC?.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                }
        }
    }
    
    func textFieldValueChangedFunc() {
        
        if let string = self.stepThreeTextField.text {
            let textString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if textString == "DELETE" {
                self.stepThreeDeleteButton.alpha = 1
                self.stepThreeDeleteButton.isEnabled = true
            } else {
                self.stepThreeDeleteButton.isEnabled = false
                self.stepThreeDeleteButton.alpha = ButtonAlpha
            }
        }
    }
    
    func keyboardWillShowFunc(notification:NSNotification) {
        
        if self.isIntoStepThreeBool {
            self.confirmBgView.isHidden = false
        } else {
            self.confirmBgView.isHidden = true
            
            UIView.animate(withDuration: DurationTime) {
                self.checkBoxBgView.height = 0
                self.checkBoxBgView.isHidden = true
                self.textFieldBgView.y = self.checkBoxBgView.y
            }
        }
    }
    
    func keyboardWillHideFunc(notification:NSNotification) {
        
        if !self.isIntoStepThreeBool {
            UIView.animate(withDuration: DurationTime) {
                self.checkBoxBgView.height = self.checkBoxBgViewHeight
                self.checkBoxBgView.isHidden = false
                self.textFieldBgView.y = self.checkBoxBgView.maxY
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    func initView() {
        
        DispatchQueue.main.async {
            self.reasonBgView.x = -self.HiddenXValue
            self.confirmBgView.x = -self.HiddenXValue
        }
        
        self.checkBoxBgViewHeight = self.checkBoxBgView.height
        
        self.stepThreeLabel.attributedText = NSMutableAttributedString.attributeStringWithText(textOne: "Please type into ", textTwo: "DELETE", textThree:" on the text box todelete your account.", colorOne: UIColor.white, colorTwo: UIColor.yellow, fontOne: SystemFont17, fontTwo: BoldSystemFont20)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowFunc), name: .UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideFunc), name: .UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldValueChangedFunc), name: NSNotification.Name.UITextFieldTextDidChange, object: self.stepThreeTextField)
    }

}
