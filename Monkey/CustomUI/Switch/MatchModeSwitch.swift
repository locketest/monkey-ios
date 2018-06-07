//
//  MatchModeSwitch.swift
//  Monkey
//
//  Created by 王广威 on 2018/2/7.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

@IBDesignable class MatchModeSwitch: BigYellowButton {
	var matchMode: MatchMode? = Achievements.shared.selectMatchMode {
		didSet {
			switchToMode(matchMode: matchMode)
		}
	}
	
	var modeLabel = UILabel.init(frame: CGRect.init(x: 14, y: 10, width: 38, height: 20))
	var modeIndicator = UIView.init(frame: CGRect.init(x: 58, y: 15, width: 34, height: 10))
	var modeEmoji = UILabel.init(frame: CGRect.init(x: 54, y: 5, width: 24, height: 30))
	
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
		self.layer.cornerRadius = 20.0
		self.backgroundColor = UIColor.init(white: 0, alpha: 0.3)
		self.adjustsImageWhenDisabled = false
		
		let textMode = (matchMode == MatchMode.TextMode)
		self.addSubview(modeLabel)
		modeLabel.textAlignment = NSTextAlignment.center
		modeLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
		modeLabel.textColor = UIColor.white
		modeLabel.text = "Text"
		modeLabel.frame = CGRect.init(x: 14, y: 10, width: 38, height: 20)
		modeLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
		modeLabel.isUserInteractionEnabled = false
		
		self.addSubview(modeIndicator)
		modeIndicator.backgroundColor = textMode ? UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1.0, alpha: 1.0) : UIColor.init(white: 0, alpha: 0.5)
		modeIndicator.layer.cornerRadius = 5
		modeIndicator.layer.masksToBounds = true
		modeIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
		modeIndicator.isUserInteractionEnabled = false
		
		self.addSubview(modeEmoji)
		modeEmoji.textAlignment = NSTextAlignment.center
		modeEmoji.font = UIFont.init(name: "Apple Color Emoji", size: 20)
		modeEmoji.text = textMode ? "🙊" : "🐵"
		modeEmoji.frame = CGRect.init(x: textMode ? 72 : 54, y: 5, width: 24, height: 30)
		modeEmoji.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
		modeEmoji.isUserInteractionEnabled = false
		
	}
	
	func switchToMode(matchMode: MatchMode?) {
		self.isUserInteractionEnabled = false
		let textMode = (matchMode == MatchMode.TextMode)
		modeEmoji.text = textMode ? "🙊" : "🐵"
		UIView.animate(withDuration: 0.25, animations: {
			self.modeIndicator.backgroundColor = textMode ? UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1.0, alpha: 1.0) : UIColor.init(white: 0, alpha: 0.5)
			self.modeEmoji.frame = CGRect.init(x: textMode ? 72 : 54, y: 5, width: 24, height: 30)
		}) { ( _) in
			self.isUserInteractionEnabled = self.isEnabled
		}
	}
	
	func switchMode() {
		if let currentMode = matchMode {
			matchMode = currentMode == .TextMode ? .VideoMode : .TextMode
		}else {
			matchMode = MatchMode.TextMode
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
