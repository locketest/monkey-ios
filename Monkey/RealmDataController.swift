//
//  RealmDataController.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/9/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//
import RealmSwift
import Foundation

/// NOTE: All RealmDataController functions work on a background thread but call back on the main thread explicitly
class RealmDataController: NSObject {

    static let shared = RealmDataController()
    private override init() {}
    /// A Realm instance confined to the main thread
    private var mainRealm: Realm?
    let backgroundQueue = DispatchQueue(label: "cool.monkey.ios.realm-data-controller-background-queue")
    let realmObjectClasses:[JSONAPIObjectProtocol.Type] = [
        RealmExperiment.self,
        RealmMessage.self,
        RealmUser.self,
        RealmFriendship.self,
        RealmRelationship.self, // reference has to be kept until (https://github.com/realm/realm-cocoa/issues/3686) is fixed
        RealmTag.self,
        RealmChannel.self,
        RealmCall.self,
        RealmInstagramAccount.self,
        RealmInstagramPhoto.self,
        RealmBlock.self,
        ]

    /**
     Signs a user into the sync server.

     The compiled implementation of this function is changed by a build flag "REALM_SYNC" which also causes serveral changes in the Environment.swift file.
     */
    private func logInToSyncServer(authorization: String, callback: @escaping (_ syncUser: SyncUser?) -> Void) {
        DispatchQueue.main.async {
            // Don't include sync code in production app to decrease chances of finding during reverse engineering
            #if !REALM_SYNC
                return callback(nil)
            #else
                guard let authorization = APIController.authorization else {
                    return callback(nil)
                }
                guard let server = URL(string: Environment.realmSyncServerURL) else {
                    return callback(nil)
                }
                guard SyncUser.current == nil else {
                    return callback(SyncUser.current)
                }
                print("Signing into Sync Server")
                // This async login request will happen without any indication on the frontent. Ideally, we get a UIActivityindicator somehow.
                SyncUser.logIn(with: .init(customToken: authorization, provider: Provider(Environment.realmSyncProvider)), server: server) { (user, error) in
                    print("Attemped to sign into Sync Server.", user.debugDescription, error.debugDescription)
                    DispatchQueue.main.async {
                        callback(user)
                    }
                }
            #endif
        }
    }

    /**
     Called once durring app start. Continues to try and create RealmDataController.realm and calls completion after that succeeds.
     */

    func setupRealm(presentingErrorsOnViewController viewController: UIViewController, completion: @escaping () -> Void) {
        guard let objectTypes = self.realmObjectClasses as? [Object.Type] else {
            print("Error: failed to set up Realm because could not caste as Object.type")
            return
        }

        let config = Realm.Configuration(
            syncConfiguration: nil,
            schemaVersion: 16,
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
                    // RealmRelationship -> RealmFriendship
                    // migration.deleteData(forType: "RealmRelationship")
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
					migration.deleteData(forType: "RealmRelationship")
				}

        }, objectTypes: objectTypes)

        Realm.Configuration.defaultConfiguration = config
        do {
            self.mainRealm = try Realm()
            completion()
        } catch let error {
            self.mainRealm = nil
            let apiError = RealmDataController.parse(error: error)
            let alertController = apiError.toAlert(onRetry: { (UIAlertAction) in
                self.setupRealm(presentingErrorsOnViewController: viewController, completion: completion)
            })

            viewController.present(alertController, animated: true, completion: nil)
            apiError.log()
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

    /**
     Attempts to load user information from UserDefaults and creates a new Realm user.
     */
    func migrateCurrentUserFromUserDefaults(completion: @escaping (_ error: APIError?) -> Void) {
        DispatchQueue.main.async {
            guard let realm = self.mainRealm else {
                completion(.realmNotInitialized)
                return
            }
            do {
                let user = RealmUser()
                user.gender = UserDefaults.standard.string(forKey: "gender")
                user.show_gender = UserDefaults.standard.string(forKey: "show_gender")
                user.age.value = UserDefaults.standard.value(forKey: "age") as? Int
                user.snapchat_username = UserDefaults.standard.string(forKey: "snapchat_username")
                user.user_id = UserDefaults.standard.string(forKey: "user_id")
                try realm.write() {
                    realm.add(user)
                    UserDefaults.standard.removeObject(forKey: "age")
                    UserDefaults.standard.removeObject(forKey: "gender")
                    UserDefaults.standard.removeObject(forKey: "show_gender")
                    UserDefaults.standard.removeObject(forKey: "snapchat_username")
                }
                completion(nil)
            } catch(let error) {
                print("Error: ", error)
                completion(.unableToSave)
            }
        }
    }
    /**
     Clears the entire Realm store.
     Used for resetting the app when user signs out so data doesn't persist from another account.
     */
    func deleteAllData(completion: @escaping (_ error: APIError?) -> Void) {
        DispatchQueue.main.async {
            guard let realm = self.mainRealm else {
                return completion(.realmNotInitialized)
            }
            do {
                try realm.write {
                    realm.deleteAll()
                    SyncUser.current?.logOut()
                }
                completion(nil)
            } catch(let error) {
                print("Error: ", error)
                completion(.unableToSave)
            }
        }
    }
    /// Parses a JSONAPIDocument and updates the Realm with it's data. This includes object creation, modification, and deletion.
    ///
    /// - Parameters:
    ///   - jsonAPIDocument: The response from a JSON API request.
    ///   - completion: Called when all objects have been parsed and passed all updated and created objects. Always called from the main thread.
    func apply(_ jsonAPIDocument: JSONAPIDocument, completion: @escaping (_ jsonAPIResult: JSONAPIResult<[JSONAPIObject]>) -> Void) {
        // Run everything on a background thread since sometimes we have a ton of items to parse at once.
        self.backgroundQueue.async {
            guard let realm = try? Realm() else {
                return DispatchQueue.main.async {
                    completion(.error(.realmNotInitialized))
                }
            }
            do {
                var newObjects = [JSONAPIObject]()
                try realm.write() {
                    // If items were deleted by a delete request (usually 1 to 1 relationships), delete them from the Realm.
                    try jsonAPIDocument.deleted?.forEach { try self.deleteResourceWithResourceIdentifier($0) }
                    // Parse the response as a single resource
                    try jsonAPIDocument.dataResource.then { newObjects.append(try self.parseJSONAPIResource($0)) }
                    // If the above failed, parse the response as an array of resources
                    try jsonAPIDocument.dataResourceCollection?.forEach { newObjects.append(try self.parseJSONAPIResource($0)) }
                    // If some items were included, lets parse those too.
                    try jsonAPIDocument.included?.forEach {
                        try self.parseJSONAPIResource($0)
                    }
                }
                let threadSafeNewObjects = newObjects.map { ThreadSafeReference(to: $0) }
                DispatchQueue.main.async {
                    var newObjects = [JSONAPIObject]()
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
    func apply(_ jsonAPIDocument: JSONAPIDocument, toObject object: JSONAPIObject, forRelationship relationshipKey: String, completion: @escaping (_ jsonAPIResult: JSONAPIResult<[JSONAPIObject]>) -> Void) {
        let threadSafeReferenceToObject = ThreadSafeReference(to: object)
        self.apply(jsonAPIDocument) { (result) in
            switch result {
            case .error(let error):
                return completion(.error(error))
            case .success(let newObjects):
                self.backgroundQueue.async {
                    guard let realm = try? Realm() else {
                        return DispatchQueue.main.async {
                            completion(.error(.realmNotInitialized))
                        }
                    }
                    do {
                        let threadSafeObject = realm.resolve(threadSafeReferenceToObject)
                        try realm.write() {
                            threadSafeObject?.setValue(newObjects.first, forKey: relationshipKey)
                        }
                    } catch let error {
                        print("Error: ", error)
                        completion(.error(.unableToSave))
                    }
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
    @discardableResult private func parseJSONAPIResource(_ jsonAPIResource:JSONAPIResource) throws -> JSONAPIObject {
        let realm = try Realm()
        let resourceRealmObjectClass = try self.classForResourceIdentifier(jsonAPIResource)
        guard let primaryKey = resourceRealmObjectClass.primaryKey() else {
            throw APIError(code: "-1", status: nil, message: "All JSONAPIObjects must have a primary key.")
        }
        guard let resourceId = jsonAPIResource.id else {
            throw APIError(code: "-1", status: nil, message: "Resource missing an ID.")
        }

        var value:[String:Any] = jsonAPIResource.attributes ?? [:]

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
            } else if let dataResourceCollection = relationship.dataResourceCollection {
                value[relationshipKey] = try dataResourceCollection.map { try self.getOrCreateRealmObjectForResourceIdentifier($0) }
            } else if relationship.isResourceNull {
                value[relationshipKey] = NSNull()
            }
        }
        // Create an object and then use KVC to set the properties since KVC will convert strings to dates.
        let object = realm.object(ofType: resourceRealmObjectClass, forPrimaryKey: resourceId) ?? realm.create(resourceRealmObjectClass, value: [
            primaryKey: resourceId,
            ])
        object.setValuesForKeys(value)
        return object
    }
    /**
     Deletes an object from the Realm after looking it up by it's resource identifier.

     If an object with the provided resource identifier does not exist, this will create it and then delete it all at once (essentially, doing nothing.)

     - warning: This method may only be called during a write transaction.

     - parameter object: The identifier of the object to be deleted.
     */
    private func deleteResourceWithResourceIdentifier(_ resourceIdentifier: JSONAPIResourceIdentifier) throws {
        let realm = try Realm()
        let jsonAPIObject = try getOrCreateRealmObjectForResourceIdentifier(resourceIdentifier)
        realm.delete(jsonAPIObject)
    }
    /// Returns the Realm JSONAPIObject class for the provided resource identifier.
    ///
    /// - Parameter resourceIdentifier: The resource identifier to find a class for.
    /// - Returns: The class for the provided resource identifier
    /// - Throws: An Error of type `APIError` when a class can not be found for the provided resource identifier
    private func classForResourceIdentifier(_ resourceIdentifier: JSONAPIResourceIdentifier) throws -> JSONAPIObject.Type {
        guard let resourceType = resourceIdentifier.type else {
            throw APIError(message: "Error: Resource missing type attribute.")
        }
        guard let resourceClass = self.realmObjectClasses.first(where: { $0.type == resourceType }) else {
            throw APIError(message: "Error: No realm object class exists for the provided type.")
        }
        guard let resourceRealmObjectClass = resourceClass as? JSONAPIObject.Type else {
            throw APIError(message: "Error: A class conforms to JSONAPIObjectProtocol but does not inherit from JSONAPIObject.")
        }
        return resourceRealmObjectClass
    }

    /// Retrieves an object from the realm based on a resource identifier (and creates the object if one does not exist).
    ///
    /// - Parameters:
    ///   - resourceIdentifier: The resource identifier of the object to get from the realm.
    /// - Returns: The new (or found) JSONAPIObject for the provided resource identifier.
    /// - Throws: An Error of type `APIError` when the resouce identifier is improperly formatted.
    private func getOrCreateRealmObjectForResourceIdentifier(_ resourceIdentifier: JSONAPIResourceIdentifier) throws -> JSONAPIObject {
        let realm = try Realm()
        guard let protocolForRelationship = self.realmObjectClasses.first(where: { $0.type == resourceIdentifier.type }) else {
            throw APIError(message: "A model was not found for the given relationship, please add the model to RealmDataController.")
        }
        guard let classForRelationship = protocolForRelationship as? JSONAPIObject.Type else {
            throw APIError(message: "A model does not conform to JSONAPIObject.")
        }
        guard let primaryKeyString = classForRelationship.sharedSchema()?.primaryKeyProperty?.name else {
            throw APIError(message: "A model is missing a primary key.")
        }
        guard let relationshipId = resourceIdentifier.id else {
            throw APIError(message: "A relationship is missing an id.")
        }
        return realm.create(classForRelationship, value: [
            primaryKeyString: relationshipId,
            ], update: true)
    }
}
