//
//  SettingBasicCell.swift
//  Monkey
//
//  Created by fank on 2018/5/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  setting basic cell

import UIKit

class SettingBasicCell: UITableViewCell {

    @IBOutlet weak var itemLabel: UILabel!
    
    var settingModel : SettingModel {
        get {
            return SettingModel()
        }
        set(newSettingModel){
            
            self.selectionStyle = .none

            self.itemLabel.text = newSettingModel.textString
        }
        
    }

}
