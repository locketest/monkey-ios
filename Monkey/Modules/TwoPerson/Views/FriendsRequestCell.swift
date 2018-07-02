//
//  FriendsRequestCell.swift
//  Monkey
//
//  Created by fank on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

protocol FriendsRequestCellDelegate : NSObjectProtocol {
	func friendsRequestCellBtnClickFunc(model: FriendsRequestModel, isCancel: Bool)
}

class FriendsRequestCell: UITableViewCell {
	
	var idString : String?
	
	var delegate : FriendsRequestCellDelegate?

	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var headImageView: UIImageView!
	
	var friendsRequestModel : FriendsRequestModel {
		get {
			return FriendsRequestModel()
		}
		set(newFriendsRequestModel){
			
			self.selectionStyle = .none
			
			self.idString = newFriendsRequestModel.idString
			
			self.nameLabel.text = newFriendsRequestModel.nameString
			
			self.headImageView.kf.setImage(with: URL(string: newFriendsRequestModel.pathString!), placeholder: UIImage(named: Tools.getGenderDefaultImageFunc())!)
		}
	}

	@IBAction func btnClickFunc(_ sender: UIButton) {
		if self.delegate != nil {
			self.delegate!.friendsRequestCellBtnClickFunc(model: self.friendsRequestModel, isCancel: (sender.tag == 1 ? true : false))
		} else {
			print("代理为空")
		}
	}
}
