//
//  JSONAPIObject.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/24/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
typealias JSONAPIOperationCompletionHandler<T> = (_ result: JSONAPIResult<[T]>) -> Void
typealias JSONAPIOperationCompletionHandlerWithFlag<T> = (_ result: JSONAPIResult<[T]>,_ flag:Bool) -> Void
class JSONAPIObject: Object {
    /**
     Updates the current item with the latest data available in the server.

     - parameter completion: Called when the request completes.
     - parameter error: The error encountered while trying to reload data.
     - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
     */
    @discardableResult func reload(completion: @escaping (_ error: APIError?) -> Void) -> JSONAPIRequest? {
        guard let primaryKeyProperty = self.objectSchema.primaryKeyProperty else {
            completion(APIError(code: "-1", status: nil, message: "Cannot reload an item without a primary key."))
            return nil
        }
        guard let id = self[primaryKeyProperty.name] else {
            completion(APIError(code: "-1", status: nil, message: "To refresh, an item must have an ID"))
            return nil
        }

        guard let subfix = (type(of: self) as? JSONAPIObjectProtocol.Type)?.requst_subfix else {
            completion(.notJSONAPIObjectProtocol)
            return nil
        }
		
		guard let api_version = (type(of: self) as? JSONAPIObjectProtocol.Type)?.api_version else {
			completion(.notJSONAPIObjectProtocol)
			return nil
		}
		
        return JSONAPIRequest(url: "\(Environment.baseURL)/api/\(api_version)/\(subfix)/\(id)", options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler { (response) in
                switch response {
                case .error(let error):
                    return completion(error)
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument) { (result) in
                        switch result {
                        case .error(let error):
                            return completion(error)
                        case .success(_):
                            return completion(nil)
                        }
                    }
                }
        }
    }

    /**
     Retrieve an item from the API and update/add that data to Realm.

     - parameter id: The id of the item to retrieve.
     - parameter parameters: Key value parameters to use with Alamofire
     - parameter completion: Called after the request finishes and the data is syced with Realm (or on error).
     - parameter error: The error encountered.
     - parameter item: The item retrieved.
     - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
     */
    @discardableResult class func fetch<T: JSONAPIObjectProtocol>(id: String, parameters: [String:Any] = [:], completion: @escaping (_ error: APIError?, _ item: T?) -> Void) -> JSONAPIRequest? {
        guard let subfix = (self as? JSONAPIObjectProtocol.Type)?.requst_subfix else {
            completion(.notJSONAPIObjectProtocol, nil)
            return nil
        }
		
		guard let api_version = (self as? JSONAPIObjectProtocol.Type)?.api_version else {
			completion(.notJSONAPIObjectProtocol, nil)
			return nil
		}
		
        return JSONAPIRequest(url: "\(Environment.baseURL)/api/\(api_version)/\(subfix)/\(id)", parameters: parameters as Parameters, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler { (response) in
                switch response {
                case .error(let error):
                    return completion(error, nil)
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument) { (result) in
                        switch result {
                        case .error(let error):
                            return completion(error, nil)
                        case .success(let newObjects):
                            return completion(nil, newObjects.first as? T)
                        }
                    }
                }
        }
    }

    /**
     Retrieve a set of items from the API and update/add that data to Realm.

     - parameter parameters: Key value parameters to use with Alamofire
     - parameter completion: Called after the request finishes and the data is syced with Realm (or on error).
     - parameter error: The error encountered.
     - parameter items: The items retrieved.
     - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
     */
    @discardableResult class func fetchAll<T: JSONAPIObjectProtocol>(parameters: [String:Any] = [:], completion operationCompletionHandler: @escaping JSONAPIOperationCompletionHandler<T>) -> JSONAPIRequest? {
        guard let subfix = (self as? JSONAPIObjectProtocol.Type)?.requst_subfix else {
            operationCompletionHandler(.error(.notJSONAPIObjectProtocol))
            return nil
        }
		
		guard let api_version = (self as? JSONAPIObjectProtocol.Type)?.api_version else {
			operationCompletionHandler(.error(.notJSONAPIObjectProtocol))
			return nil
		}
		
        return JSONAPIRequest(url: "\(Environment.baseURL)/api/\(api_version)/\(subfix)", parameters: parameters as Parameters, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler({ result in
                switch result {
                case .error(let error):
                    return operationCompletionHandler(.error(error))
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument) { result in
                        switch result {
                        case .error(let error):
                            return operationCompletionHandler(.error(error))
                        case .success(let documentObjects):
                            operationCompletionHandler(.success(documentObjects as? [T] ?? [T]()))
                        }
                    }
                }
            })
    }

    /**
     POSTs a new item to the API, adds the newly created item to realm, and provides it’s value.

     - parameter parameters: JSON API data to use in the body of the request.
     - parameter completion: Called after the request finishes (or on error).
     - parameter error: The error encountered.
     - parameter item: The item created.
     - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
     */
    @discardableResult class func create<T: JSONAPIObjectProtocol>(parameters: [String:Any] = [:], completion operationCompletionHandler: @escaping JSONAPIOperationCompletionHandler<T>) -> JSONAPIRequest? {
        guard let subfix = (self as? JSONAPIObjectProtocol.Type)?.requst_subfix else {
            operationCompletionHandler(.error(.notJSONAPIObjectProtocol))
            return nil
        }
		
		guard let api_version = (self as? JSONAPIObjectProtocol.Type)?.api_version else {
			operationCompletionHandler(.error(.notJSONAPIObjectProtocol))
			return nil
		}
		
        return JSONAPIRequest(url: "\(Environment.baseURL)/api/\(api_version)/\(subfix)", method:.post, parameters: parameters as Parameters, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler({ result in
                switch result {
                case .error(let error):
                    return operationCompletionHandler(.error(error))
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument) { result in
                        switch result {
                        case .error(let error):
                            return operationCompletionHandler(.error(error))
                        case .success(let documentObjects):
                            operationCompletionHandler(.success(documentObjects as? [T] ?? [T]()))
                        }
                    }
                }
            })
    }
    
    
    @discardableResult class func customURLCreate<T: JSONAPIObjectProtocol>(url:String,parameters: [String:Any] = [:], completion operationCompletionHandler: @escaping JSONAPIOperationCompletionHandler<T>) -> JSONAPIRequest? {
        
        return JSONAPIRequest(url: url, method:.post, parameters: parameters as Parameters, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler({ result in
                switch result {
                case .error(let error):
                    return operationCompletionHandler(.error(error))
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument) { result in
                        switch result {
                        case .error(let error):
                            return operationCompletionHandler(.error(error))
                        case .success(let documentObjects):
                            let doc = documentObjects as! [T]
                            operationCompletionHandler(.success(doc))
                        }
                    }
                }
            })
    }

    /// Updates a relationship.
    ///
    /// - Parameters:
    ///   - relationshipKey: The key of a relationship to delete.
    ///   - completion: Called when the update competes.
    ///   - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.

    @discardableResult func update(relationship relationshipKey: String, resourceIdentifier: JSONAPIResourceIdentifier?, completion: @escaping (_ error: APIError?) -> Void) -> JSONAPIRequest? {
        guard let primaryKeyProperty = self.objectSchema.primaryKeyProperty else {
            completion(APIError(code: "-1", status: nil, message: "Cannot reload an item without a primary key."))
            return nil
        }
		
        guard let id = self[primaryKeyProperty.name] else {
            completion(APIError(code: "-1", status: nil, message: "To refresh, an item must have an ID"))
            return nil
        }

        guard let subfix = (type(of: self) as? JSONAPIObjectProtocol.Type)?.requst_subfix else {
            completion(.notJSONAPIObjectProtocol)
            return nil
        }
		
		guard let api_version = (type(of: self) as? JSONAPIObjectProtocol.Type)?.api_version else {
			completion(.notJSONAPIObjectProtocol)
			return nil
		}

        return JSONAPIRequest(url: "\(Environment.baseURL)/api/\(api_version)/\(subfix)/\(id)/relationships/\(relationshipKey)", method: .patch, parameters: JSONAPIDocument(data: resourceIdentifier).json, options: [
                .header("Authorization", APIController.authorization),
                ]).addCompletionHandler { (response) in
                    switch response {
                case .error(let error):
                    return completion(error)
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument, toObject: self, forRelationship: relationshipKey) { result in
                        switch result {
                        case .error(let error):
                            return completion(error)
                        case .success(_):
                            completion(nil)
                        }
                    }
                }
        }
    }

    /// Delete the object from the server via a DELETE request and from the Realm.
    ///
    /// - parameter completion: called upon deletion.
    /// - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
    @discardableResult func delete(completion: @escaping (_ error: APIError?) -> Void) -> JSONAPIRequest? {
        guard let primaryKeyProperty = self.objectSchema.primaryKeyProperty else {
            completion(APIError(code: "-1", status: nil, message: "Cannot reload an item without a primary key."))
            return nil
        }
		
        guard let id = self[primaryKeyProperty.name] else {
            completion(APIError(code: "-1", status: nil, message: "To refresh, an item must have an ID"))
            return nil
        }

        guard let subfix = (type(of: self) as? JSONAPIObjectProtocol.Type)?.requst_subfix else {
            completion(.notJSONAPIObjectProtocol)
            return nil
        }
		
		guard let api_version = (type(of: self) as? JSONAPIObjectProtocol.Type)?.api_version else {
			completion(.notJSONAPIObjectProtocol)
			return nil
		}
		
        return JSONAPIRequest(url: "\(Environment.baseURL)/api/\(api_version)/\(subfix)/\(id)", method: .delete, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler { (response) in
                switch response {
                case .error(let error):
                    return completion(error)
                case .success(let jsonAPIDocument):
                    RealmDataController.shared.apply(jsonAPIDocument) { result in
                        switch result {
                        case .error(let error):
                            return completion(error)
                        case .success(_):
                            return completion(nil)
                        }
                    }
                }
        }
    }

    override func setValue(_ value: Any?, forKey key: String) {
        guard let property = self.objectSchema.properties.first(where: { $0.name == key }) else {
            return super.setValue(value, forKey: key)
        }
        guard property.type == .date, let stringValue = value as? String else {
            return super.setValue(value, forKey: key)
        }
        super.setValue(APIController.parseDate(stringValue), forKey: key)
    }
}

protocol RealmObjectProtocol {
	// Class property (equal to instance type)
	static var type: String { get }
	// Based on Realm
	static func primaryKey() -> String
}

protocol JSONAPIObjectProtocol: RealmObjectProtocol {
	// request subfix
	static var requst_subfix: String { get }
	// the special api version
	static var api_version: String { get }
}
