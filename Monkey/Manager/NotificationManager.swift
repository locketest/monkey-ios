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
		stackBackground.axis = .vertical
		stackBackground.spacing = 5.0
		stackBackground.alignment = .fill
		stackBackground.distribution = .fill
	}

	// showing notifications
    weak var currentNotificationViews = NSHashTable<InAppNotificationBar>.weakObjects()
	private var stackBackground: UIStackView = UIStackView()
	
	fileprivate func dismissAllNotificationBar() {
		self.stackBackground.arrangedSubviews.forEach { (notificationBar) in
			(notificationBar as! InAppNotificationBar).dismiss()
		}
	}
	
	fileprivate func showInAppNotificationBar(user: RealmUser, style: InAppNotificationBar.Style) {
		if stackBackground.arrangedSubviews.count == 3 {
			let firstBar = stackBackground.arrangedSubviews.first as! InAppNotificationBar
			firstBar.dismiss()
			firstBar.removeFromSuperview()
		}
		
		let window = UIApplication.shared.delegate!.window!!
		if stackBackground.superview == nil {
			window.addSubview(stackBackground)
			stackBackground.snp.makeConstraints { (make) in
				make.leading.equalTo(0)
				make.top.equalTo(0)
				make.trailing.equalTo(0)
			}
		}
		
		let notificationBar = InAppNotificationBar.instanceFromNib(user: user, style: style)
		stackBackground.addArrangedSubview(notificationBar)
		notificationBar.snp.makeConstraints { (maker) in
			maker.height.equalTo(76)
		}
	}
}

extension NotificationManager: UserObserver {
	func currentUserDidLogout() {
		self.dismissAllNotificationBar()
	}
}

extension NotificationManager: MessageObserver {
	func didReceiveVideoCall(call: VideoCallModel) {
		self.showInAppNotificationBar(user: UserManager.shared.currentUser!, style: InAppNotificationBar.Style.VideoCall)
	}
	
	func didReceiveCallCancel(call: String) {
		
	}
	
}
