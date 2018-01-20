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
        return  self.afmCount >= ((MKRemoteConfigHelper.shareHelper.configValues[MKRemoteConfigKeys.MatchAutoSkipTimesOut.rawValue])?.numberValue?.intValue)!
    }
    
    static let shareManager = MKMatchManager()
}
