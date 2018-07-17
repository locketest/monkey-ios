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
	
	private var user: MatchUser!
	private var friend_stauts: Bool = false
	var actionDelegate: RemoteActionDelegate?
	
	var gradientShow: Bool = false
	var shouldShowReport: Bool = true
	@IBOutlet weak var colorGradient: ColorGradientView!
	@IBOutlet weak var reportButton: SmallYellowButton!
	@IBOutlet weak var friendButton: BigYellowButton!
	@IBOutlet weak var instagramButton: BigYellowButton!
	@IBOutlet weak var reportLabel: UILabel!
	var remoteRender: UIView?
	
	static func remoteInfoView() -> RemoteUserInfo {
		let view = UINib(nibName: "RemoteUserInfo", bundle: nil).instantiate(withOwner: nil, options: nil).first as! RemoteUserInfo
		view.configureApperance()
		return view
	}
	
	private func configureApperance() {
		self.colorGradient.alpha = 0
		self.reportLabel.isHidden = true
	}
	
	func show(with user: MatchUser) {
		self.user = user
		let remoteRender = user.renderContainer
		self.insertSubview(remoteRender, at: 0)
		remoteRender.frame = self.bounds
		remoteRender.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.update(friendStatus: user.friendMatched)
		
		if self.shouldShowReport {
			let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(showGradient))
			self.addGestureRecognizer(tapGesture)
		}else {
			self.colorGradient.isHidden = true
			self.reportButton.isHidden = true
			self.reportLabel.isHidden = true
		}
	}
	
	func reported() {
		self.reportButton.isEnabled = false
		self.reportButton.emojiLabel?.text = "😳"
		self.reportLabel.isHidden = false
		self.colorGradient.isHidden = true
	}
	
	func update(friendStatus: Bool) {
		self.friend_stauts = friendStatus
		if friendStatus {
			self.friendButton.isEnabled = false
			self.friendButton.isHidden = true
			
			if self.user.instagram_id != nil {
				self.instagramButton.isEnabled = true
				self.instagramButton.isHidden = false
			}else {
				self.instagramButton.isEnabled = false
				self.instagramButton.isHidden = true
			}
		}else {
			self.friendButton.isEnabled = true
			self.friendButton.isHidden = false
			
			self.instagramButton.isEnabled = false
			self.instagramButton.isHidden = true
		}
	}
	
	@IBAction func friendTapped(_ sender: Any) {
		self.friendButton.isEnabled = false
		self.actionDelegate?.friendTapped(to: self.user)
	}
	
	@IBAction func reportTapped(_ sender: Any) {
		self.actionDelegate?.reportTapped(to: self.user)
	}
	
	@IBAction func insgramTapped(_ sender: Any) {
		self.actionDelegate?.insgramTapped(to: self.user)
	}
	
	func showGradient() {
		self.gradientShow = !self.gradientShow
		UIView.animate(withDuration: 0.25) {
			self.colorGradient.alpha = self.gradientShow ? 1 : 0
			if self.friendButton.isEnabled {
				self.friendButton.alpha = self.gradientShow ? 0 : 1
			}else {
				self.friendButton.alpha = self.gradientShow ? 0 : 1.5
			}
			if self.instagramButton.isEnabled {
				self.instagramButton.alpha = self.gradientShow ? 0 : 1
			}
		}
	}
}

