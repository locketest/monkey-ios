//
//  MyContactsCell.swift
//  Monkey
//
//  Created by fank on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol MyContactsCellDelegate : NSObjectProtocol {
	func myContactsCellBtnClickFunc(idString: String, phoneString: String)
}

class MyContactsCell: UITableViewCell {
	
	var idString : String?
	
	var phoneString : String?
	
	var delegate : MyContactsCellDelegate?
	
	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var phoneLabel: UILabel!
	
	@IBOutlet weak var funnelLabel: UILabel!
	
	@IBOutlet weak var headImageView: CachedImageView!
	
	@IBOutlet weak var inviteButton: BigYellowButton!
	
	var myContactsModel : MyContactsModel {
		get {
			return MyContactsModel()
		}
		set(newMyContactsModel){
			
			self.idString = newMyContactsModel.idString
			
			self.phoneString = newMyContactsModel.phoneString
			
			self.nameLabel.text = newMyContactsModel.nameString
			
			self.phoneLabel.text = newMyContactsModel.phoneString
			
			if let timeStamp = newMyContactsModel.timestampDouble {
				
				let date = Date(timeIntervalSince1970: timeStamp / 1000)
				
				let second = date.timeIntervalSince(Date())
				
				if second > 0 { // 截止时间是当前时间以后就加图层
					self.inviteButton.isUserInteractionEnabled = false
					self.inviteButton.isEnabled = false
					
					self.inviteButton.setTitle("", for: .normal)
					self.addProgressViewFunc(progress: CGFloat(second) / (60 * 60 * 24 * 3), isBringToFont: true)
				} else {
					self.inviteButton.isUserInteractionEnabled = true
					self.inviteButton.isEnabled = true
					
					self.inviteButton.setTitle("👋", for: .normal)
				}
			}
			
			guard newMyContactsModel.phoneString != nil else { return }
			
			if FileManager.default.fileExists(atPath: ContactsImageRootPath + "/" + newMyContactsModel.phoneString!) {
				self.headImageView.url = ContactsImageRootPath + "/" + newMyContactsModel.phoneString!
			} else {
				self.headImageView.placeholder = Tools.getGenderDefaultImageFunc()
			}
		}
	}
	
	@IBAction func btnClickFunc(_ sender: UIButton) {
		
		self.inviteButton.setTitle("", for: .normal)
		
		self.inviteButton.isUserInteractionEnabled = false
		self.inviteButton.isEnabled = false
		
		self.addProgressViewFunc(progress: 1, isBringToFont: false)
		
		if self.delegate != nil {
			self.delegate!.myContactsCellBtnClickFunc(idString: self.idString!, phoneString: self.phoneString!)
		} else {
			print("代理为空")
		}
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
	
	func addProgressViewFunc(progress:CGFloat, isBringToFont:Bool) {
		
		let shapeLayer = CAShapeLayer()
		
		shapeLayer.frame = CGRect(x: 0, y: 0, width: self.inviteButton.width / 2, height: self.inviteButton.height / 2)
		shapeLayer.position = self.inviteButton.center
		shapeLayer.fillColor = UIColor.clear.cgColor
		
		shapeLayer.lineWidth = self.inviteButton.width / 2
		shapeLayer.strokeColor = UIColor.black.withAlphaComponent(0.45).cgColor
		
		shapeLayer.strokeStart = 0
		shapeLayer.strokeEnd = progress
		
		let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.inviteButton.width / 2, height: self.inviteButton.height / 2))
		
		shapeLayer.path = circlePath.cgPath
		
		self.layer.addSublayer(shapeLayer)
		
		if isBringToFont {
			self.bringSubview(toFront: self.funnelLabel)
		}
	}
}
