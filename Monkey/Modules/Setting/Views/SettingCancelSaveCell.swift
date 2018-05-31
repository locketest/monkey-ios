//
//  SettingCancelSaveCell.swift
//  Monkey
//
//  Created by fank on 2018/5/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol SettingCancelSaveCellDelegate : NSObjectProtocol {
    func cancelSaveBtnClickFunc(isCancel:Bool)
}

class SettingCancelSaveCell: UITableViewCell {
    
    var delegate : SettingCancelSaveCellDelegate?

    @IBOutlet weak var saveButton: BigYellowButton!
    
    @IBAction func cancelAndSaveBtnClickFunc(_ sender: BigYellowButton) {
        if self.delegate != nil {
            self.delegate!.cancelSaveBtnClickFunc(isCancel: (sender.tag == 1 ? true : false))
        } else {
            print("代理为空")
        }
    }
    
}
