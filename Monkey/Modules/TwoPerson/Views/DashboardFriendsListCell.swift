//
//  DashboardFriendsListCell.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol DashboardFriendsListCellDelegate : NSObjectProtocol {
	func dashboardFriendsListCellBtnClickFunc(model:DashboardFriendsListModel)
}

class DashboardFriendsListCell: UITableViewCell {
	
	var timer : Timer!
	
	var timeTuple : (CGFloat, CGFloat) = (300, 300)
	
	let shapeLayer = CAShapeLayer()
	
	var delegate : DashboardFriendsListCellDelegate?
	
	@IBOutlet weak var greenView: UIView!
	
	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var missedLabel: UILabel!
	
	@IBOutlet weak var emojiLabel: EmojiLabel!
	
	@IBOutlet weak var headImageView: CachedImageView!
	
	@IBOutlet weak var actionButton: JigglyButton!
	
	@IBOutlet weak var nameLabelCenterYConstraint: NSLayoutConstraint!
	
	var tempDashboardFriendsListModel : DashboardFriendsListModel?
	
	var dashboardFriendsListModel : DashboardFriendsListModel {
		get {
			return DashboardFriendsListModel()
		}
		set(newDashboardFriendsListModel){
			
			self.tempDashboardFriendsListModel = newDashboardFriendsListModel
			
			self.actionButton.emojiLabel = self.emojiLabel
			
			self.nameLabel.text = newDashboardFriendsListModel.nameString
			
			self.headImageView.placeholder = Tools.getGenderDefaultImageFunc()
			self.headImageView.url = newDashboardFriendsListModel.pathString
			
			// 根据状态控制actionButton的样式和内容，如果status为0未操作，timestampDouble时间还未到，inviteeId是自己，表示是被邀请的item
			let date = Date(timeIntervalSince1970: newDashboardFriendsListModel.timestampDouble! / 1000)
			if newDashboardFriendsListModel.statusInt == 0 && date.timeIntervalSince(Date()) > 0 && newDashboardFriendsListModel.inviteeIdString == APIController.shared.currentUser!.user_id {
				self.actionButton.backgroundColor = UIColor(red: 100 / 255, green: 74 / 255, blue: 241 / 255, alpha: 1)
				self.actionButton.isJiggling = true
				
				DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + date.timeIntervalSince(Date())) {
					self.actionButton.isJiggling = false
				}
			} else {
				// todo，睿，进来后如果是主动发起的30秒内，还该有个倒计时
				self.actionButton.backgroundColor = UIColor.yellow
			}
			
			if newDashboardFriendsListModel.onlineString == "1" {
				self.greenView.isHidden = false
			} else {
				self.greenView.isHidden = true
			}
			
			// 根据miss的状态处理missedLabel显示与隐藏状态、nameLabel的距离约束
			if newDashboardFriendsListModel.isMissedBool! {
				self.nameLabelCenterYConstraint.constant = -8
			} else {
				self.nameLabelCenterYConstraint.constant = 0
			}
		}
	}
	
	func countDownFunc(second:Double) {
		
	}
	
	@IBAction func btnClickFunc(_ sender: JigglyButton) {
		if self.delegate != nil {
//			self.delegate!.dashboardFriendsListCellBtnClickFunc(model: self.tempDashboardFriendsListModel!)
			
			// todo，睿，点击后的30秒倒计时，加个封装，传入时间
			self.addTimerFunc()
			self.actionButton.isUserInteractionEnabled = false
		} else {
			print("代理为空")
		}
	}
	
	func progressUpdateFunc() {
		
		if self.timeTuple.0 < 0 {
			self.timer.invalidate()
			self.timeTuple.0 = self.timeTuple.1
			self.shapeLayer.removeFromSuperlayer()
			self.actionButton.isUserInteractionEnabled = true
			return
		}
		
		self.layer.addSublayer(self.addProgressViewFunc(progress: self.timeTuple.0 / self.timeTuple.1))
		
		self.timeTuple.0 -= 1
	}
	
	func addTimerFunc() {
		self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(progressUpdateFunc), userInfo: nil, repeats: true)
		RunLoop.current.add(self.timer!, forMode: .commonModes)
	}
	
	func addProgressViewFunc(progress:CGFloat) -> CAShapeLayer {
		
		shapeLayer.frame = CGRect(x: 0, y: 0, width: self.actionButton.width / 2, height: self.actionButton.height / 2)
		shapeLayer.position = self.actionButton.center
		shapeLayer.fillColor = UIColor.clear.cgColor
		
		shapeLayer.lineWidth = self.actionButton.width / 2
		shapeLayer.strokeColor = UIColor.black.withAlphaComponent(0.45).cgColor
		
		shapeLayer.strokeStart = 0
		shapeLayer.strokeEnd = progress
		
		let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.actionButton.width / 2, height: self.actionButton.height / 2))
		
		shapeLayer.path = circlePath.cgPath
		
		return shapeLayer
	}
}
