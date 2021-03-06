//
//  Tools.swift
//  Monkey
//
//  Created by fank on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

public let GoToSettingTag = "GoToSetting"

public let MyContactsModelTag = "MyContactsModel"

public let IsUploadContactsTag = "IsUploadContacts"

public let ProfileImageDefault = "ProfileImageDefault"

public let ActionButtonJigglingColor = UIColor(red: 100 / 255, green: 74 / 255, blue: 241 / 255, alpha: 1)

public let ContactsImageRootPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first! + "/contactsImage"

/**
 工具类
*/
class Tools: NSObject {
	
	/**
	 去空格
	*/
	class func trimSpace(string:String) -> String {
		return string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	/**
	 根据性别获取默认头像
	*/
	class func getGenderDefaultImageFunc(genderString:String) -> String {
		return genderString == Gender.female.rawValue ? "ProfileImageDefaultFemale" : "ProfileImageDefaultMale"
	}
	
	/**
	 判断时间戳是否过期
	*/
	class func timestampIsExpiredFunc(timestamp:Double) -> (isExpired:Bool, second:Double) {
		
		let date = Date(timeIntervalSince1970: timestamp / 1000)
		
		let second = date.timeIntervalSince(Date())
		
		if second > 0 { // 时间未过期
			return (false, second)
		} else {
			return (true, second)
		}
	}
	
	/**
	 字符串截取，传入需要截取的字符串开始位置(不按索引算)、结束位置(包含)
	*/
	class func subStringFunc(string:String, start:Int, end:Int) -> String {
		
		if string.count < end { return "" } // 避免下标越界
		
		let startIndex = string.index(string.startIndex, offsetBy: start - 1)
		
		let endIndex = string.index(string.startIndex, offsetBy: end)
		
		let subStringRange = startIndex ..< endIndex
		
		return string[subStringRange].description
	}
	
	/**
	 目标控件加外层圆边框
	*/
	class func drawCircleFunc(imageView:UIImageView, lineWidth:CGFloat, strokeColor:UIColor, padding:CGFloat) -> CAShapeLayer {
		
		let shapeLayer = CAShapeLayer()
		
		shapeLayer.frame = CGRect(x: 0, y: 0, width: imageView.width + padding, height: imageView.height + padding)
		shapeLayer.position = imageView.center
		shapeLayer.fillColor = UIColor.clear.cgColor
		
		shapeLayer.lineWidth = lineWidth
		shapeLayer.strokeColor = strokeColor.cgColor
		
		let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: imageView.width + padding, height: imageView.height + padding))
		
		shapeLayer.path = circlePath.cgPath
		
		return shapeLayer
	}
	
	/**
	 十六进制转颜色
	*/
	class func colorWithHexStringFunc(hexString:String) -> UIColor {
		
		var cString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
		
		if cString.hasPrefix("#") {
			cString = (cString as NSString).substring(from: 1)
		}
		
		if cString.count != 6 {
			return UIColor.gray
		}
		
		let rString = (cString as NSString).substring(to: 2)
		let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
		let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
		
		var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0
		
		Scanner(string: rString).scanHexInt32(&r)
		Scanner(string: gString).scanHexInt32(&g)
		Scanner(string: bString).scanHexInt32(&b)
		
		return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
	}

}

extension UInt32 {
	static let combiningEnclosingKeycap: UInt32 = 0x20E3
	static let variationSelector15: UInt32 = 0xFE0E
	static let variationSelector16: UInt32 = 0xFE0F
}

extension String {
	public func containsEmojiFunc() -> Bool {
//		let codepoints = self.unicodeScalars.map { $0.value }
//		
//		if let first = codepoints.first, let last = codepoints.last {
//			let isKeycapEmoji = last == .combiningEnclosingKeycap && codepoints.contains(.variationSelector16)
//			let isEmoji = CodePointSet.contains(first) && last != .variationSelector15
//			
//			return isKeycapEmoji || isEmoji
//		} else {
			return false
//		}
	}
}

/**
 模型操作类，实现Codable协议
*/
class CodableTools {
	
	class func encodeFunc<T:Codable>(models:T, forKey: String) -> Bool {
		if let encoded = try? JSONEncoder().encode(models) {
			NSKeyedArchiver.archiveRootObject(encoded, toFile: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as NSString).appendingPathComponent(forKey))
			return true
		}
		
		return false
	}

	class func decodeFunc<T:Codable>(type:T.Type, decodeKey:String)  -> [T]? {
		
		if let decode = NSKeyedUnarchiver.unarchiveObject(withFile: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as NSString).appendingPathComponent(decodeKey)) {
			if let data = try? JSONDecoder().decode([T].self, from: decode as! Data) {
				return data
			}
		}
		
		return nil
	}
}
