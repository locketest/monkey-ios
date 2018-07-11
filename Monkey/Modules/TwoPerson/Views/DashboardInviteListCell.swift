//
//  DashboardInviteListCell.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	 invite friends on monkey cell

import UIKit

protocol DashboardInviteListCellDelegate : NSObjectProtocol {
	func dashboardInviteListCellBtnClickFunc(userIdInt:Int)
}

class DashboardInviteListCell: UITableViewCell {
	
	var userIdInt : Int?

    var delegate : DashboardInviteListCellDelegate?
	
	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var headImageView: CachedImageView!
	
	@IBOutlet weak var actionButton: BigYellowButton!

	var dashboardInviteListModel : DashboardInviteListModel {
		get {
			return DashboardInviteListModel()
		}
		set(newDashboardInviteListModel){
			
			self.userIdInt = newDashboardInviteListModel.userIdInt
			
			self.nameLabel.text = newDashboardInviteListModel.nameString
			
			self.headImageView.placeholder = Tools.getGenderDefaultImageFunc()
			self.headImageView.url = newDashboardInviteListModel.pathString
			
			// statusInt为0表示未操作，此时按钮不能点，为1，再判断timestamp，可以点击的时间，如果小于当前时间，就可以点，否则还是不能点
			if newDashboardInviteListModel.statusInt == 0 {
				self.actionButton.isUserInteractionEnabled = false
				self.actionButton.isEnabled = false
			} else {
				if let timestamp = newDashboardInviteListModel.nextInviteAtDouble {
					let timestampTuple = Tools.timestampIsExpiredFunc(timestamp: timestamp)
					if !timestampTuple.isExpired { // 截止时间是当前时间以后就加图层
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
			
			self.delegate!.dashboardInviteListCellBtnClickFunc(userIdInt: self.userIdInt!)
			
			if self.actionButton.isEnabled {
				self.actionButton.isEnabled = false
				self.actionButton.isUserInteractionEnabled = false
			}
		} else {
			print("代理为空")
		}
	}
}
