//
//  APIResponse.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/24/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire

typealias JSONAPIRequestCompletionHandler = (_ result: JSONAPIResult<JSONAPIDocument>) -> Void

class JSONAPIRequest {
    /// Enumerations that can be passed to a request options object to modify default request behaviour.
    enum RequestOption {
        /// The value for the Authorization header. Defaults to self.authorization.
        case header(String, String?)
    }
    /// The request created by Alamofire.
    private weak var dataRequest: DataRequest?
    /// The document returned by the request. This will not be populated until shortly before completion is called.
    private(set) var responseJSONAPIDocument: JSONAPIDocument?
    /**
     Perform an HTTP request based on the JSON API standard.

     - parameter path: The path to append to the `APIController.baseURL` path, including a leading `/`.
     - parameter options: An array of `RequestOption` items to adjust the default behaviors of the request. For many options, only the *last* value provided for the option type will be used.
     - parameter completion: Called with two mutually exclusive result objects rafter the request completes.
     - parameter error: An APIError sent if the data request returns a JSON API error object or when the response is invalid JSON API format.
     - parameter data: The API error data.
     */
    @discardableResult init(url: String, method: HTTPMethod = .get, parameters: Parameters? = nil, options: [RequestOption]? = nil) {

        let client = Bundle.main.bundleIdentifier
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        // Define variables which may be modified in some way by changing the `options` array.
        var headers: HTTPHeaders = [
            "Accept": "application/vnd.api+json, application/json",
            "Content-Type": "application/vnd.api+json",
            "Client": client ?? "",
            "Version": version ?? ""
            ]

        // Loop through all the options and assign their values to the associated variable.
        options?.forEach {
            switch $0 {
            case .header(let headerKey, let headerValue):
                // If the provided value is nil, remove existing header value, if any.
                if let headerValue = headerValue {
                    headers[headerKey] = headerValue
                } else {
                    headers.removeValue(forKey: headerKey)
                }
            } // End switch statement.
        }

        self.dataRequest = Alamofire.request(url, method: method, parameters: parameters, encoding: method == HTTPMethod.get ? URLEncoding.default : JSONEncoding.default, headers: headers)
            //.validate(statusCode: acceptableStatusCodes)
            .validate(contentType: ["application/json", "application/vnd.api+json"])
    }

    @discardableResult func addCompletionHandler(_ handler: @escaping JSONAPIRequestCompletionHandler) -> Self {
        self.dataRequest?.responseJSON { (response) in
            guard let responseJSON = response.result.value as? [String:Any], // Response format validation failed.
                !response.result.isFailure else // Alamofire validation failed.
            {
                var status: String?

                if let statusCode = response.response?.statusCode {
                    status = String(statusCode)
                }
                return handler(.error(APIError(code: String((response.result.error as? NSError)?.code ?? -1), status: status, message: response.result.error?.localizedDescription ?? "Unknown request error.")))
            }
            let responseJSONAPIDocument = JSONAPIDocument(json: responseJSON)
            self.responseJSONAPIDocument = responseJSONAPIDocument
            if let jsonApiError = responseJSONAPIDocument.errors?[0] {
                return handler(.error(APIError(jsonApiError: jsonApiError)))
            }
            handler(.success(responseJSONAPIDocument))
        }
        return self
    }

    /// Cancels the HTTP request.
    /// - note: If the request has already completed, you may still receive a callback after cancel is called since data parsing happens in a background thread and will still trigger the callback upon completion.
    func cancel() {
        self.dataRequest?.cancel()
    }
}

/// Represents JSON API response data in a defined format.
class JSONAPIDocument {
    /// The JSON data provided to init.
    let json: [String:Any]
    /**
        Creates a new JSONAPIResource struct from the provided JSON data.

        - parameter json: The JSON data to base the struct off of.
    */
    init(json: [String:Any]) {
        self.json = json
    }
    convenience init(data: JSONAPIResourceIdentifier?) {
        self.init(json: [
            "data": data?.json ?? NSNull(),
            ])
    }
    /// json.data
    var dataResource: JSONAPIResource? {
        guard let data = json["data"] as? [String:Any] else {
            return nil // Top level data object doesn't exist.
        }
        return JSONAPIResource(data: data)
    }
    /// json.meta
    var meta: [String:Any]? {
        return json["meta"] as? [String:Any]
    }
    /// json.data
    var dataResourceCollection: [JSONAPIResource]? {
        guard let data = json["data"] as? [[String:Any]] else {
            return nil // Top level data object doesn't exist or is in the incorrect format.
        }
        return data.map { JSONAPIResource(data: $0) }
    }
    /// json.data is NSNull
    var isResourceNull: Bool {
        return json["data"]  is NSNull
    }
    /// json.data is NSNull
    var isResourceUndefined: Bool {
        return json["data"] == nil
    }
    /// json.errors
    var errors:[JSONAPIError]? {
        guard let errors = json["errors"] as? [[String: Any]] else {
            return nil // Top level errors object doesn't exist or is in the incorrect format.
        }
        return errors.map { JSONAPIError(error: $0) }
    }
    /// json.included
    var included:[JSONAPIResource]? {
        guard let included = json["included"] as? [[String:Any]] else {
            guard let data:[String:Any] = json["data"] as? [String : Any],
                let included2 = data["included"] as? [[String:Any]] else {
                    return nil
            }
            return included2.map { JSONAPIResource(data: $0) } // Top level data object doesn't exist or is in the incorrect format.
        }
        return included.map { JSONAPIResource(data: $0) }
    }
    /// data.deleted (This is NOT valid JSON API format. We have deviated from the spec. An array of resource identifiers that were deleted. All delete requests MUST include an identifier for self.)
    var deleted: [JSONAPIResourceIdentifier]? {
        guard let deleted = json["deleted"] as? [[String:Any]] else {
            return nil // Top level data object doesn't exist or is in the incorrect format.
        }
        return deleted.map { JSONAPIResourceIdentifier(data: $0) }
    }
}


/// Represents JSON API errors in a defined format.
class JSONAPIError {
    /// The JSON data provided to init.
    let error: [String: Any]
    /**
     Creates a new JSONAPIError struct from the provided JSON data.

     - parameter json: The JSON data to base the struct off of.
     */
    init(error: [String:Any]) {
        self.error = error
    }
    // error.status
    var status: String? {
        let status = error["status"]
        if let statusInt = status as? Int {
            return String(statusInt)
        }
        return status as? String
    }
    // error.code
    var code: String? {
        return error["code"] as? String
    }
    // error.title
    var title: String? {
        return error["title"] as? String
    }
    // error.detail
    var detail: String? {
        return error["detail"] as? String
    }

    var meta: [String: Any]? {
        return error["meta"] as? [String:Any]
    }
}


/// Represents JSON API resources in a defined format.
class JSONAPIResourceIdentifier {
    /// The JSON data provided to init.
    let json: [String: Any]
    /**
     Creates a new JSONAPIResourceIdentifier struct from the provided JSON data.

     - parameter json: The JSON data to base the struct off of.
     */
    init(data: [String: Any]) {
        self.json = data
    }
    convenience init(type: String, id: String) {
        self.init(data: [
            "type": type,
            "id": id,
            ])
    }
    /// data.id
    var id: String? {
        return json["id"] as? String
    }
    /// data.type
    var type: String? {
        return json["type"] as? String
    }
}

/// Represents JSON API resources in a defined format.
class JSONAPIResource: JSONAPIResourceIdentifier {
    /// data.attributes
    var attributes: [String: Any]? {
        return json["attributes"] as? [String:Any]
    }
    /// data.relationships
    var relationships: [String: Any]? {
        return (json["relationships"] as? [String:Any])?.mapPairs { (key, value) in
            guard value as? NSNull == nil else {
                return (key, value) // Keep null
            }
            guard let relationshipJSON = value as? [String:Any] else {
                return (key, value) // Keep unexpected response
            }
            return (key, JSONAPIDocument(json: relationshipJSON))
        }
    }
}

enum JSONAPIResult<T> {
    case success(T)
    case error(APIError)
}
