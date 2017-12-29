//
//  AppGroupDataManager.swift
//  Monkey
//
//  Created by 王广威 on 2017/12/29.
//  Copyright © 2017年 Monkey Squad. All rights reserved.
//

import Foundation

class AppGroupDataManager: NSObject {
	
	private static let defaultManager: AppGroupDataManager = {
		let dataManager = AppGroupDataManager()
		
		return dataManager
	}()
	
	open static let appGroupUserDefaults: UserDefaults? = {
		let appGroupUserDefaults = UserDefaults.init(suiteName: AppGroupDataManager.identifier)
		
		return appGroupUserDefaults
	}()
	
	static let identifier: String = "group.monkey.ios"
	static let containerUrl: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupDataManager.identifier)
	
	func write(_ data: String, to fileName: String) -> Bool {
		guard let containerUrl = AppGroupDataManager.containerUrl else {
			return false
		}
		let filePath = containerUrl.appendingPathComponent(fileName)
		
		var success = true
		
		do {
			try data.write(to: filePath, atomically: true, encoding: .utf8)
		} catch {
			success = false
		}
		
		return success
	}
}
