//
//  RealmChannel.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/17/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Alamofire
import RealmSwift
import ObjectMapper

class RealmChannel: MonkeyModel {
	
	override class var type: String {
		return ApiType.Channels.rawValue
	}
	override static func primaryKey() -> String {
		return "channel_id"
	}
    
    dynamic var channel_id: String!
    /// The channel title.
    dynamic var title: String?
    /// The channel subtitle such as "302 online now"
    dynamic var subtitle: String?
	/// icon for this channel
	dynamic var icon: String?
    /// text, gif, or drawing
    dynamic var emoji: String?
    /// How many people are online in the channel.
	dynamic var users_online: Int = 0
    /// How many people are online in the channel.
	dynamic var is_active: Bool = false
	/// did select this channel
	dynamic var is_selected: Bool = false
    /// Used to sort the channels.
    dynamic var updated_at: Date?
    /// The date the channel was created.
    dynamic var created_at: Date?
	
	required convenience init?(map: Map) {
		if map["id"].currentValue == nil {
			return nil
		}
		self.init()
	}
}

extension RealmChannel {
	/**
	Retrieve a set of items from the API and update/add that data to Realm.
	
	- parameter parameters: Key value parameters to use with Alamofire
	- parameter completion: Called after the request finishes and the data is syced with Realm (or on error).
	- parameter error: The error encountered.
	- parameter items: The items retrieved.
	- returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	*/
	@discardableResult class func fetchAll<T: Object>(parameters: [String: Any] = [:], completion operationCompletionHandler: @escaping JSONAPIOperationCompletionHandlerWithFlag<T>) -> JSONAPIRequest? {
		
		return JSONAPIRequest(url: RealmChannel.common_request_path, parameters: parameters as Parameters, options: [
			.header("Authorization", UserManager.authorization),
			]).addCompletionHandler({ result in
				switch result {
				case .error(let error):
					return operationCompletionHandler(.error(error),false)
				case .success(let jsonAPIDocument):
					let channel_version = (jsonAPIDocument.json["version"] as? NSNumber ?? NSNumber.init(value: 0)).doubleValue
					var newChannelVersion = false
					let lastVersion = UserDefaults.standard.double(forKey: "LAST_CHANNEL_VERSION")
					
					if  channel_version > 0,
						lastVersion != 0,
						channel_version != lastVersion{
						newChannelVersion = true
						UserDefaults.standard.set(channel_version, forKey: "LAST_CHANNEL_VERSION")
					}
					RealmDataController.shared.apply(jsonAPIDocument) { result in
						switch result {
						case .error(let error):
							return operationCompletionHandler(.error(error),false)
						case .success(let documentObjects):
							operationCompletionHandler(.success(documentObjects as? [T] ?? [T]()), newChannelVersion)
						}
					}
				}
			})
	}
}

