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
    
    /// Currently signed in user
    var currentUser: RealmUser? {
        // All signed in users set user_id in UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            return nil
        }
        let threadSafeRealm = try? Realm()
        return threadSafeRealm?.object(ofType: RealmUser.self, forPrimaryKey: userId)
    }
    
    var currentExperiment: RealmExperiment? {
        let threadSafeRealm = try? Realm()
        // Experiement IDs directly corolate to app versions
        return threadSafeRealm?.object(ofType: RealmExperiment.self, forPrimaryKey: Environment.appVersion)
    }
    
    static var authorization: String? {
        get {
            return UserDefaults.standard.string(forKey: "authorization")
        }
        set(auth) {
            UserDefaults.standard.set(auth, forKey: "authorization")
			UserDefaults.standard.synchronize()
			Achievements.shared.group_authorization = auth;
        }
    }
}
