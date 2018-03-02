//
//  MonkeySwitch.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/2.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//


import UIKit

@IBDesignable class MonkeySwitch: UIControl {
	
	var modeIndicator = UIView.init(frame: CGRect.init(x: 2, y: 10, width: 36, height: 10))
	var modeEmoji = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 24, height: 29))
	var switchValueChanged: ((Bool) -> ())?
	
	var open = false {
		didSet {
			self.reloadApperance()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	func configureApperance() {
		self.addSubview(modeIndicator)
		modeIndicator.backgroundColor = open ? UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1.0, alpha: 1.0) : UIColor.init(white: 1, alpha: 0.3)
		modeIndicator.layer.cornerRadius = 5
		modeIndicator.layer.masksToBounds = true
		modeIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
		modeIndicator.isUserInteractionEnabled = false
		
		self.addSubview(modeEmoji)
		modeEmoji.textAlignment = NSTextAlignment.center
		modeEmoji.font = UIFont.init(name: "Apple Color Emoji", size: 20)
		modeEmoji.text = "🐵"
		modeEmoji.frame = CGRect.init(x: open ? 16 : 0, y: 0, width: 24, height: 29)
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
		UIView.animate(withDuration: 0.25, animations: {
			self.modeIndicator.backgroundColor = open ? UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1.0, alpha: 1.0) : UIColor.init(white: 1, alpha: 0.3)
			self.modeEmoji.frame = CGRect.init(x: open ? 16 : 0, y: 0, width: 24, height: 29)
		}) { ( _) in
			self.isUserInteractionEnabled = true
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
