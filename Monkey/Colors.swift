//
//  Colors.swift
//  Monkey
//
//  Created by Isaiah Turner on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import UIKit

/**
 Monkey's brand colors used throughout the app.
 
 Black and white colors are often paired with an opacity and in those cases, should be generated using the `black(opacity)` and `white(opacity)` functions.
*/
class Colors {
    /// A plain white color.
    static let white: UIColor = .white
    /// A plain black color.
    static let black: UIColor = .black
    /// The clear color.
    static let clear: UIColor = .clear
    
    /// The Monkey brand blue color.
    static let blue = UIColor(red: 100.0 / 255.0, green: 74.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
    /// An alias for blue since some people thing Monkey is purple when it is actually blue.
    static let purple = UIColor(red: 100.0 / 255.0, green: 74.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
    /// The Monkey brand yellow color.
    static let yellow = UIColor(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1.0)
    
    /**
     Generate a transparent white color.
     - parameters:
        - opacity: The opacity value as a CGFloat between 0.0 and 1.0.
     - returns:
     A white color with the provided opacity.
     */
    class func white(_ opacity: CGFloat) -> UIColor {
        return UIColor(white: 1.0, alpha: opacity)
    }
    
    /**
     Generate an opaque black color.
     - parameters:
        - opacity: The opacity value as a CGFloat between 0.0 and 1.0.
     - returns:
     A black color with the provided opacity.
     */
    class func black(_ opacity: CGFloat) -> UIColor {
        return UIColor(white: 0.0, alpha: opacity)
    }
}
