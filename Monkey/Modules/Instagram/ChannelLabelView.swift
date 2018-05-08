//
//  ChannelLabelView.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 9/8/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

@IBDesignable class ChannelLabelView: UIView {

    private var emojiLabel = UILabel()

    @IBInspectable var emojiLabelText:String? {
        get {
            return emojiLabel.text
        }
        set {
            emojiLabel.text = newValue
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        afterInit()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        afterInit()
    }
    
    private func afterInit() {
        self.backgroundColor = .white
        self.layer.masksToBounds = true
        
        self.addSubview(self.emojiLabel)
        self.emojiLabel.backgroundColor = Colors.purple
        self.emojiLabel.textAlignment = .center
        self.emojiLabel.font = UIFont(name: "AppleColorEmoji", size: 32.0)
        self.emojiLabel.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        self.layer.cornerRadius = frame.size.width / 2.0
        
        let borderWidth:CGFloat = 1.5
        self.emojiLabel.frame = CGRect(x:borderWidth, y: borderWidth, width: frame.size.width - (borderWidth*2.0), height: frame.size.height - (borderWidth*2.0))
        self.emojiLabel.layer.cornerRadius = self.emojiLabel.frame.size.width / 2.0
    }

}
