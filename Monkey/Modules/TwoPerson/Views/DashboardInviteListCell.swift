//
//  DashboardInviteListCell.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	 invite friends on monkey cell

import UIKit

protocol DashboardInviteListCellDelegate : NSObjectProtocol {
	func dashboardInviteListCellBtnClickFunc(friendshipIdString:String)
}

class DashboardInviteListCell: UITableViewCell {
	
	var friendshipIdString : String?

    var delegate : DashboardInviteListCellDelegate?
	
	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var headImageView: CachedImageView!
	
	@IBOutlet weak var actionButton: BigYellowButton!

	var dashboardInviteListModel : DashboardInviteListModel {
		get {
			return DashboardInviteListModel()
		}
		set(newDashboardInviteListModel){
			
			self.nameLabel.text = newDashboardInviteListModel.nameString
			
			self.friendshipIdString = newDashboardInviteListModel.friendshipIdString
			
			self.headImageView.placeholder = Tools.getGenderDefaultImageFunc()
			self.headImageView.url = newDashboardInviteListModel.pathString
			
			// statusInt为0表示未操作，此时按钮不能点，为1，再判断timestamp，可以点击的时间，如果小于当前时间，就可以点，否则还是不能点
			if newDashboardInviteListModel.statusInt == 0 {
				self.actionButton.isUserInteractionEnabled = false
				self.actionButton.isEnabled = false
			} else {
				if let timeStamp = newDashboardInviteListModel.timestampDouble {
					let date = Date(timeIntervalSince1970: timeStamp / 1000)
					let second = date.timeIntervalSince(Date())
					if second > 0 { // 截止时间是当前时间以后就加图层
						self.actionButton.isUserInteractionEnabled = false
						self.actionButton.isEnabled = false
					} else {
						self.actionButton.isUserInteractionEnabled = true
						self.actionButton.isEnabled = true
					}
				}
			}
		}
	}
	
	@IBAction func btnClickFunc(_ sender: UIButton) {
		if self.delegate != nil {
			
			self.delegate!.dashboardInviteListCellBtnClickFunc(friendshipIdString: self.friendshipIdString!)
			
			if self.actionButton.isEnabled {
				self.actionButton.isEnabled = false
				self.actionButton.isUserInteractionEnabled = false
			}
		} else {
			print("代理为空")
		}
	}
}
