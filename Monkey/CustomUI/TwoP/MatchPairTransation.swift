//
//  MatchPairTransation.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/16.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class MatchPairTransation: MakeUIViewGreatAgain {
	
	var leftCircle = UIView.init(frame: CGRect.init(x: -780, y: -780, width: 780, height: 780))
	var rightCircle = UIView.init(frame: CGRect.init(x: -780, y: -780, width: 780, height: 780))
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	func configureApperance() {
		self.backgroundColor = UIColor.clear
		self.addSubview(self.leftCircle)
		self.addSubview(self.rightCircle)
		self.leftCircle.backgroundColor = UIColor.init(red: 100.0 / 255.0, green: 74.0 / 255.0, blue: 241.0 / 255.0, alpha: 1)
		self.rightCircle.backgroundColor = UIColor.init(red: 100.0 / 255.0, green: 74.0 / 255.0, blue: 241.0 / 255.0, alpha: 1)
		self.leftCircle.layer.cornerRadius = 390
		self.leftCircle.layer.masksToBounds = true
		self.rightCircle.layer.masksToBounds = true
		self.leftCircle.isHidden = true
		self.rightCircle.isHidden = true
		self.isUserInteractionEnabled = false
	}
	
	func startConnect() {
		self.leftCircle.isHidden = false
		self.rightCircle.isHidden = false
		self.isHidden = false
		self.transform = CGAffineTransform.identity
		
		self.leftCircle.center = CGPoint.init(x: -390, y: 0)
		self.leftCircle.frame.size = CGSize.init(width: 780, height: 780)
		self.leftCircle.layer.cornerRadius = 390
		
		self.rightCircle.center = CGPoint.init(x: ScreenWidth + 390, y: ScreenHeight)
		self.rightCircle.frame.size = CGSize.init(width: 780, height: 780)
		self.rightCircle.layer.cornerRadius = 390
		
		UIView.animate(withDuration: 0.15, animations: {
			self.leftCircle.center = CGPoint.init(x: -100, y: 0)
			self.rightCircle.center = CGPoint.init(x: ScreenWidth + 390 - 290, y: ScreenHeight)
		}) { (_) in
			UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveLinear, animations: {
				self.leftCircle.frame.size = CGSize.init(width: 1200, height: 1200)
				self.leftCircle.center = CGPoint.init(x: -100, y: 0)
				self.leftCircle.layer.cornerRadius = 600
				
				self.rightCircle.frame.size = CGSize.init(width: 1200, height: 1200)
				self.rightCircle.center = CGPoint.init(x: ScreenWidth + 390 - 290, y: ScreenHeight)
				self.rightCircle.layer.cornerRadius = 600
			}, completion: nil)
		}
	}
	
	func connectSuccess() {
		self.leftCircle.isHidden = false
		self.rightCircle.isHidden = false
		self.isHidden = false
		self.transform = CGAffineTransform.identity
		self.leftCircle.layer.cornerRadius = 600
		self.rightCircle.layer.cornerRadius = 600
		self.leftCircle.frame.size = CGSize.init(width: 1200, height: 1200)
		self.rightCircle.frame.size = CGSize.init(width: 1200, height: 1200)
		self.leftCircle.center = CGPoint.init(x: ScreenWidth / 2, y: ScreenHeight / 2)
		self.rightCircle.center = CGPoint.init(x: ScreenWidth / 2, y: ScreenHeight / 2)
		
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
			self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
		}) { (_) in
			self.transform = CGAffineTransform.identity
			self.leftCircle.isHidden = true
			self.rightCircle.isHidden = true
			self.isHidden = true
		}
	}
	
	func startReconnect() {
		self.leftCircle.isHidden = false
		self.rightCircle.isHidden = false
		self.isHidden = false
		self.leftCircle.layer.cornerRadius = 600
		self.rightCircle.layer.cornerRadius = 600
		self.leftCircle.frame.size = CGSize.init(width: 1200, height: 1200)
		self.rightCircle.frame.size = CGSize.init(width: 1200, height: 1200)
		self.leftCircle.center = CGPoint.init(x: ScreenWidth / 2, y: ScreenHeight / 2)
		self.rightCircle.center = CGPoint.init(x: ScreenWidth / 2, y: ScreenHeight / 2)
		self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
		
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
			self.leftCircle.frame.size = CGSize.init(width: 1200, height: 1200)
			self.rightCircle.frame.size = CGSize.init(width: 1200, height: 1200)
			self.leftCircle.center = CGPoint.init(x: ScreenWidth / 2, y: ScreenHeight / 2)
			self.rightCircle.center = CGPoint.init(x: ScreenWidth / 2, y: ScreenHeight / 2)
			self.transform = CGAffineTransform.identity
		}) { (_) in
			
		}
	}
	
	func reconnectSuccess() {
		self.leftCircle.isHidden = false
		self.rightCircle.isHidden = false
		self.isHidden = false
		self.leftCircle.frame.size = CGSize.init(width: 1200, height: 1200)
		self.leftCircle.center = CGPoint.init(x: -100, y: 0)
		self.leftCircle.layer.cornerRadius = 600
		
		self.rightCircle.frame.size = CGSize.init(width: 1200, height: 1200)
		self.rightCircle.center = CGPoint.init(x: ScreenWidth + 390 - 290, y: ScreenHeight)
		self.rightCircle.layer.cornerRadius = 600
		
		UIView.animate(withDuration: 0.15, animations: {
			self.leftCircle.center = CGPoint.init(x: -390, y: 0)
			self.rightCircle.center = CGPoint.init(x: ScreenWidth + 390, y: ScreenHeight)
		}) { (_) in
			UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveLinear, animations: {
				self.leftCircle.frame.size = CGSize.init(width: 780, height: 780)
				self.leftCircle.center = CGPoint.init(x: -390, y: 0)
				self.leftCircle.layer.cornerRadius = 390
				
				self.rightCircle.frame.size = CGSize.init(width: 780, height: 780)
				self.rightCircle.center = CGPoint.init(x: ScreenWidth + 390, y: ScreenHeight)
				self.rightCircle.layer.cornerRadius = 390
			}, completion:{ (_) in
				self.leftCircle.isHidden = true
				self.rightCircle.isHidden = true
				self.isHidden = true
			})
		}
	}
}
