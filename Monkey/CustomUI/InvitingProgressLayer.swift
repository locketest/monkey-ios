//
//  InvitingProgressLayer.swift
//  TTTest
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 fank. All rights reserved.
//

import UIKit

let kHWAnimationKey = "kHWAnimationKey"
let kHWRotateAnim = "kHWRotateAnim"
let kHWStrokeStartAnim = "kHWStrokeStartAnim"
let kHWStrokeEndAnim = "kHWStrokeEndAnim"

class InvitingProgressLayer: CAShapeLayer, CAAnimationDelegate {
	
	var duringTime = 2.5
	
	var curColorIndex = 0
	
	var isStartTurn = true
	
	var hadPlayingAnim = false
	
	var superLayer : CALayer?
	
	var superBackColor : UIColor?
	
	var rotateAnim : CABasicAnimation?
	
	var startAnim : CABasicAnimation?
	
	var endAnim : CABasicAnimation?
	
	var colors = [Tools.colorWithHexStringFunc(hexString: "FFEA03"), Tools.colorWithHexStringFunc(hexString: "1EF2AF"), Tools.colorWithHexStringFunc(hexString: "3EDBFF"), Tools.colorWithHexStringFunc(hexString: "8888FF"), Tools.colorWithHexStringFunc(hexString: "ED77CA"), Tools.colorWithHexStringFunc(hexString: "FF9327")]
	
	override init(layer: Any) {
		super.init(layer: layer)
		
		self.superLayer = layer as? CALayer
		
		self.initAnimations()
		
		self.lineWidth = 2
		self.lineCap = kCALineCapRound
		
		self.changeColor()
		
		self.fillColor = UIColor.clear.cgColor
		self.strokeStart = 0
		self.strokeEnd = 1
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func initAnimations() {
		
		weak var weakSelf = self
		
		self.rotateAnim = CABasicAnimation(keyPath: "transform.rotation")
		self.rotateAnim?.duration = self.duringTime
		self.rotateAnim?.isRemovedOnCompletion = false
		self.rotateAnim?.fillMode = kCAFillModeForwards
		self.rotateAnim?.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		self.rotateAnim?.fromValue = 0
		self.rotateAnim?.toValue = 2 * Double.pi
		self.rotateAnim?.delegate = weakSelf
		self.rotateAnim?.setValue(kHWRotateAnim, forKey: kHWAnimationKey)
		
		self.startAnim = CABasicAnimation(keyPath: "strokeStart")
		self.startAnim?.duration = self.duringTime * 0.5
		self.startAnim?.isRemovedOnCompletion = false
		self.startAnim?.fillMode = kCAFillModeForwards
		self.startAnim?.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		self.startAnim?.fromValue = 0
		self.startAnim?.toValue = 1
		self.startAnim?.delegate = weakSelf
		self.startAnim?.setValue(kHWStrokeStartAnim, forKey: kHWAnimationKey)
		
		self.endAnim = CABasicAnimation(keyPath: "strokeEnd")
		self.endAnim?.duration = self.duringTime * 0.5
		self.endAnim?.isRemovedOnCompletion = false
		self.endAnim?.fillMode = kCAFillModeForwards
		self.endAnim?.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		self.endAnim?.fromValue = 0
		self.endAnim?.toValue = 1
		self.endAnim?.delegate = weakSelf
		self.endAnim?.setValue(kHWStrokeEndAnim, forKey: kHWAnimationKey)
	}
	
	func startAniamtion() {
		if self.hadPlayingAnim || self.isHidden {
			return
		}
		
		self.hadPlayingAnim = true
		
		self.superLayer?.insertSublayer(self, at: 0)
		self.add(self.rotateAnim!, forKey: kHWRotateAnim)
		self.add(self.startAnim!, forKey: kHWStrokeStartAnim)
	}
	
	func stopAnimation() {
		
		self.hadPlayingAnim = false
		
		self.removeAllAnimations()
		self.removeFromSuperlayer()
	}
	
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		
		let keyPath = anim.value(forKey: kHWAnimationKey) as! String
		
		if flag {
			if keyPath == kHWRotateAnim {
				self.add(self.rotateAnim!, forKey: kHWRotateAnim)
			} else if keyPath == kHWStrokeStartAnim {
				self.removeAnimation(forKey: kHWStrokeStartAnim)
				self.add(self.endAnim!, forKey: kHWStrokeEndAnim)
				self.changeColor()
			} else if keyPath == kHWStrokeEndAnim {
				self.removeAnimation(forKey: kHWStrokeEndAnim)
				self.add(self.startAnim!, forKey: kHWStrokeStartAnim)
			}
		}
	}
	
	func changeColor() {
		
		if self.curColorIndex >= 5 {
			self.curColorIndex = 0
		} else {
			self.curColorIndex += 1
		}
		
		if self.superBackColor != nil {
			if self.superBackColor!.isEqual(self.colors[self.curColorIndex]) {
				self.curColorIndex = self.curColorIndex >= 5 ? 0 : self.curColorIndex + 1
			}
		}
		
//		self.strokeColor = self.colors[self.curColorIndex].cgColor
		
		self.strokeColor = UIColor.yellow.cgColor
	}
	
	override var frame: CGRect {
		didSet {
			let equal = superLayer?.frame == frame
			super.frame = frame
			if !equal {
				self.path = UIBezierPath(ovalIn: self.bounds).cgPath
			}
		}
	}
}

