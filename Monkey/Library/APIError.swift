//
//  APIError.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/24/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class APIError: Error, CustomStringConvertible {
    // Define frequently used client errors.
    static let realmNotInitialized = APIError(message: "Realm is not initialized.")
    static let unableToSave = APIError(message: "Unable to save data to disk.")
    static let notJSONAPIObjectProtocol = APIError(message: "To refresh, the class must conform to JSONAPIObjectProtocol.")
	static let notAPIObjectProtocol = APIError(message: "To refresh, the class must conform to APIObjectProtocol.")
	
    var code: APIErrorCode
    /// The HTTP Status Code if the error was generated by an HTTP request.
    var status: String?
    var message: String
	var internalMessage: String
    
    /// Includes meta data for error (facts etc.)
    var meta: [String: Any]?

    init(code: String, status: String?, message: String) {
        self.code = APIErrorCode(rawString: code)
        self.message = message
        self.internalMessage = message
        status.then { self.status = $0 }
    }
	
    init(code: String = "-1", status: String? = nil, message: String, internalMessage: String? = nil) {
        self.code = APIErrorCode(rawString: code)
        self.message = message
        self.internalMessage = internalMessage ?? message
        status.then { self.status = $0 }
    }
    
    init(jsonApiError: JSONAPIError) {
        self.status = jsonApiError.status
        self.code = APIErrorCode(rawString: jsonApiError.code ?? "-1")
        let message = jsonApiError.title ?? "Unknown JSON API error."
        self.message = message
        self.internalMessage = jsonApiError.detail ?? message
        self.meta = jsonApiError.meta ?? [:]
    }
    
    /// Logs the API Error in a standardized format
    ///
    /// - Parameter context: An optional message to append to the end of the log, useful for identifying the source of the error
    func log(context:String = "") {
        print(self.description + ". \(context)")
    }

    var description: String {
        var descriptionString = "Error: (\(code) "
        if let status = status {
            descriptionString +=  "- \(status) "
        }
        descriptionString += ") \(message) - \(internalMessage)"
        return descriptionString
    }
	
    func toAlert(onOK: ((UIAlertAction) -> Void)?) -> UIAlertController {
        return alert(dismissText: "OK", onDismissal: onOK)
    }
    
    func toAlert(onOK: ((UIAlertAction) -> Void)?, title: String, text:String) -> UIAlertController {
        return alert(titleString: title, dismissText: text, onDismissal: onOK)
    }
    
    func toAlert(onRetry: ((UIAlertAction) -> Void)?) -> UIAlertController {
        return alert(dismissText: "Retry", onDismissal: onRetry)
    }
    
    private func alert(titleString: String = "Uh oh!", dismissText: String, onDismissal: ((UIAlertAction) -> Void)?) -> UIAlertController {
        // Default alert title
        var title = titleString
        
        // Default alert message
        var message = self.message
        
        // Swaps title and alert message with more user friendly verbiage if server is down
        if let statusCode = self.status {
            if statusCode >= "500"  && statusCode <= "599" {
                title = "Monkey is going bananas! 🍌"
                message = "Monkey is down for maintenance. Try again soon."
                print("Error: obfuscated HTTP \(statusCode) \(self.message) to user.")
            }
        }
        
        let alert = UIAlertController(title: title, message: titleString == "Uh oh!" ? message : nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissText, style: .cancel, handler: onDismissal))
        return alert
    }
}

enum APIErrorCode: String {
    /// The default error code.
    case unknown = "-1"
	/// The error that occurs when the user swipes away while a chat session request is being created
	case cancelled = "-999"
    /// An unrecognized error represents any error with a raw value that has not been represented in this enum.
    case unrecognized = "0"
	
    init(rawInt: Int) {
        guard let apiError = APIErrorCode(rawValue: "\(rawInt)") else {
            print("Error: Unrecognized error code \(rawInt). You may need to add it's value to APIErrorCode.")
            self = .unrecognized
            return
        }
        self = apiError
    }
	
    init(rawString: String) {
        guard let apiError = APIErrorCode(rawValue: rawString) else {
            print("Error: Unrecognized error code \(rawString)")
            self = .unrecognized
            return
        }
        self = apiError
    }
}
