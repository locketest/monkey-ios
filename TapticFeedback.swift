//
//  Taptic.swift
//  Monkey
//
//  Created by Harrison Weinerman on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation

class TapticFeedback {
    
    class func impact(style: UIImpactFeedbackStyle) {
        if #available(iOS 10.2, *) {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    // Error is not a UIImpactFeedbackStyle so it is separate
    class func feedback(type: UINotificationFeedbackType) {
        if #available(iOS 10.2, *) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        }
    }
}
