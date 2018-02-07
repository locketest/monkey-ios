//
//  SmallYellowButton.swift
//  Monkey
//
//  Created by 王广威 on 2018/2/7.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

@IBDesignable class SmallYellowButton: UIButton {
	
	var emojiLabel:EmojiLabel?
	
	/// Toggles the button opacity and touch down animations.
	override var isEnabled: Bool {
		didSet {
			// Disabled buttons are transparent.
			self.alpha = isEnabled ? 1.0 : 0.5
		}
	}
	
	@IBInspectable var roundedSquare: Bool = false
	
	/// When set to true, button will have a corner radius of 6 for a rounded square effect instead of a semi-circle endcap by default
	@IBInspectable var emoji: String? {
		didSet {
			if let currentLabel = emojiLabel {
				currentLabel.removeFromSuperview()
			}
			emojiLabel = EmojiLabel()
			if let emojiString = emoji {
				emojiLabel!.text = emojiString
				emojiLabel!.textAlignment = .center
				if self.titleLabel?.text == nil {
					emojiLabel?.frame = self.bounds
					emojiLabel?.font = UIFont(name: "Apple Color Emoji", size: 26)
				} else {
					emojiLabel?.font = UIFont(name: "Apple Color Emoji", size: 24)
					emojiLabel!.frame = CGRect(x: 0, y: 8, width: self.frame.size.width, height: 30)
					setPadding(15)
				}
				emojiLabel?.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
				self.addSubview(emojiLabel!)
			}
		}
	}
	
	func setPadding(_ padding: CGFloat) {
		self.titleEdgeInsets = UIEdgeInsetsMake(padding, 0, -padding, 0);
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		afterInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		afterInit()
	}
	
	func afterInit() {
		self.showsTouchWhenHighlighted = false
		self.tintColor = .clear
		self.layer.cornerRadius = 4
		self.layer.masksToBounds = true
		self.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
		
		self.addTarget(self, action: #selector(buttonTouchDown), for: UIControlEvents.touchDown)
		self.addTarget(self, action: #selector(buttonTouchCancel), for: UIControlEvents.touchCancel)
		self.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControlEvents.touchUpInside)
		self.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControlEvents.touchUpOutside)
		self.addTarget(self, action: #selector(buttonTouchDragOutside), for: UIControlEvents.touchDragOutside)
		self.addTarget(self, action: #selector(buttonTouchDragInside), for: UIControlEvents.touchDragInside)
	}
	
	func shrinkButton() {
		UIView.animate(
			withDuration: 0.15,
			delay: 0,
			options: UIViewAnimationOptions.allowUserInteraction,
			animations: {
				self.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
		},
			completion: { Void in()  }
		)
	}
	
	func enlargeButton(speed: Double) {
		UIView.animate(withDuration: 0.3, animations: {
			self.transform = CGAffineTransform.identity
		})
	}
	
	func buttonTouchUpInside(sender: UIButton) {
		self.enlargeButton(speed: 0.2)
	}
	func buttonTouchCancel(sender: UIButton) {
		self.enlargeButton(speed: 0.0)
	}
	func buttonTouchUpOutside(sender: UIButton) {
		self.enlargeButton(speed: 0.3)
	}
	func buttonTouchDragOutside(sender: UIButton) {
		self.enlargeButton(speed: 0.3)
	}
	func buttonTouchDragInside(sender: UIButton) {
		self.shrinkButton()
	}
	func buttonTouchDown(sender: UIButton) {
		self.shrinkButton()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		// Creates semicircle endcap effect
		if roundedSquare == false {
			self.layer.cornerRadius = self.frame.size.height / 2.0
		}
	}
}
