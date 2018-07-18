//
//  NotificationManager.swift
//  Monkey
//
//  Created by Philip Bernstein on 7/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import Alamofire
import SnapKit

@objc protocol InAppNotificationActionDelegate: NSObjectProtocol {
	func videoCallDidAccept(videoCall: VideoCallModel, from bar: InAppNotificationBar?)
	func videoCallDidReject(videoCall: VideoCallModel, from bar: InAppNotificationBar?)
	
	func twopInviteDidAccept(from friend: Int)
	func twopInviteDidReject(from friend: Int)
	
	func pairRequestDidAccept(invitePair: InvitedPair, from bar: InAppNotificationBar?)
	func pairRequestDidReject(invitePair: InvitedPair, from bar: InAppNotificationBar?)
}

@objc protocol InAppNotificationPreActionDelegate: NSObjectProtocol {
	@objc optional func shouldPresentVideoCallNotification(videoCall: VideoCallModel) -> Bool
	
	@objc optional func shouldPresentPairRequestNotification(invitePair: InvitedPair) -> Bool
	
	@objc optional func shouldPresentTwopInviteNotification(from friend: Int) -> Bool
}

class NotificationManager: NSObject {
	
	static let InAppNotificationLimitCount = 3
    static let shared = NotificationManager()
	private override init() {
		super.init()
		stackBackground.frame = CGRect.init(x: 5.0, y: 20.0, width: Environment.ScreenWidth - 10.0, height: 76.0)
		stackBackground.axis = .vertical
		stackBackground.spacing = 5.0
	}

	weak var actionDelegate: InAppNotificationActionDelegate? {
		didSet {
			if actionDelegate == nil {
				self.dismissAllNotificationBar()
				UserManager.shared.delMessageObserver(observer: self)
				MessageCenter.shared.delMessageObserver(observer: self)
			}else {
				UserManager.shared.addMessageObserver(observer: self)
				MessageCenter.shared.addMessageObserver(observer: self)
			}
		}
	}
	
	weak var prePresentDelegate: InAppNotificationPreActionDelegate?
	
	// showing notifications
    weak var currentNotificationViews = NSHashTable<InAppNotificationBar>.weakObjects()
	private var stackBackground: UIStackView = UIStackView()
	
	func dismissAllNotificationBar(except acceptBar: InAppNotificationBar? = nil) {
		self.stackBackground.arrangedSubviews.forEach { (notificationBar) in
			if notificationBar != acceptBar {
				self.dismissBar(bar: notificationBar as! InAppNotificationBar)
			}
		}
	}
	
	private func checkEmptyNotificationBar() {
		if self.stackBackground.arrangedSubviews.count == 0 {
			self.stackBackground.removeFromSuperview()
		}
	}
	
	fileprivate func showInAppNotificationBar(user: RealmUser, style: InAppNotificationBar.Style) -> InAppNotificationBar {
		if stackBackground.arrangedSubviews.count == NotificationManager.InAppNotificationLimitCount {
			let firstBar = stackBackground.arrangedSubviews.first as! InAppNotificationBar
			self.dismissBar(bar: firstBar)
		}
		let topWindow = UIApplication.shared.keyWindow
		if stackBackground.superview == nil, let topWindow = topWindow {
			topWindow.addSubview(stackBackground)
			stackBackground.layer.zPosition = UIWindowLevelAlert
			stackBackground.snp.makeConstraints { (make) in
				make.leading.equalTo(5)
				make.trailing.equalTo(-5)
				
				if #available(iOS 11, *), Environment.isIphoneX {
					make.top.equalTo(topWindow.safeAreaLayoutGuide.snp.topMargin)
				} else {
					make.top.equalTo(20)
				}
			}
		}else {
			topWindow?.bringSubview(toFront: stackBackground)
		}
		
		let notificationBar = InAppNotificationBar.instanceFromNib(user: user, style: style)
		
		stackBackground.addArrangedSubview(notificationBar)
		notificationBar.onAccept = { [unowned self, weak notificationBar] in
			guard let bar = notificationBar else { return }
			self.dismissAllNotificationBar(except: bar)
		}
		
		notificationBar.willDismiss = { [unowned self, weak notificationBar] in
			guard let bar = notificationBar else { return }
			self.dismissBar(bar: bar)
		}
		
		notificationBar.onDismiss = { [unowned self] in
			self.checkEmptyNotificationBar()
		}
		
		notificationBar.snp.makeConstraints { (maker) in
			maker.height.equalTo(76)
		}
		
		self.showBar(bar: notificationBar)
		return notificationBar
	}
	
	fileprivate func showBar(bar: InAppNotificationBar) {
		let animated = stackBackground.arrangedSubviews.count != 1
		bar.present(animated: animated)
	}
	
	fileprivate func dismissBar(bar: InAppNotificationBar) {
		let animated = stackBackground.arrangedSubviews.count != 1
		bar.dismiss(animated: animated)
	}
}

extension NotificationManager: UserObserver {
	func currentUserDidLogout() {
		self.dismissAllNotificationBar()
	}
}

extension NotificationManager: MessageObserver {
	func didReceiveVideoCall(call: VideoCallModel) {
		if self.prePresentDelegate?.shouldPresentVideoCallNotification?(videoCall: call) == false {
			return
		}
		
		guard let friendship = call.friendship else { return }
		let bar = self.showInAppNotificationBar(user: friendship, style: .VideoCall)
		bar.didAccept = {
			self.actionDelegate?.videoCallDidAccept(videoCall: call, from: bar)
		}
		bar.didDismiss = {
			self.actionDelegate?.videoCallDidReject(videoCall: call, from: bar)
		}
	}
	
	func didReceiveCallCancel(in chat: String) {
		guard let currentBars = self.currentNotificationViews?.allObjects else { return }
		for bar in currentBars {
			if bar.barStyle == InAppNotificationBar.Style.VideoCall {
				self.dismissBar(bar: bar)
			}
		}
	}
	
	func didReceiveTwopInvite(from: String) {
		guard let friend = Int(from) else { return }
		if self.prePresentDelegate?.shouldPresentTwopInviteNotification?(from: friend) == false {
			return
		}
		
		guard let friendship = UserManager.cachedUser(with: friend) else { return }
		let bar = self.showInAppNotificationBar(user: friendship, style: .TwopInvite)
		bar.didAccept = {
			self.actionDelegate?.twopInviteDidAccept(from: friend)
		}
		bar.didDismiss = {
			self.actionDelegate?.twopInviteDidReject(from: friend)
		}
	}
	
	func didReceivePairRequest(invitedPair: InvitedPair) {
		if self.prePresentDelegate?.shouldPresentPairRequestNotification?(invitePair: invitedPair) == false {
			return
		}
		
		guard let friendship = UserManager.cachedUser(with: invitedPair.friend_id) else { return }
		let bar = self.showInAppNotificationBar(user: friendship, style: .PairRequest)
		bar.didAccept = {
			self.actionDelegate?.pairRequestDidAccept(invitePair: invitedPair, from: bar)
		}
		bar.didDismiss = {
			self.actionDelegate?.pairRequestDidReject(invitePair: invitedPair, from: bar)
		}
	}
}
