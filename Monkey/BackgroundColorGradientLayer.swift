//
//  BackgroundColorGradientLayer.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/22/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

@IBDesignable class ColorGradientView: UIView {
    @IBInspectable var topColor: UIColor = UIColor.init(red: 76.0/255.0, green: 71.0/255.0, blue: 249.0/255.0, alpha: 0.75)
    @IBInspectable var bottomColor: UIColor = Colors.black(0.80)
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override func layoutSubviews() {
        (layer as! CAGradientLayer).colors = [topColor.cgColor, bottomColor.cgColor]
    }
}
