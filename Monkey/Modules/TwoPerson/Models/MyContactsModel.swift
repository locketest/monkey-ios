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
	
	var idString : String?
	
	var nameString : String?
	
	var phoneString : String?
	
	var pathString : String?
	
	var timestampDouble : Double?
	
	class func myContactsModel(dict:[String:AnyObject]) -> MyContactsModel {
		
		let myContactsModel = MyContactsModel()
		
		myContactsModel.idString = dict["id"] as? String
		myContactsModel.nameString = dict["name"] as? String
		myContactsModel.phoneString = dict["phoneNumber"] as? String
//		myContactsModel.pathString = dict["avatarUrl"] as? String
		myContactsModel.timestampDouble = dict["timestamp"] as? Double
		
		return myContactsModel
	}
}

