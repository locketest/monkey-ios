//
//  NSMutableAttributedStringExtension.swift
//  Monkey
//
//  Created by fank on 2018/5/29.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

let SystemFont13 = UIFont.systemFont(ofSize: 13)
let SystemFont15 = UIFont.systemFont(ofSize: 15)
let SystemFont17 = UIFont.systemFont(ofSize: 17)

let BoldSystemFont13 = UIFont.boldSystemFont(ofSize: 13)
let BoldSystemFont15 = UIFont.boldSystemFont(ofSize: 15)
let BoldSystemFont18 = UIFont.boldSystemFont(ofSize: 18)
let BoldSystemFont20 = UIFont.boldSystemFont(ofSize: 20)

extension NSMutableAttributedString {
    
    class func attributeStringWithText(textOne:String, textTwo:String, textThree:String, colorOne:UIColor, colorTwo:UIColor, fontOne:UIFont, fontTwo:UIFont) -> NSMutableAttributedString {
        
        let attr = NSMutableAttributedString(string: textOne + textTwo + textThree)
        
        attr.setAttributes([NSForegroundColorAttributeName:colorOne, NSFontAttributeName:fontOne], range: NSMakeRange(0, textOne.count))
        
        attr.setAttributes([NSForegroundColorAttributeName:colorTwo, NSFontAttributeName:fontTwo], range: NSMakeRange(textOne.count, textTwo.count))
        
        attr.setAttributes([NSForegroundColorAttributeName:colorOne, NSFontAttributeName:fontOne], range: NSMakeRange(textOne.count + textTwo.count, textThree.count))
        
        return attr
    }
    
}
