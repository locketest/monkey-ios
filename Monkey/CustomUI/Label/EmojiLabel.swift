//
//  EmojiLabel.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/15/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit

class EmojiLabel: UILabel {
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0.0
    var leftInset: CGFloat = 0
    var rightInset: CGFloat = 0.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    override public var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}
