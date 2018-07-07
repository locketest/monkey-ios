//
//  MyContactsModel.swift
//  Monkey
//
//  Created by fank on 2018/6/13.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

/**
 邀请联系人
*/
class MyContactsModel: Codable {
	
	var nameString : String?
	
	var phoneString : String?
	
	var inviteTimesInt : Int?
	
	var inviteAtDouble : Double?
	
	var nextInviteAtDouble : Double?
	
	class func myContactsModel(dict:[String:AnyObject]) -> MyContactsModel {
		
		let myContactsModel = MyContactsModel()
		
		myContactsModel.nameString = dict["name"] as? String
		myContactsModel.phoneString = dict["phone_number"] as? String
		myContactsModel.inviteTimesInt = dict["invite_times"] as? Int
		myContactsModel.inviteAtDouble = dict["invite_at"] as? Double
		myContactsModel.nextInviteAtDouble = dict["next_invite_at"] as? Double
		
		return myContactsModel
	}
}

