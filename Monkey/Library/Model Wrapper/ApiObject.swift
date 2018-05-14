//
//  ApiObject.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/9.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift

enum ApiType: String {
	case UnAvaliable = "unAvaliable"

	case Auth = "accountkit"
	case Experiment = "experiments"

	case Users = "users"
	case Instagram_accounts = "instagram_accounts"
	case Instagram_photos = "instagram_photos"
	case Bananas = "bananas"
	case Apns = "apns"
	case Channels = "channels"
	case UserOptions = "UserOption"

	case Messages = "messages"
	case Friendships = "friendships"
	case Blocks = "blocks"

	case Videocall = "videocall"

	case Chats = "chats"
	case Match_request = "match_request"
	case Match_cancel = "match_cancel"
	case Reports = "reports"
	case Match_event = "MatchEvent"
	case Match_info = "MatchInfo"
}

enum ApiVersion: String {
	case V10 = "v1.0"
	case V12 = "v1.2"
	case V13 = "v1.3"
	case V20 = "v2.0"
}

typealias SingleModelOperationCompletionHandler<T> = (_ result: JSONAPIResult<T>) -> Void
typealias JSONAPIOperationCompletionHandler<T> = (_ result: JSONAPIResult<[T]>) -> Void
typealias JSONAPIOperationCompletionHandlerWithFlag<T> = (_ result: JSONAPIResult<[T]>,_ flag:Bool) -> Void

protocol RealmObjectProtocol {
	// Class property (equal to instance type)
	static var type: String { get }
}

extension RealmObjectProtocol {
	static var type: String {
		return String(describing: self)
	}
}

protocol APIProtocol: RealmObjectProtocol {
	// the special request subfix
	static var requst_subfix: String { get }
	// the special api version
	static var api_version: ApiVersion { get }
	// the common request path
	static var common_request_path: String { get }
}

extension APIProtocol {
	static var requst_subfix: String {
		return type
	}
	static var api_version: ApiVersion {
		return ApiVersion.V10
	}
	static var common_request_path: String {
		return "\(Environment.baseURL)/api/\(api_version.rawValue)/\(requst_subfix)"
	}
}

protocol SpecificObjectProtocol: APIProtocol {
	// the special attributes pair
	static var attributes: [String]? { get }
	// the special request path
	static func specific_request_path(specific_id: String) -> String
	// the special request path
	var specific_request_path: String? { get }
}

extension SpecificObjectProtocol {
	static var attributes: [String]? {
		return nil
	}

	static func specific_request_path(specific_id: String) -> String {
		return "\(common_request_path)/\(specific_id)"
	}

	var specific_request_path: String? {
		guard let model = self as? MonkeyModel else {
			print("must be a monkey model")
			return nil
		}
		
		let primary_key = type(of: model).primaryKey()
		guard let specific_id = model.value(forKey: primary_key) as? String else {
			print("To refresh, an item must have an ID")
			return nil
		}

		return type(of: self).specific_request_path(specific_id: specific_id)
	}
}

protocol APIRequestProtocol: APIProtocol {
	/**
	Perform an HTTP request based on the JSON API standard.

	- parameter path: The path to append to the `APIController.baseURL` path, including a leading `/`.
	- parameter method: The HTTPMethod to server, defalut is GET.
	- parameter parameters: The parameter to server, defalut is nil.
	- parameter completion: Called with two mutually exclusive result objects rafter the request completes.
	- parameter error: An APIError sent if the data request returns a JSON API error object or when the response is invalid JSON API format.
	- parameter data: The API error data.
	*/
	@discardableResult static func request(url: String?, method: HTTPMethod, parameters: Parameters?, completion: @escaping JSONAPIRequestCompletionHandler) -> JSONAPIRequest?
}

protocol CommonAPIRequestProtocol: APIRequestProtocol {
	/**
	Retrieve a set of items from the API and update/add that data to Realm.

	- parameter parameters: Key value parameters to use with Alamofire
	- parameter completion: Called after the request finishes and the data is syced with Realm (or on error).
	- parameter error: The error encountered.
	- parameter item: The response document.
	- returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	*/
	@discardableResult static func fetchAll<T: RealmObjectProtocol>(parameters: Parameters?, completion: @escaping JSONAPIOperationCompletionHandler<T>) -> JSONAPIRequest?

	/**
	POSTs a new item to the API, adds the newly created item to realm, and provides it’s value.

	- parameter parameters: JSON API data to use in the body of the request.
	- parameter completion: Called after the request finishes (or on error).
	- parameter error: The error encountered.
	- parameter item: The response document.
	- returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	*/
	@discardableResult static func create<T: RealmObjectProtocol>(method: HTTPMethod, parameters: Parameters?, completion: @escaping SingleModelOperationCompletionHandler<T>) -> JSONAPIRequest?
}

protocol SpecificJsonAPIRequestProtocol: APIRequestProtocol {
	/**
	Perform an HTTP request based on the JSON API standard.

	- parameter path: The path to append to the `APIController.baseURL` path, including a leading `/`.
	- parameter method: The HTTPMethod to server, defalut is GET.
	- parameter parameters: The parameter to server, defalut is nil.
	- parameter completion: Called with two mutually exclusive result objects rafter the request completes.
	- parameter error: An APIError sent if the data request returns a JSON API error object or when the response is invalid JSON API format.
	- parameter data: The API error data.
	*/
	@discardableResult static func request(url: String?, method: HTTPMethod, parameters: Parameters?, completionParse: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest?
}

protocol SpecificAPIRequestProtocol: SpecificObjectProtocol, SpecificJsonAPIRequestProtocol {
	/**
	Retrieve an item from the API and update/add that data to Realm.

	- parameter id: The id of the item to retrieve.
	- parameter completion: Called after the request finishes and the data is syced with Realm (or on error).
	- parameter error: The error encountered.
	- parameter item: The item retrieved.
	- returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	*/
	@discardableResult static func fetch(id: String, completion: @escaping JSONAPIRequestCompletionHandler) -> JSONAPIRequest?

	/**
	Updates the current item with the latest data available in the server.

	- parameter completion: Called when the request completes.
	- parameter error: The error encountered while trying to reload data.
	- returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	*/
	@discardableResult func reload(completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest?

	/// Updates a relationship.
	///
	/// - Parameters:
	///   - relationshipKey: The key of a relationship to delete.
	///   - completion: Called when the update competes.
	///   - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	@discardableResult func update(relationship: String, resourceIdentifier: JSONAPIResourceIdentifier?, completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest?

	/**
	Updates user information both backend and frontend

	- parameter attributes: An array of Attribute items to update.
	- parameter callback: Called whent the request completes.
	- parameter error: The error encountered.
	*/
	@discardableResult func update(attributes: [String]?, completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest?

	/// Delete the object from the server via a DELETE request and from the Realm.
	///
	/// - parameter completion: called upon deletion.
	/// - returns: The DataRequest if a request was started. Use this to cancel the in-flight HTTP request.
	@discardableResult func delete(completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest?

	/**
	Updates user information both backend and frontend

	- parameter attributes: An array of Attribute items to update.
	- parameter callback: Called whent the request completes.
	- parameter error: The error encountered.
	*/
	func patch(parameters: Parameters?, completion: @escaping JSONAPIRequestErrorHandler)
}

extension APIRequestProtocol {
	@discardableResult static func request(url: String?, method: HTTPMethod = .get, parameters: Parameters? = nil, completion: @escaping JSONAPIRequestCompletionHandler) -> JSONAPIRequest? {
		guard let url = url else {
			completion(.error(APIError(code: "-1", status: nil, message: "request url should not be nil")))
			return nil
		}

		var options: [JSONAPIRequest.RequestOption]?
		if let authorization = APIController.authorization {
			options = [
				.header("Authorization", authorization),
			]
		}
		
		print("API request:request url:\(url)\nobject type:\(type)\nobject api version:\(api_version)\nobject subfix:\(requst_subfix)")

		return JSONAPIRequest(url: url, method: method, parameters: parameters, options: options).addCompletionHandler({ result in
				switch result {
				case .error(let error):
					completion(.error(error))
				case .success(let jsonAPIDocument):
					completion(.success(jsonAPIDocument))
				}
			})
	}
}

extension SpecificJsonAPIRequestProtocol {
	@discardableResult static func request(url: String?, method: HTTPMethod = .get, parameters: Parameters? = nil, completionParse: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest? {
		return request(url: url, method: method, parameters: parameters, completion: { (result) in
			switch result {
			case .error(let error):
				completionParse(error)
			case .success(let jsonAPIDocument):
				RealmDataController.shared.apply(jsonAPIDocument) { parsedResult in
					switch parsedResult {
					case .error(let error):
						completionParse(error)
					case .success( _):
						completionParse(nil)
					}
				}
			}
		})
	}
}

extension CommonAPIRequestProtocol {
	@discardableResult static func fetchAll<T: RealmObjectProtocol>(parameters: Parameters? = nil, completion: @escaping JSONAPIOperationCompletionHandler<T>) -> JSONAPIRequest? {
		return request(url: common_request_path, parameters: parameters, completion: { (result) in
			switch result {
			case .error(let error):
				completion(.error(error))
			case .success(let jsonAPIDocument):
				RealmDataController.shared.apply(jsonAPIDocument) { (parsedResult) in
					switch parsedResult {
					case .error(let parseError):
						completion(.error(parseError))
					case .success(let newObjects):
						completion(.success(newObjects as! [T]))
					}
				}
			}
		})
	}

	@discardableResult static func create<T: RealmObjectProtocol>(method: HTTPMethod = .get, parameters: Parameters? = nil, completion: @escaping SingleModelOperationCompletionHandler<T>) -> JSONAPIRequest? {
		return request(url: common_request_path, method: method, parameters: parameters, completion: { (response) in
			switch response {
			case .error(let error):
				completion(.error(error))
			case .success(let jsonAPIDocument):
				RealmDataController.shared.apply(jsonAPIDocument) { (result) in
					switch result {
					case .error(let parseError):
						completion(.error(parseError))
					case .success(let newObjects):
						completion(.success(newObjects.first! as! T))
					}
				}
			}
		})
	}
}

extension SpecificAPIRequestProtocol {
	@discardableResult static func fetch(id: String, completion: @escaping JSONAPIRequestCompletionHandler) -> JSONAPIRequest? {
		return request(url: specific_request_path(specific_id: id), completion: completion)
	}

	@discardableResult func reload(completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest? {
		return type(of: self).request(url: specific_request_path, completionParse:completion)
	}

	@discardableResult func update(relationship: String, resourceIdentifier: JSONAPIResourceIdentifier?, completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest? {
		return type(of: self).request(url: specific_request_path, completionParse:completion)
	}

	@discardableResult func update(attributes: [String]?, completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest? {
		return type(of: self).request(url: specific_request_path, completionParse:completion)
	}

	@discardableResult func delete(completion: @escaping JSONAPIRequestErrorHandler) -> JSONAPIRequest? {
		return type(of: self).request(url: specific_request_path, completionParse:completion)
	}

	func patch(parameters: Parameters?, completion: @escaping JSONAPIRequestErrorHandler) {
		type(of: self).request(url: specific_request_path, method: .patch, parameters: parameters, completionParse: completion)
	}
}
