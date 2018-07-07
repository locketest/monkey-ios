//
//  NotificationManager.swift
//  Monkey
//
//  Created by Philip Bernstein on 7/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import UserNotifications
import UserNotificationsUI
import RealmSwift
import Alamofire
import SnapKit

class NotificationManager: NSObject {
    static let shared = NotificationManager()
	private override init() {
		super.init()
		UserManager.shared.addMessageObserver(observer: self)
		MessageCenter.shared.addMessageObserver(observer: self)
		stackBackground.frame = CGRect.init(x: 5.0, y: 20.0, width: Environment.ScreenWidth - 10.0, height: 76.0)
		stackBackground.axis = .vertical
		stackBackground.spacing = 5.0
	}

	// showing notifications
    weak var currentNotificationViews = NSHashTable<InAppNotificationBar>.weakObjects()
	private var stackBackground: UIStackView = UIStackView()
	
	fileprivate func dismissAllNotificationBar(except acceptBar: InAppNotificationBar? = nil) {
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
	
	fileprivate func showInAppNotificationBar(user: RealmUser, style: InAppNotificationBar.Style) {
		if stackBackground.arrangedSubviews.count == 3 {
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
				
				if #available(iOS 11, *) {
					make.top.equalTo(topWindow.safeAreaLayoutGuide.snp.topMargin)
				} else {
					make.top.equalTo(0)
				}
			}
		}
		
		let random = InAppNotificationBar.Style.random()
		let notificationBar = InAppNotificationBar.instanceFromNib(user: user, style: random)
		
		stackBackground.addArrangedSubview(notificationBar)
		notificationBar.onAccept = { [unowned self, weak notificationBar] in
			self.dismissAllNotificationBar(except: notificationBar)
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
	}
	
	private func showBar(bar: InAppNotificationBar) {
		let animated = stackBackground.arrangedSubviews.count != 1
		bar.present(animated: animated)
	}
	
	private func dismissBar(bar: InAppNotificationBar) {
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
		self.showInAppNotificationBar(user: UserManager.shared.currentUser!, style: .VideoCall)
	}
	
	func didReceiveCallCancel(call: String) {
		
	}
	
	func didReceivePairRequest(message: [String : Any]) {
		self.showInAppNotificationBar(user: UserManager.shared.currentUser!, style: .PairRequest)
	}
	
	func didReceiveFriendInvite() {
		self.showInAppNotificationBar(user: UserManager.shared.currentUser!, style: .TwopInvite)
	}
}
