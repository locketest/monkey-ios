//
//  BlurEffectView.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

@IBDesignable class BlurEffectView: UIView {
	
	var backgroundContainer: UIView {
		if UIAccessibilityIsReduceTransparencyEnabled() {
			return systemEffect?.contentView ?? self
		}else {
			return self
		}
	}
	var contentContainer = UIView.init()
	
	var systemEffect: UIVisualEffectView?
	weak var headerView: UITextView?
	func getHeader() -> UITextView {
		if let header = headerView {
			return header
		}else {
			let headerView = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: self.backgroundContainer.bounds.size.width, height: 30))
			headerView.autoresizingMask = [.flexibleWidth]
			headerView.backgroundColor = UIColor.init(white: 1, alpha: 0.06)
			headerView.textColor = UIColor.init(red: 154 / 255, green: 154 / 255, blue: 154 / 255, alpha: 1)
			headerView.font = UIFont.systemFont(ofSize: 15)
			headerView.textAlignment = .left
			headerView.isScrollEnabled = false
			headerView.isEditable = false
			headerView.isSelectable = false
			headerView.textContainerInset = UIEdgeInsets.init(top: 7, left: 4, bottom: 0, right: 0)
			
			self.backgroundContainer.addSubview(headerView)
			self.headerView = headerView
			return getHeader()
		}
	}
	
	var headerTitle: String? {
		didSet {
			self.refreshTitle()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.configuraApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.configuraApperance()
	}
	
	func configuraApperance() {
		//only apply the blur if the user hasn't disabled transparency effects
		if UIAccessibilityIsReduceTransparencyEnabled() == true {
			self.backgroundColor = .clear
			
			let blurEffect = UIBlurEffect(style: .dark)
			let blurEffectView = UIVisualEffectView(effect: blurEffect)
			//always fill the view
			blurEffectView.frame = self.bounds
			blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			
			self.addSubview(blurEffectView)
			self.systemEffect = blurEffectView
		} else {
			self.backgroundColor = UIColor.init(white: 0, alpha: 0.65)
		}
		
		contentContainer.backgroundColor = UIColor.clear
		contentContainer.frame = self.backgroundContainer.bounds
		contentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.backgroundContainer.addSubview(contentContainer)
		
		self.layer.cornerRadius = 12
	}
	
	func refreshTitle() {
		if let title = self.headerTitle {
			let headerLabel = self.getHeader()
			headerLabel.text = title
			contentContainer.frame = CGRect.init(x: 0, y: 30, width: self.backgroundContainer.bounds.size.width, height: self.backgroundContainer.bounds.size.height - 30)
		}else {
			headerView?.removeFromSuperview()
			contentContainer.frame = self.backgroundContainer.bounds
		}
	}
}
