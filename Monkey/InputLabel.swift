//
//  InputLabel.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/26/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

@IBDesignable class InputLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.width / 2
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
