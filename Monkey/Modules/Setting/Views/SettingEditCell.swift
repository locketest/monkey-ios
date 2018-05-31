//
//  SettingEditCell.swift
//  Monkey
//
//  Created by fank on 2018/5/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class SettingEditCell: UITableViewCell {

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
            
        }
    }
}
