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

class APIController {
    
    static let kCodeVerifyJustNow = "kCodeVerifyJustNow"
    static let kNewAccountCodeVerify = "kNewAccountCodeVerify"
    static let kSignAsLogin = "kSignAsLogin"
    static let kNewAccountSignUpFinish = "kNewAccountSignUpFinish"

    static let shared = APIController()
    private init() {}
    
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
        return threadSafeRealm?.object(ofType: RealmExperiment.self, forPrimaryKey: APIController.shared.appVersion)
    }
    
    var languageString : String {
        return NSLocale.preferredLanguages.first ?? ""
    }
    
    var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0" // Use zeros instead of crashing. This should not happen.
    }
    /// The current version string of the API to be used in URLs.
    private static let apiVersion = "v1.0"
    /// The current version string of the API to be used in URLs.
    let apiVersion: String = APIController.apiVersion
    
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
    class func urlTo(_ model: String) -> String {
        return "\(Environment.baseURL)/api/\(self.apiVersion)/\(model)"
    }
    class func parseDate(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: dateString) ?? Date()
    }
}

@objc protocol ModelAttributes {
    var id: String? { get set }
}
protocol Model {
    static var className: String { get }
    static var type: String { get }
    static func update(id: String,
                       attributes: Dictionary<String,Any>,
                       relationships: Dictionary<String, Model>,
                       completion: @escaping ( _ result : NSManagedObject?) -> Void)
    static func set(id: String, updatedAt date: String, callback: ((APIError?, Bool) -> Void)?)
}
