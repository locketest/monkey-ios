//
//  ContactModel.swift
//  Monkey
//
//  Created by fank on 2018/6/13.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import Contacts

/**
 上传联系人
*/
class ContactModel: NSObject {
	
	var firstName : String!
	
	var familyName : String!
	
	var thumbnailImage : Data?
	
	var phoneNumber : String!
	
	class func contactModelToArray(contact:CNContact) -> [ContactModel] {
		
		var contactArray : [ContactModel] = []
		
		contact.phoneNumbers.forEach { (labelValue) in
			
			let contactModel = ContactModel()
			
			contactModel.firstName = contact.givenName
			contactModel.familyName = contact.familyName
			contactModel.thumbnailImage = contact.thumbnailImageData
			contactModel.phoneNumber = labelValue.value.stringValue
			
			// 每个条目中，至少有一个电话号码的长度大于等于4，小于等于17的才会将整个条目添加到集合中
			if contactModel.phoneNumber.count >= 4 && contactModel.phoneNumber.count <= 17 {
				contactArray.append(contactModel)
			}
		}
		
		return contactArray
	}
}
