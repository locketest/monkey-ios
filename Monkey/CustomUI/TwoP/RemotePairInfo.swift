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
	func beginChat(with match: MatchModel)
	
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
		self.addSubview(leftUserBio)
		leftUserBio.snp.makeConstraints { (maker) in
			maker.leading.top.bottom.equalTo(0)
		}
		leftUserBio.show(with: self.match.left)
		self.leftUserBio = leftUserBio
		
		if let rightUser = self.match.right {
			let rightUserBio = UserBioView.init(frame: self.bounds)
			rightUserBio.frame.origin.x = self.bounds.size.width / 2
			self.addSubview(rightUserBio)
			rightUserBio.snp.makeConstraints { (maker) in
				maker.trailing.top.bottom.equalTo(0)
				maker.leading.equalTo(leftUserBio.snp.trailing)
				maker.width.equalTo(leftUserBio.snp.width)
			}
			rightUserBio.show(with: rightUser)
			self.rightUserBio = rightUserBio
		}
	}
	
	private func onepInfoApperance() {
		let leftRemoteInfo = RemoteUserInfo.remoteInfoView()
		leftRemoteInfo.frame = self.bounds
		leftRemoteInfo.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.insertSubview(leftRemoteInfo, at: 0)
		leftRemoteInfo.show(with: self.match.left)
		leftRemoteInfo.actionDelegate = self
		self.leftRemoteInfo = leftRemoteInfo
	}
	
	private func pairInfoApperance() {
		let leftRemoteInfo = RemoteUserInfo.remoteInfoView()
		leftRemoteInfo.frame.size.width = self.bounds.size.width / 2
		self.insertSubview(leftRemoteInfo, at: 0)
		leftRemoteInfo.snp.makeConstraints { (maker) in
			maker.leading.top.bottom.equalTo(0)
		}
		leftRemoteInfo.show(with: self.match.left)
		leftRemoteInfo.actionDelegate = self
		self.leftRemoteInfo = leftRemoteInfo
		
		if let rightUser = self.match.right {
			let rightRemoteInfo = RemoteUserInfo.remoteInfoView()
			rightRemoteInfo.frame.origin.x = self.bounds.size.width / 2
			self.insertSubview(rightRemoteInfo, at: 1)
			rightRemoteInfo.snp.makeConstraints { (maker) in
				maker.trailing.top.bottom.equalTo(0)
				maker.leading.equalTo(leftRemoteInfo.snp.trailing)
				maker.width.equalTo(leftRemoteInfo.snp.width)
			}
			rightRemoteInfo.show(with: rightUser)
			rightRemoteInfo.actionDelegate = self
			self.rightRemoteInfo = rightRemoteInfo
		}
	}
	
	fileprivate func addRemoteInfo() {
		if self.match.matched_pair() {
			// 如果是 pair
			self.pairInfoApperance()
		}else {
			// 如果是一个人
			self.onepInfoApperance()
		}
	}
	
	fileprivate func removeRemoteBio() {
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
			self.pairBioApperance()
		}else {
			// 如果是一个人
			self.onepBioApperance()
		}
	}
	
	func reported(user: MatchUser) {
		if user == match.left {
			self.leftRemoteInfo?.reported()
		}else if user == match.right {
			self.rightRemoteInfo?.reported()
		}
	}
	
	func addFriend(user: MatchUser) {
		if user == match.left {
			self.leftRemoteInfo?.update(friendStatus: true)
		}else if user == match.right {
			self.rightRemoteInfo?.update(friendStatus: true)
		}
	}
}

extension RemotePairInfo: RemoteActionDelegate {
	func friendTapped(to user: MatchUser) {
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/\(match.match_id)/addfriend/\(user.user_id)", method: .post) { (_) in
			
		}
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
	func beginChat(with match: MatchModel) {
		guard self.showedRemoteInfo == false else { return }
		self.match = match
		
		self.addRemoteInfo()
		self.removeRemoteBio()
	}
}
