//
//  SettingEditCell.swift
//  Monkey
//
//  Created by fank on 2018/5/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol SettingEditCellDelegate : NSObjectProtocol {
    func nameTextTypeAndValueDelegateFunc(dataTuple:DataTuple, valueString:String)
}

class SettingEditCell: UITableViewCell {
    
    var dataTuple : DataTuple?
    
    var datePicker : BirthdatePicker?
    
    var delegate : SettingEditCellDelegate?

    @IBOutlet weak var itemLabel: UILabel!
    
    @IBOutlet weak var tipsLabel: UILabel!
    
    @IBOutlet weak var nameTextField: UsernameTextField!
    
    var settingModel : SettingModel {
        get {
            return SettingModel()
        }
        set(newSettingModel){
            
            self.selectionStyle = .none
            
            self.nameTextField.isUserInteractionEnabled = false
            
            self.itemLabel.text = newSettingModel.textString
            
            self.nameTextField.text = newSettingModel.timeString
            
            self.tipsLabel.text = newSettingModel.imgPathString
            
            self.datePicker = BirthdatePicker(frame: CGRect(x:0, y:0, width:ScreenWidth, height:216))
            self.datePicker!.datePickerMode = UIDatePickerMode.date
            
            if let date = self.formattedDateFromString(dateString: newSettingModel.timeString!) {
                self.datePicker!.date = date
            }
            self.datePicker!.addTarget(self, action: #selector(dateChangedFunc), for: .valueChanged)
            
            if let dataTuple = self.dataTuple {
                switch dataTuple.cellType {
                case .birthday:
                    self.nameTextField.inputView = self.datePicker
                default:
                    self.nameTextField.inputView = nil
                }
            }
            
            self.nameTextField.addObserver(self, forKeyPath: "text", options: .new, context: nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if "text" == keyPath! {
            if let changeValue = change?[NSKeyValueChangeKey.newKey] {
                
                var value = "0"
                
                switch dataTuple?.cellType {
                case .firstName?:
                    if self.nameTextField.charactersCount <= 2 {
                        self.tipsLabel.text = "Invalid format"
                        self.tipsLabel.textColor = UIColor.init(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
                        value = ""
                    } else {
                        self.tipsLabel.text = "You can change your name once every 2 months"
                        self.tipsLabel.textColor = UIColor.init(red: 255.0/255.0, green: 252.0/255.0, blue: 1.0/255.0, alpha: 1.0)
                    }
                case .birthday?:
                    break
                case .snapchatName?:
                    if self.nameTextField.charactersCount < 3 {
                        self.tipsLabel.text = "Invalid format"
                        self.tipsLabel.textColor = UIColor.init(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
                        value = ""
                    } else {
                        self.tipsLabel.text = ""
                    }
                default:
                    break
                }
                
                if delegate != nil {
                    self.delegate?.nameTextTypeAndValueDelegateFunc(dataTuple: self.dataTuple!, valueString: value == "" ? "" : (changeValue as! String))
                } else {
                    print("delegate is nil")
                }
            }
        }
    }
    
    func cellTappedFunc() {
        self.nameTextField.isUserInteractionEnabled = true
        self.nameTextField.becomeFirstResponder()
    }
    
    func dateChangedFunc(datePicker:BirthdatePicker) {
        self.nameTextField.text = datePicker.formattedDate
    }
    
    func formattedDateFromString(dateString:String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: dateString)
    }
    
    deinit {
        self.nameTextField.removeObserver(self, forKeyPath: "text")
    }
}
