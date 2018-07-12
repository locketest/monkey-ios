//
//  MyContactsCell.swift
//  Monkey
//
//  Created by fank on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol MyContactsCellDelegate : NSObjectProtocol {
	func myContactsCellBtnClickFunc(phoneString: String)
}

class MyContactsCell: UITableViewCell {
	
	var phoneString : String?
	
	let shapeLayer = CAShapeLayer()
	
	var delegate : MyContactsCellDelegate?
	
	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var phoneLabel: UILabel!
	
	@IBOutlet weak var funnelLabel: UILabel!
	
	@IBOutlet weak var headImageView: UIImageView!
	
	@IBOutlet weak var inviteButton: BigYellowButton!
	
	var myContactsModel : MyContactsModel {
		get {
			return MyContactsModel()
		}
		set(newMyContactsModel){
			
			self.initShapelayerFunc()
			
			self.phoneString = newMyContactsModel.phoneString
			
			self.nameLabel.text = newMyContactsModel.nameString
			
			self.phoneLabel.text = newMyContactsModel.phoneString
			
			if let timeStamp = newMyContactsModel.nextInviteAtDouble {
				
				let date = Date(timeIntervalSince1970: timeStamp / 1000)
				
				let second = date.timeIntervalSince(Date())
//				print("*** second = \(second)")
				if second > 0 { // 截止时间是当前时间以后就加图层
					self.inviteButton.isUserInteractionEnabled = false
					self.inviteButton.isEnabled = false
					self.funnelLabel.isHidden = false
					
					self.inviteButton.setTitle("", for: .normal)
//					self.addShapeLayerFunc(progress: CGFloat(second) / (60 * 60 * 24 * 3), isBringToFont: true)
				} else {
					self.inviteButton.isUserInteractionEnabled = true
					self.inviteButton.isEnabled = true
					self.funnelLabel.isHidden = true
					
					self.inviteButton.setTitle("👋", for: .normal)
					self.removeShapeLayerFunc()
				}
			}
			
			guard newMyContactsModel.phoneString != nil else { return }
			
			if FileManager.default.fileExists(atPath: ContactsImageRootPath + "/" + newMyContactsModel.phoneString!) {
				self.headImageView.image = UIImage(contentsOfFile: ContactsImageRootPath + "/" + newMyContactsModel.phoneString!)
			} else {
				self.headImageView.image = UIImage(named: ProfileImageDefault)
			}
		}
	}
	
	@IBAction func btnClickFunc(_ sender: UIButton) {
		
//		self.addProgressViewFunc(progress: 1, isBringToFont: false)
		
		if self.delegate != nil {
			self.delegate!.myContactsCellBtnClickFunc(phoneString: self.phoneString!)
		} else {
			print("代理为空")
		}
		
		self.inviteButton.isUserInteractionEnabled = false
		self.inviteButton.isEnabled = false
		self.funnelLabel.isHidden = false
		
		self.inviteButton.setTitle("", for: .normal)
	}
	
	// #####@##### 睿，查看已经存入的图片和删除图片，测试后删除
	func handleHeadImgFunc() {
		
		let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first!
		
		try? FileManager.default.removeItem(atPath: path + "/13661063814")
		try? FileManager.default.removeItem(atPath: path + "/18611118009")
		try? FileManager.default.removeItem(atPath: path + "/188 1005 2020")
		
		let files = try? FileManager.default.contentsOfDirectory(atPath: ContactsImageRootPath)
		print("*** files = \(String(describing: files))")
	}
	
	func removeShapeLayerFunc() {
		self.shapeLayer.removeFromSuperlayer()
	}
	
	func addShapeLayerFunc(progress:CGFloat, isBringToFont:Bool) {

		shapeLayer.strokeEnd = progress
		
		self.layer.addSublayer(shapeLayer)

		if isBringToFont {
			self.bringSubview(toFront: self.funnelLabel)
		}
	}
	
	func initShapelayerFunc() {
		
		shapeLayer.frame = CGRect(x: 0, y: 0, width: self.inviteButton.width / 2, height: self.inviteButton.height / 2)
		shapeLayer.position = self.inviteButton.center
		shapeLayer.fillColor = UIColor.clear.cgColor
		
		shapeLayer.lineWidth = self.inviteButton.width / 2
		shapeLayer.strokeColor = UIColor.black.withAlphaComponent(0.45).cgColor
		
		shapeLayer.strokeStart = 0
		
		let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.inviteButton.width / 2, height: self.inviteButton.height / 2))
		
		shapeLayer.path = circlePath.cgPath
	}
}
