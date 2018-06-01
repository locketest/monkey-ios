//
//  UIViewExtension.swift
//  Monkey
//
//  Created by fank on 2018/5/29.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

extension UIView {
    
    public var x : CGFloat {
        get {
            return self.frame.origin.x
        }
        set(newX) {
            var frame = self.frame
            frame.origin.x = newX
            self.frame = frame
        }
    }
    
    public var y : CGFloat {
        get {
            return self.frame.origin.y
        }
        
        set(newY) {
            var frame = self.frame
            frame.origin.y = newY
            self.frame = frame
        }
    }
    
    public var width : CGFloat {
        get {
            return self.frame.size.width
        }
        
        set(newWidth) {
            var frame = self.frame
            frame.size.width = newWidth
            self.frame = frame
        }
    }
    
    public var height : CGFloat {
        get {
            return self.frame.size.height
        }
        
        set(newHeight) {
            var frame = self.frame
            frame.size.height = newHeight
            self.frame = frame
        }
    }
    
    public var maxX : CGFloat {
        get {
            return self.x + self.width
        }
    }
    
    public var maxY : CGFloat {
        get {
            return self.y + self.height
        }
    }
    
    public var minX : CGFloat {
        get {
            return self.x
        }
    }
    
    public var minY : CGFloat {
        get {
            return self.y
        }
    }
    
    public var centerX : CGFloat {
        get {
            return self.center.x
        }
        
        set(newCenterX) {
            var center = self.center
            center.x = newCenterX
            self.center = center
        }
    }
    
    public var centerY : CGFloat {
        get {
            return self.center.y
        }
        
        set(newCenterY) {
            var center = self.center
            center.y = newCenterY
            self.center = center
        }
    }
}
