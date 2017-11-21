//
//  SelectableButton.swift
//  Monkey
//
//  Created by Isaiah Turner on 3/26/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation

/**
 BigYellowButtons with customized selected styles.
 */
@IBDesignable class SelectableButton: BigYellowButton {
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.backgroundColor = Colors.white
                self.isUserInteractionEnabled = false
            } else {
                self.backgroundColor = Colors.black(0.1)
                self.isUserInteractionEnabled = true
            }
        }
    }
}
