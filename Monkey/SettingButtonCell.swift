//
//  SettingButtonCell.swift
//  Monkey
//
//  Created by fank on 2018/5/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  SettingButtonCell

import UIKit

class SettingButtonCell: UITableViewCell {
    
    var dataTuple : DataTuple!

    @IBOutlet weak var itemLabel: UILabel!
    
    @IBOutlet weak var monkeySwitch: MonkeySwitch!
    
    var settingModel : SettingModel {
        get {
            return SettingModel()
        }
        set(newSettingModel){
            
            self.selectionStyle = .none
            
            self.itemLabel.text = newSettingModel.textString
            
            self.monkeySwitch.openEmoji = "🐵"
            
            if self.dataTuple.cellType == .acceptButton || self.dataTuple.cellType == .nearbyButton {
                
                self.monkeySwitch.open = self.dataTuple.cellType == .acceptButton ? Achievements.shared.autoAcceptMatch : Achievements.shared.nearbyMatch
                
                self.monkeySwitch.switchValueChanged = {
                    self.dataTuple.cellType == .acceptButton ? (Achievements.shared.autoAcceptMatch = $0) : (Achievements.shared.nearbyMatch = $0)
                }
            }
            
        }
        
    }
    
}
