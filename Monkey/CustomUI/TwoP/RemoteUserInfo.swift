//
//  RemoteUserInfo.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/11.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import SnapKit
import UIKit

protocol RemoteActionDelegate {
	func friendTapped(to user: MatchUser)
	func reportTapped(to user: MatchUser)
	func insgramTapped(to user: MatchUser)
	func addTimeTapped()
}

class RemoteUserInfo: MakeUIViewGreatAgain {
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	private var user: MatchUser!
	var actionDelegate: RemoteActionDelegate?
	
	private var gradientShow: Bool = false
	private var colorGradient: ColorGradientView = ColorGradientView()
	private var reportButton: BigYellowButton = BigYellowButton()
	private var friendButton: BigYellowButton = BigYellowButton()
	private var instagramButton: BigYellowButton = BigYellowButton()
	private weak var remoteRender: UIView?
	
	private func configureApperance() {
		self.addSubview(self.colorGradient)
		self.colorGradient.frame = self.bounds
//		self.colorGradient.isHidden = true
		self.colorGradient.alpha = 0
		self.colorGradient.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(showGradient)))
		self.colorGradient.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		self.colorGradient.addSubview(self.reportButton)
		self.reportButton.roundedSquare = true
		self.reportButton.backgroundColor = UIColor.init(red: 1, green: 51.0 / 255.0, blue: 102.0 / 255.0, alpha: 1)
		self.reportButton.emoji = "👮"
		self.reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
		self.reportButton.snp.makeConstraints { (maker) in
			maker.trailing.equalTo(12)
			maker.width.height.equalTo(40)
			
			if Environment.isIphoneX {
				maker.top.equalTo(51)
			} else {
				maker.top.equalTo(27)
			}
		}
		
		self.addSubview(self.friendButton)
		self.friendButton.roundedSquare = true
		self.friendButton.backgroundColor = UIColor.init(red: 1, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1)
		self.friendButton.emoji = "🎉"
		self.friendButton.addTarget(self, action: #selector(friendTapped), for: .touchUpInside)
		self.friendButton.snp.makeConstraints { (maker) in
			maker.leading.equalTo(12)
			maker.width.height.equalTo(40)
			
			if Environment.isIphoneX {
				maker.top.equalTo(51)
			} else {
				maker.top.equalTo(27)
			}
		}
		
		self.colorGradient.addSubview(self.instagramButton)
		self.instagramButton.roundedSquare = true
		self.instagramButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
		self.instagramButton.emoji = "🌄"
		self.instagramButton.isHidden = true
		self.instagramButton.addTarget(self, action: #selector(insgramTapped), for: .touchUpInside)
		self.instagramButton.snp.makeConstraints { (maker) in
			maker.leading.equalTo(12)
			maker.width.height.equalTo(40)
			
			if Environment.isIphoneX {
				maker.top.equalTo(51)
			} else {
				maker.top.equalTo(27)
			}
		}
	}
	
	func show(with user: MatchUser) {
		self.user = user
		let remoteRender = user.renderContainer
		self.insertSubview(remoteRender, at: 0)
		remoteRender.frame = self.bounds
		remoteRender.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.update(friendStatus: user.friendMatched)
	}
	
	func update(friendStatus: Bool) {
		if friendStatus {
			self.instagramButton.isEnabled = true
			self.instagramButton.isHidden = false
		}else {
			self.friendButton.isEnabled = false
			self.friendButton.isHidden = true
		}
	}
	
	func friendTapped() {
		self.friendButton.isEnabled = false
		self.actionDelegate?.friendTapped(to: self.user)
	}
	
	func reportTapped() {
		self.actionDelegate?.reportTapped(to: self.user)
	}
	
	func insgramTapped() {
		self.actionDelegate?.insgramTapped(to: self.user)
	}
	
	func showGradient() {
		self.gradientShow = !self.gradientShow
		UIView.animate(withDuration: 0.25) {
			self.colorGradient.alpha = self.gradientShow ? 1 : 0
			self.friendButton.alpha = self.gradientShow ? 0 : 1
			self.instagramButton.alpha = self.gradientShow ? 0 : 1
		}
	}
}



