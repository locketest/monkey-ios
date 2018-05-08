//
//  SettingModel.swift
//  Monkey
//
//  Created by fank on 2018/5/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  setting model

import UIKit

class SettingModel: NSObject {

    var textString : String?
    
    var timeString : String?
    
    var imgPathString : String?
    
    class func settingModel(data:DataTuple) -> SettingModel {
        
        let settingModel = SettingModel()
        
        settingModel.textString = data.text
        
        settingModel.timeString = data.other
        
        settingModel.imgPathString = data.image
        
        return settingModel
    }
    
}
