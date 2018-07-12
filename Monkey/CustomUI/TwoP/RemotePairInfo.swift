//
//  RemotePairInfo.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/11.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import SnapKit
import UIKit

@objc protocol MatchActionHandler {
	func beginChat()
	
	@objc optional func receiveTyping(message: TextMessage)
	@objc optional func receiveText(message: TextMessage)
	
	@objc optional func receiveSkip(message: MatchMessage)
	@objc optional func receiveAccept(message: MatchMessage)
	
	@objc optional func receiveUnMute(message: MatchMessage)
	@objc optional func receiveReport(message: MatchMessage)
	@objc optional func receiveAddTime(message: MatchMessage)
	@objc optional func receiveAddFriend(message: MatchMessage)
	
	@objc optional func receiveTurnBackground(message: MatchMessage)
	@objc optional func receiveTurnForeground(message: MatchMessage)
}

class RemotePairInfo: MakeUIViewGreatAgain {
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	fileprivate var match: MatchModel!
	var actionDelegate: RemoteActionDelegate?
	
	fileprivate var showedRemoteInfo = false
	private var leftUserBio: UserBioView?
	private var leftRemoteInfo: RemoteUserInfo?
	private var rightUserBio: UserBioView?
	private var rightRemoteInfo: RemoteUserInfo?
	
	private func configureApperance() {
		self.backgroundColor = UIColor.clear
		
	}
	
	private func onepBioApperance() {
		let leftUserBio = UserBioView.init(frame: self.bounds)
		leftUserBio.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.addSubview(leftUserBio)
		leftUserBio.show(with: self.match.left)
		self.leftUserBio = leftUserBio
	}
	
	private func pairBioApperance() {
		let leftUserBio = UserBioView.init(frame: self.bounds)
		leftUserBio.frame.size.width = self.bounds.size.width / 2
		leftUserBio.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleRightMargin]
		self.addSubview(leftUserBio)
		leftUserBio.show(with: self.match.left)
		self.leftUserBio = leftUserBio
		
		if let rightUser = self.match.right {
			let rightUserBio = UserBioView.init(frame: self.bounds)
			rightUserBio.frame.origin.x = self.bounds.size.width / 2
			rightUserBio.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin]
			self.addSubview(rightUserBio)
			rightUserBio.show(with: rightUser)
			self.rightUserBio = rightUserBio
		}
	}
	
	private func onepInfoApperance() {
		let leftRemoteInfo = RemoteUserInfo.init(frame: self.bounds)
		leftRemoteInfo.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.insertSubview(leftRemoteInfo, at: 0)
		leftRemoteInfo.show(with: self.match.left)
		self.leftRemoteInfo = leftRemoteInfo
	}
	
	private func pairInfoApperance() {
		let leftRemoteInfo = RemoteUserInfo.init(frame: self.bounds)
		leftRemoteInfo.frame.size.width = self.bounds.size.width / 2
		leftRemoteInfo.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleRightMargin]
		self.insertSubview(leftRemoteInfo, at: 0)
		leftRemoteInfo.show(with: self.match.left)
		self.leftRemoteInfo = leftRemoteInfo
		
		if let rightUser = self.match.right {
			let rightRemoteInfo = RemoteUserInfo.init(frame: self.bounds)
			rightRemoteInfo.frame.origin.x = self.bounds.size.width / 2
			rightRemoteInfo.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin]
			self.insertSubview(leftRemoteInfo, at: 1)
			rightRemoteInfo.show(with: rightUser)
			self.rightRemoteInfo = rightRemoteInfo
		}
	}
	
	func addRemoteInfo() {
		if self.match.matched_pair() {
			// 如果是 pair
			self.onepInfoApperance()
		}else {
			// 如果是一个人
			self.pairInfoApperance()
		}
	}
	
	func removeRemoteBio() {
		UIView.animate(withDuration: 0.25, animations: {
			self.leftUserBio?.alpha = 0
			self.rightUserBio?.alpha = 0
		}) { (_) in
			self.leftUserBio?.removeFromSuperview()
			self.leftUserBio = nil
			self.rightUserBio?.removeFromSuperview()
			self.rightUserBio = nil
		}
	}
	
	func show(with match: MatchModel) {
		self.match = match
		if match.matched_pair() {
			// 如果是 pair
			self.onepBioApperance()
		}else {
			// 如果是一个人
			self.pairBioApperance()
		}
	}
}

extension RemotePairInfo: RemoteActionDelegate {
	func friendTapped(to user: MatchUser) {
		self.actionDelegate?.friendTapped(to: user)
	}
	
	func reportTapped(to user: MatchUser) {
		self.actionDelegate?.reportTapped(to: user)
	}
	
	func insgramTapped(to user: MatchUser) {
		self.actionDelegate?.insgramTapped(to: user)
	}
	
	func addTimeTapped() {
		self.actionDelegate?.addTimeTapped()
	}
}

extension RemotePairInfo: MatchActionHandler {
	func beginChat() {
		guard self.showedRemoteInfo == false else { return }
		
		self.addRemoteInfo()
		self.removeRemoteBio()
	}
}
