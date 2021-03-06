//
//  DashboardFriendsListCell.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol DashboardFriendsListCellDelegate : NSObjectProtocol {
	func dashboardFriendsListCellBtnClickFunc(model: DashboardFriendsListModel, cell: DashboardFriendsListCell, isPair: Bool)
}

class DashboardFriendsListCell: UITableViewCell {
	
	var timer : Timer!
	
	var timeTuple : (current: CGFloat, total:CGFloat) = (300, 300)
	
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
			
//			print("*** weight = \(newDashboardFriendsListModel.weightDouble!)")
			
			let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
			let rotateTransform = flipTransform.rotated(by: -CGFloat.pi / 2)
			shapeLayer.setAffineTransform(rotateTransform)
			
			self.tempDashboardFriendsListModel = newDashboardFriendsListModel
			
			self.actionButton.emojiLabel = self.emojiLabel
			
			self.nameLabel.text = newDashboardFriendsListModel.nameString
			
			self.headImageView.url = newDashboardFriendsListModel.pathString
			self.headImageView.placeholder = Tools.getGenderDefaultImageFunc(genderString: newDashboardFriendsListModel.genderString ?? "")
			
			if let nextInvite = newDashboardFriendsListModel.nextInviteAtDouble {
				
				let nextInviteTuple = Tools.timestampIsExpiredFunc(timestamp: nextInvite)
				
				self.emojiLabel.text = "🙌"
				
				if newDashboardFriendsListModel.inviteeIdInt?.description != APIController.shared.currentUser!.user_id { // 主动发起邀请
					
					self.actionButton.backgroundColor = UIColor.yellow
					self.actionButton.isJiggling = false
					
//					if self.timer != nil { self.stopTimerFunc() }
					
					if !nextInviteTuple.isExpired {
//						self.timeTuple.current = CGFloat(nextInviteTuple.second) / self.timeTuple.total
//						self.actionButton.isUserInteractionEnabled = false
//						self.emojiLabel.text = "⏳"
//						self.addTimerFunc()
					}
				} else { // 被邀请
					
					if !nextInviteTuple.isExpired {
						
						self.actionButton.backgroundColor = ActionButtonJigglingColor
						self.actionButton.isJiggling = true
						
						DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + nextInviteTuple.second) {
							self.actionButton.backgroundColor = UIColor.yellow
							self.actionButton.isJiggling = false
						}
					}
				}
			}
			
			// online为true时不显示miss状态，按状态优先级显示
			if let onlineStatusBool = newDashboardFriendsListModel.onlineStatusBool {
				if onlineStatusBool {
					self.greenView.isHidden = false
				} else {
					self.greenView.isHidden = true
				}
			}
			
//			print("*** isMissedBool = \(newDashboardFriendsListModel.isMissedBool)")
			// 根据miss的状态处理missedLabel显示与隐藏状态、nameLabel的距离约束
			if newDashboardFriendsListModel.isMissedBool {
				self.nameLabelCenterYConstraint.constant = -8
				self.missedLabel.isHidden = false
			} else {
				self.nameLabelCenterYConstraint.constant = 0
				self.missedLabel.isHidden = true
			}
		}
	}
	
	func countDownFunc(second:Double) {
		
	}
	
	@IBAction func btnClickFunc(_ sender: JigglyButton) {
		
		if self.delegate != nil {
			
//			if !Tools.timestampIsExpiredFunc(timestamp: self.tempDashboardFriendsListModel!.nextInviteAtDouble!).isExpired {
				// todo，睿，点击后的30秒倒计时，加个封装，传入时间
//				self.addTimerFunc()
//				self.actionButton.isUserInteractionEnabled = false
//			}
			
			if let model = self.tempDashboardFriendsListModel, let nextInvite = model.nextInviteAtDouble {
				
				let nextInviteTuple = Tools.timestampIsExpiredFunc(timestamp: nextInvite)
				
				if nextInviteTuple.isExpired { // 时间过期就是主动发起
					self.sendPairFunc()
				} else {
					if model.inviteeIdInt?.description != APIController.shared.currentUser!.user_id { // 时间过期，inviteeIdInt不是自己亦是主动邀请
						self.sendPairFunc()
					} else { // 被邀请，此处可将所有条件并联判断其它就是send pair
						self.delegate!.dashboardFriendsListCellBtnClickFunc(model: self.tempDashboardFriendsListModel!, cell: self, isPair: false)
						self.actionButton.backgroundColor = UIColor.yellow
						self.emojiLabel.text = "🙌"
						self.actionButton.isJiggling = false
					}
				}
			} else {
				self.sendPairFunc()
			}
		} else {
			print("代理为空")
		}
	}
	
	func sendPairFunc() {
		self.delegate!.dashboardFriendsListCellBtnClickFunc(model: self.tempDashboardFriendsListModel!, cell: self, isPair: true)
		self.actionButton.isUserInteractionEnabled = false
		self.emojiLabel.text = "⏳"
		self.addTimerFunc()
	}
	
	func progressUpdateFunc() {
		
		if self.timeTuple.current < 0 {
			self.timeTuple.current = self.timeTuple.total + 5
			self.shapeLayer.removeFromSuperlayer()
			self.actionButton.isUserInteractionEnabled = true
			self.emojiLabel.text = "🙌"
			self.timer.invalidate()
			self.timer = nil
			return
		}
		
		self.layer.addSublayer(self.addProgressViewFunc(progress: self.timeTuple.current / self.timeTuple.total))
		
		self.timeTuple.current -= 1
	}
	
	func addTimerFunc() {
		self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(progressUpdateFunc), userInfo: nil, repeats: true)
		RunLoop.current.add(self.timer!, forMode: .commonModes)
	}
	
	func stopJigglingFunc() {
		self.actionButton.backgroundColor = UIColor.yellow
		self.actionButton.isJiggling = false
	}
	
	func stopTimerFunc() {
		self.timeTuple = (300, 300)
		self.actionButton.isUserInteractionEnabled = true
		self.shapeLayer.removeFromSuperlayer()
		self.timer.invalidate()
		self.timer = nil
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
