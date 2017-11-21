//
//  BackgroundColorGradientLayer.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/22/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

@IBDesignable class ColorGradientView: UIView {
    @IBInspectable var topColor: UIColor = Colors.blue.withAlphaComponent(0.75)
    @IBInspectable var bottomColor: UIColor = Colors.black(0.80)
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override func layoutSubviews() {
        (layer as! CAGradientLayer).colors = [topColor.cgColor, bottomColor.cgColor]
    }
}
