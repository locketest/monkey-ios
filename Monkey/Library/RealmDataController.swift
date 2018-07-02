//
//  RealmDataController.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/9/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift
import Foundation
import ObjectMapper

/// NOTE: All RealmDataController functions work on a background thread but call back on the main thread explicitly
class RealmDataController {
	
	static let shared = RealmDataController()
	private init() {}
	
	private let realmObjectClasses: [MonkeyRealmObject.Type] = [
		RealmExperiment.self,
		RealmUser.self,
		RealmChannel.self,
		RealmMessage.self,
		RealmFriendship.self,
		RealmInstagramPhoto.self,
		RealmInstagramAccount.self,
		RealmMatchInfo.self,
		RealmMatchEvent.self,
		Authorization.self,
		DeepLinkInfo.self,
	]
	
	/**
	Configuration of Realm and migration from old schema.
	*/
	private func configureRealm() {
		var defaultConfig: Realm.Configuration!
		if let syncUser = SyncUser.current {
			defaultConfig = syncUser.configuration(realmURL: URL.init(string: Environment.MonkeySyncRealmUrl), fullSynchronization: true)
			defaultConfig.objectTypes = self.realmObjectClasses
		}else {
			defaultConfig = Realm.Configuration(
				schemaVersion: 22,
				migrationBlock: { migration, oldSchemaVersion in
					if oldSchemaVersion < 1 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
					}
					if oldSchemaVersion < 2 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
					}
					if oldSchemaVersion < 3 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmUser.username' has been added.
						- Property 'RealmUser.updated_at' has been added.
						- Property 'RealmUser.created_at' has been added.
						*/
					}
					if oldSchemaVersion < 4 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmUser.seconds_in_app' has been added
						*/
					}
					if oldSchemaVersion < 5 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmUser.channels' has been added
						*/
					}
					if oldSchemaVersion < 6 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmRelationship.last_message_read_at' has been added.
						- Property 'RealmUser.last_online_at' has been added.
						*/
					}
					if oldSchemaVersion < 7 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmRelationship.user_is_typing' has been added.
						- Property 'RealmRelationship.is_typing' has been added.
						*/
					}
					if oldSchemaVersion < 8 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmUser.bananas' has been added.
						*/
					}
					if oldSchemaVersion < 9 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmMessages.uuid' has been added
						*/
					}
					if oldSchemaVersion < 10 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmExperiment.instagram_login_url' has been added
						- Property 'RealmUser.instagram_account' has been added
						- Property 'RealmUser.location' has been added
						*/
					}
					if oldSchemaVersion < 11 {
						// Something to do!
						/*
						RealmRelationship -> RealmFriendship
						RealmRelationship.self, // reference has to be kept until (https://github.com/realm/realm-cocoa/issues/3686) is fixed
						*/
						migration.deleteData(forType: "RealmRelationship")
					}
					if oldSchemaVersion < 12 {
						// Something to do!
						/*
						- Property 'RealmUser.is_banned' has been added
						*/
					}
					if oldSchemaVersion < 13 {
						// Something to do!
						/*
						- Property 'RealmExperiment.monkeychat_link' has been added
						*/
					}
					if oldSchemaVersion < 14 {
						// Something to do!
						/*
						- Property 'RealmCall.user' has been added
						*/
					}
					if oldSchemaVersion < 15 {
						// Something to do!
						/*
						- Property 'RealmCall.match_mode' has been added
						*/
					}
					if oldSchemaVersion < 16 {
						// Something to do!
						/*
						- Property 'RealmCall.request_id' has been added
						*/
					}
					if oldSchemaVersion < 17 {
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
					}
					if oldSchemaVersion < 18 {
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
					}
					if oldSchemaVersion < 19 {
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
					}
					if oldSchemaVersion < 20 {
						// Something to do!
						/*
						- Class 'RealmTag' has been deleted
						- Class 'RealmPhoneAuth' has been deleted
						- Class 'RealmBlock' has been deleted
						- Class 'RealmMatchedUser' has been deleted
						
						- Property 'RealmUser.tag' has been deleted
						*/
					}
					if oldSchemaVersion < 21 {
						// Nothing to do!
						// Realm will automatically detect new properties and removed properties
						// And will update the schema on disk automatically
						/*
						- Property 'RealmUser.delete_at' has been added
						- Property 'RealmCall.notify_accept' has been added
						- Property 'RealmVideoCall.notify_accept' has been added
						*/
					}
					if oldSchemaVersion < 22 {
						// Something to do!
						/*
						- Class 'RealmCall' has been deleted
						- Class 'RealmVideoCall' has been deleted
						- Class 'Authorization' has been deleted
						- Class 'DeepLinkInfo' has been deleted
						*/
					}
			}, objectTypes: self.realmObjectClasses)
		}
		
		Realm.Configuration.defaultConfiguration = defaultConfig
	}
	
	/// A Realm instance confined to the main thread
	var mainRealm: Realm?
	private let backgroundQueue = DispatchQueue(label: "cool.monkey.ios.realm-data-controller-background-queue")
	/**
	Called once durring app start. Continues to try and create RealmDataController.realm and calls completion after that succeeds.
	*/
	func setupRealm(completion: @escaping (_ error: APIError?) -> Void) {
//		self.logInToSyncServer { (syncUser) in
			// get main Realm
			DispatchQueue.main.async {
				guard self.mainRealm == nil else {
					completion(nil)
					return
				}
				
				self.configureRealm()
				
				do {
					self.mainRealm = try Realm()
					self.migrateFromUserDefaults(completion: completion)
				} catch let error {
					self.mainRealm = nil
					let apiError = RealmDataController.parse(error: error)
					apiError.log()
					completion(apiError)
				}
			}
//		}
	}
	
	/**
	Clears the entire Realm store.
	Used for resetting the app when user signs out so data doesn't persist from another account.
	*/
	func deleteAllData(completion: @escaping (_ error: APIError?) -> Void) {
		// delete all data
		DispatchQueue.main.async {
			// 还未初始化
			guard let mainRealm = self.mainRealm else {
				return completion(.realmNotInitialized)
			}
			
			do {
				try mainRealm.write {
					mainRealm.deleteAll()
				}
				completion(nil)
			} catch(let error) {
				print("Error: ", error)
				completion(.unableToSave)
			}
			SyncUser.current?.logOut()
		}
	}
	
	/**
	Attempts to load user information from UserDefaults and creates a new Realm user.
	*/
	func migrateFromUserDefaults(completion: @escaping (_ error: APIError?) -> Void) {
		
		// 如果
		guard let mainRealm = self.mainRealm else {
			completion(.realmNotInitialized)
			return
		}
		
		// 如果已经更新过
		if let authorization = UserManager.shared.currentAuthorization {
			UserDefaults.standard.set(authorization.auth_token, forKey: "authorization")
			UserDefaults.standard.set(authorization.user_id, forKey: "user_id")
		}else if let authorizationToken = APIController.authorization, let user_id = APIController.user_id {
			// transform old data to model
			var token = authorizationToken
			let prefix = Authorization.token_prefix
			if token.hasPrefix(prefix) {
				let startIndex = token.index(token.startIndex, offsetBy: prefix.count)
				token = token.substring(from: startIndex)
			}
			
			let authorizationJson = [
				"data": [
					"id": user_id,
					"type": Authorization.type,
					"attributes": [
						"token": token,
					],
					"relationships": [
						"user": [
							"data": [
								"id": user_id,
								"type": RealmUser.type,
							]
						]
					]
				]
			]
			if let authorization = Mapper<Authorization>().map(JSON: authorizationJson) {
				try! mainRealm.write {
					mainRealm.add(authorization, update: true)
					// remove old data
//					APIController.user_id = nil
//					APIController.authorization = nil
//					UserDefaults.standard.removeObject(forKey: "age")
//					UserDefaults.standard.removeObject(forKey: "gender")
//					UserDefaults.standard.removeObject(forKey: "apns_token")
//					UserDefaults.standard.removeObject(forKey: "show_gender")
//					UserDefaults.standard.removeObject(forKey: "snapchat_username")
				}
			}
		}
		
		completion(nil)
	}
	
	/**
	Signs a user into the sync server.
	
	The compiled implementation of this function is changed by a build flag "REALM_SYNC" which also causes serveral changes in the Environment.swift file.
	*/
	private func logInToSyncServer(callback: @escaping () -> Void) {
		print("Signing into Sync Server")
		if let syncUser = SyncUser.current {
			print("User already sign into Sync Server.", syncUser.debugDescription)
			callback()
		}else {
			// This async login request will happen without any indication on the frontent. Ideally, we get a UIActivityindicator somehow.
			SyncUser.logIn(with: SyncCredentials.nickname("wei", isAdmin: true), server: URL(string: Environment.RealmSyncServerUrl)!, onCompletion: { (syncUser, error) in
				print("Attemped to sign into Sync Server.", syncUser.debugDescription, error.debugDescription)
				callback()
			})
		}
	}
	
	/**
	Converts a Error object thrown by realm into an APIError with messages than can be displayed to the user.
	*/
	class func parse(error: Error) -> APIError {
		switch error {
		case Realm.Error.incompatibleLockFile:
			return APIError(code: "-1", status: nil, message: "Incompatible lock file.", internalMessage: "Realm Error: \(error.localizedDescription)")
		default:
			return APIError(code: "-1", status: nil, message: "Unknown local data storage issue.", internalMessage: "Realm Error: \(error.localizedDescription)")
		}
	}
	
	/// Parses a JSONAPIDocument and updates the Realm with it's data. This includes object creation, modification, and deletion.
	///
	/// - Parameters:
	///   - jsonAPIDocument: The response from a JSON API request.
	///   - completion: Called when all objects have been parsed and passed all updated and created objects. Always called from the main thread.
	func apply(_ jsonAPIDocument: JSONAPIDocument, completion: @escaping (_ jsonAPIResult: JSONAPIResult<[Object]>) -> Void) {
		// Run everything on a background thread since sometimes we have a ton of items to parse at once.
		self.backgroundQueue.async {
			guard let realm = try? Realm() else {
				return DispatchQueue.main.async {
					completion(.error(.realmNotInitialized))
				}
			}
			do {
				var newObjects = [Object]()
				try realm.write() {
					// If items were deleted by a delete request (usually 1 to 1 relationships), delete them from the Realm.
					try jsonAPIDocument.deleted?.forEach {
						try self.deleteResourceWithResourceIdentifier($0)
					}
					
					// Parse the response as a single resource
					try jsonAPIDocument.dataResource.then {
						if let jsonAPIObject = try self.parseJSONAPIResource($0) {
							newObjects.append(jsonAPIObject)
						}
					}
					
					// If the above failed, parse the response as an array of resources
					try jsonAPIDocument.dataResourceCollection?.forEach {
						if let jsonAPIObject = try self.parseJSONAPIResource($0) {
							newObjects.append(jsonAPIObject)
						}
					}
					
					// If some items were included, lets parse those too.
					try jsonAPIDocument.included?.forEach {
						try self.parseJSONAPIResource($0)
					}
				}
				
				let threadSafeNewObjects = newObjects.map {
					ThreadSafeReference(to: $0)
				}
				
				DispatchQueue.main.async {
					var newObjects = [Object]()
					threadSafeNewObjects.forEach { (threadSafeReference) in
						if let newObject = self.mainRealm?.resolve(threadSafeReference) {
							newObjects.append(newObject)
						}
					}
					completion(.success(newObjects))
				}
			} catch let error {
				print("Error: ", error)
				DispatchQueue.main.async {
					completion(.error(error as? APIError ?? .unableToSave))
				}
			}
		}
	}
	
	/// Inserts the provided resource into realm or updates the existing Realm object with the resource's ID if an object is already in the realm.
	///
	/// - warning: This method may only be called during a write transaction.
	/// - Parameters:
	///   - jsonAPIResource: The resource to insert or update the realm with.
	/// - Returns: The new or updated Realm object.
	/// - Throws: An Error of type `APIError` when parsing fails.
	@discardableResult private func parseJSONAPIResource(_ jsonAPIResource: JSONAPIResource) throws -> MonkeyRealmObject? {
		guard let resourceRealmObjectClass = try self.classForResourceIdentifier(jsonAPIResource) else {
			return nil
		}
		guard let primaryKey = resourceRealmObjectClass.primaryKey() else {
			throw APIError(code: "-1", status: nil, message: "All JSONAPIObjects must have a primary key.")
		}
		guard let resourceId = jsonAPIResource.id else {
			throw APIError(code: "-1", status: nil, message: "Resource missing an ID.")
		}
		
		var value: [String: Any] = jsonAPIResource.attributes ?? [:]
		
		// 如果是新的好友，设置 last_message_at 为 created_at
		if resourceRealmObjectClass.type == ApiType.Friendships.rawValue {
			if value["last_message_at"] == nil, let created_at = value["created_at"] {
				value["last_message_at"] = created_at
			}
		}
		
		try jsonAPIResource.relationships?.forEach { (relationshipKey, relationshipValue) in
			let properties = resourceRealmObjectClass.sharedSchema()?.properties
			
			guard properties?.contains(where: { (property) -> Bool in
				property.name == relationshipKey
			}) == true else {
				return
			}
			
			if relationshipValue is NSNull {
				value[relationshipKey] = NSNull()
				return
			}
			guard let relationship = relationshipValue as? JSONAPIDocument else {
				throw APIError(code: "-1", status: nil, message: "Unrecognized data type for relationship.")
			}
			if let dataResource = relationship.dataResource {
				value[relationshipKey] = try self.getOrCreateRealmObjectForResourceIdentifier(dataResource)
			} else if let dataResourceCollection = relationship.dataResourceCollection, dataResourceCollection.count > 0 {
				value[relationshipKey] = try dataResourceCollection.map { try self.getOrCreateRealmObjectForResourceIdentifier($0) }
			} else if relationship.isResourceNull {
				value[relationshipKey] = NSNull()
			}
		}
		// Create an object and then use KVC to set the properties since KVC will convert strings to dates.
		let realm = try Realm()
		let object = realm.object(ofType: resourceRealmObjectClass, forPrimaryKey: resourceId) ?? realm.create(resourceRealmObjectClass, value: [
			primaryKey: resourceId,
			])
		object.setValuesForKeys(value)
		return object as? MonkeyRealmObject
	}
	/**
	Deletes an object from the Realm after looking it up by it's resource identifier.
	
	If an object with the provided resource identifier does not exist, this will create it and then delete it all at once (essentially, doing nothing.)
	
	- warning: This method may only be called during a write transaction.
	
	- parameter object: The identifier of the object to be deleted.
	*/
	private func deleteResourceWithResourceIdentifier(_ resourceIdentifier: JSONAPIResourceIdentifier) throws {
		let realm = try Realm()
		if let jsonAPIObject = try getOrCreateRealmObjectForResourceIdentifier(resourceIdentifier) {
			realm.delete(jsonAPIObject)
		}
	}
	/// Returns the Realm JSONAPIObject class for the provided resource identifier.
	///
	/// - Parameter resourceIdentifier: The resource identifier to find a class for.
	/// - Returns: The class for the provided resource identifier
	/// - Throws: An Error of type `APIError` when a class can not be found for the provided resource identifier
	private func classForResourceIdentifier(_ resourceIdentifier: JSONAPIResourceIdentifier) throws -> MonkeyRealmObject.Type? {
		guard let resourceType = resourceIdentifier.type else {
			APIError(message: "Error: Resource missing type attribute.").log()
			return nil
		}
		guard let realmObjectClass = self.realmObjectClasses.first(where: { $0.type == resourceType }) else {
			APIError(message: "Error: No realm object class exists for the provided type.").log()
			return nil
		}
		
		return realmObjectClass
	}
	
	/// Retrieves an object from the realm based on a resource identifier (and creates the object if one does not exist).
	///
	/// - Parameters:
	///   - resourceIdentifier: The resource identifier of the object to get from the realm.
	/// - Returns: The new (or found) JSONAPIObject for the provided resource identifier.
	/// - Throws: An Error of type `APIError` when the resouce identifier is improperly formatted.
	private func getOrCreateRealmObjectForResourceIdentifier(_ resourceIdentifier: JSONAPIResourceIdentifier) throws -> MonkeyRealmObject? {
		guard let resourceRealmObjectClass = try self.classForResourceIdentifier(resourceIdentifier) else {
			APIError(message: "A model does not conform to JSONAPIObject.").log()
			return nil
		}
		guard let primaryKeyString = resourceRealmObjectClass.sharedSchema()?.primaryKeyProperty?.name else {
			APIError(message: "A model is missing a primary key.").log()
			return nil
		}
		guard let relationshipId = resourceIdentifier.id else {
			APIError(message: "A relationship is missing an id.").log()
			return nil
		}
		
		let realm = try Realm()
		let object = realm.create(resourceRealmObjectClass, value: [
			primaryKeyString: relationshipId,
			], update: true)
		return object as? MonkeyRealmObject
	}
	
	func parseDate(_ dateString: String) -> Date {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		if dateString.hasSuffix("Z") {
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		}else {
			dateFormatter.dateFormat = "E MMM dd yyyy HH:mm:ss Zz"
		}
		let date = dateFormatter.date(from: dateString) ?? Date()
		return date
	}
}
