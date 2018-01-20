//
//  MKMatchManager.swift
//  Monkey
//
//  Created by YY on 2018/1/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class MKMatchManager: NSObject {
    
    var afmCount: Int = 0
    
    var needShowAFMAlert : Bool {
        return  self.afmCount >= RemoteConfigManager.shared.match_autoskip_warncount
    }
    
    static let shareManager = MKMatchManager()
}
