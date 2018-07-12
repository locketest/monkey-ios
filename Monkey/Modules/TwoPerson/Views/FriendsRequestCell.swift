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
	
	var delegate : FriendsRequestCellDelegate?

	@IBOutlet weak var nameLabel: UILabel!
	
	@IBOutlet weak var headImageView: CachedImageView!
	
	var tempFriendsRequestModel : FriendsRequestModel!
	
	var friendsRequestModel : FriendsRequestModel {
		get {
			return FriendsRequestModel()
		}
		set(newFriendsRequestModel){
			
			self.tempFriendsRequestModel = newFriendsRequestModel
			
			self.nameLabel.text = newFriendsRequestModel.nameString
			
			self.headImageView.placeholder = ProfileImageDefault
			self.headImageView.url = newFriendsRequestModel.pathString
		}
	}

	@IBAction func btnClickFunc(_ sender: UIButton) {
		if self.delegate != nil {
			self.delegate!.friendsRequestCellBtnClickFunc(model: self.tempFriendsRequestModel, isCancel: (sender.tag == 1 ? true : false))
		} else {
			print("代理为空")
		}
	}
}
