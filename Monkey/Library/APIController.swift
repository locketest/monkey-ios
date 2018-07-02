//
//  APIController.swift
//  Monkey
//
//  Created by Isaiah Turner on 2/15/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import RealmSwift

class APIController: NSObject {
    static let shared = APIController()
	private override init() {}
	
    var currentUser: RealmUser? {
		return UserManager.shared.currentUser
    }
    
    var currentExperiment: RealmExperiment? {
		return UserManager.shared.currentExperiment
    }
    
    static var authorization: String? {
        get {
            return UserDefaults.standard.string(forKey: "authorization")
        }
        set(auth) {
            UserDefaults.standard.set(auth, forKey: "authorization")
			UserDefaults.standard.synchronize()
        }
    }
	
	static var user_id: String? {
		get {
			return UserDefaults.standard.string(forKey: "user_id")
		}
		set(user_id) {
			UserDefaults.standard.set(user_id, forKey: "user_id")
			UserDefaults.standard.synchronize()
		}
	}
}
