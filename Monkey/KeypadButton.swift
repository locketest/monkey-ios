//
//  BackgroundHighlightedButton.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/24/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

@IBDesignable class KeypadButton: UIButton {
    
    @IBInspectable var highlightedBackgroundColor :UIColor?
    @IBInspectable var nonHighlightedBackgroundColor :UIColor?
    /// The index of the button, corresponding to where on the keyboard it is. Used to convert from emojis to numbers when sending code
    @IBInspectable var value:String?
    override var isHighlighted :Bool {
        didSet {
            self.backgroundColor = isHighlighted ? highlightedBackgroundColor : nonHighlightedBackgroundColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // This color is taken from Apple's keyboard shadow, so not added to Colors as unlikely to be used again
        self.layer.shadowColor =  UIColor(red: 84.0 / 255.0, green: 86.0 / 255.0, blue: 88.0 / 255.0, alpha: 1.0).cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 5.0
    }
}
