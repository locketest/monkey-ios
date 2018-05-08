//
//  Taptic.swift
//  Monkey
//
//  Created by Harrison Weinerman on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import AudioToolbox

class TapticFeedback {
    class func impact(style: UIImpactFeedbackStyle) {
		if #available(iOS 10.2, *) {
			if UIDevice.current.responds(to: Selector("_feedbackSupportLevel")) {
				if let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int {
					if feedbackSupportLevel >= 2 {
						let generator = UIImpactFeedbackGenerator(style: style)
						generator.prepare()
						generator.impactOccurred()
					}
				}
			}
		}
		
		// fall back on System vibration
//		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate) // kSystemSoundID_Vibrate: (this is  `Peek` or a weak boom, 1520 is `Pop` or a strong boom)
    }
}
