//
//  MonkeyModel.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/9.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

typealias MonkeyRealmObject = Object & RealmObjectProtocol
typealias MonkeyApiObject = CommonAPIRequestProtocol & SpecificAPIRequestProtocol
typealias MonkeyObject = MonkeyApiObject

// common model
// to make model great again
class MonkeyModel: Object, Mappable, MonkeyObject {
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	func mapping(map: Map) {
		
	}
	
	override func setValue(_ value: Any?, forKey key: String) {
		guard let property = self.objectSchema.properties.first(where: { $0.name == key }) else {
			return super.setValue(value, forKey: key)
		}
		guard property.type == .date, let stringValue = value as? String else {
			return super.setValue(value, forKey: key)
		}
		super.setValue(RealmDataController.shared.parseDate(stringValue), forKey: key)
	}
	
	func update(operation: @escaping () -> Swift.Void) -> Bool {
		do {
			guard let realm = try? Realm() else {
				return false
			}
			try realm.write {
				operation()
			}
			
			return true
		} catch (let error) {
			print(error)
			return false
		}
	}
	
	class var type: String {
		return String(describing: self)
	}
	
	class var requst_subfix: String {
		return type
	}
	
	class var api_version: ApiVersion {
		return ApiVersion.V10
	}
	
	override class func primaryKey() -> String {
		return "id"
	}
	
	class var attributes: [String]? {
		return nil
	}
}
