//
//  MonkeySwitch.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/2.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//


import UIKit

@IBDesignable class MonkeySwitch: UIControl {
	
	var modeIndicator = UIView.init(frame: CGRect.init(x: 4, y: 10, width: 34, height: 10))
	var modeEmoji = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 24, height: 30))
	var switchValueChanged: ((Bool) -> ())?
	
	var openIndicatorColor = UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1.0, alpha: 1.0) {
		didSet {
			modeIndicator.backgroundColor = open ? openIndicatorColor : closeIndicatorColor
		}
	}
	
	var closeIndicatorColor = UIColor.init(white: 0, alpha: 0.5) {
		didSet {
			modeIndicator.backgroundColor = open ? openIndicatorColor : closeIndicatorColor
		}
	}
	
	var openEmoji = "🙊" {
		didSet {
			modeEmoji.text = open ? openEmoji : closeEmoji
		}
	}
	var closeEmoji = "🐵" {
		didSet {
			modeEmoji.text = open ? closeEmoji : openEmoji
		}
	}
	
	var open = false {
		didSet {
			self.reloadApperance()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.configureApperance()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
	}
	
	func configureApperance() {
		self.addSubview(modeIndicator)
		modeIndicator.backgroundColor = openIndicatorColor
		modeIndicator.layer.cornerRadius = 5
		modeIndicator.layer.masksToBounds = true
		modeIndicator.frame = CGRect.init(x: 4, y: 10, width: self.frame.size.width - 8, height: self.frame.size.height - 20)
		modeIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
		modeIndicator.isUserInteractionEnabled = false
		
		self.addSubview(modeEmoji)
		modeEmoji.textAlignment = NSTextAlignment.center
		modeEmoji.font = UIFont.init(name: "Apple Color Emoji", size: 20)
		modeEmoji.text = closeEmoji
		modeEmoji.frame = CGRect.init(x: open ? 16 : 0, y: 0, width: 24, height: 30)
		modeEmoji.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
		modeEmoji.isUserInteractionEnabled = false
		
		self.addTarget(self, action: #selector(switchChange), for: .touchUpInside)
	}
	
	func switchChange() {
		self.open = !self.open
		if switchValueChanged != nil {
			switchValueChanged!(self.open)
		}
	}
	
	func reloadApperance() {
		self.isUserInteractionEnabled = false
		let open = self.open
		modeEmoji.text = open ? openEmoji : closeEmoji
		UIView.animate(withDuration: 0.25, animations: {
			self.modeIndicator.backgroundColor = open ? self.openIndicatorColor : self.closeIndicatorColor
			self.modeEmoji.frame = CGRect.init(x: open ? self.frame.size.width - 24 : 0, y: (self.frame.size.height - 30) / 2, width: 24, height: 30)
		}) { ( _) in
			self.isUserInteractionEnabled = self.isEnabled
		}
	}
	
	/*
	// Only override draw() if you perform custom drawing.
	// An empty implementation adversely affects performance during animation.
	override func draw(_ rect: CGRect) {
	// Drawing code
	}
	*/
	
}
