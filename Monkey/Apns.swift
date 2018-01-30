//
//  AppleDevice.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/23/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation
import Alamofire

class Apns {
    class func update(callback: ((_ error: String?) -> Void)?) {
        let token = UserDefaults.standard.string(forKey: "apns_token")
        print("<<<>>>\(String(describing: token))")
        if token == nil {
            return
        }
        let badge = UserDefaults.standard.bool(forKey: "apns_badge") == true
        let sound = UserDefaults.standard.bool(forKey: "apns_sound") == true
        let alert = UserDefaults.standard.bool(forKey: "apns_alert") == true
        let paramaters:Parameters = [
            "data": [
                "type": "apns",
                "id": token!,
                "attributes": [
                    "badge": badge,
                    "sound": sound,
                    "alert": alert,
                ]
            ]
        ]

        var headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        if let authorization = APIController.authorization {
            headers["Authorization"] = authorization

        }
        Alamofire.request("\(Environment.baseURL)/api/v1.0/apns", method: .post, parameters: paramaters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            if let error = response.result.error {
                callback?(error.localizedDescription)
                return
            }
            if response.response!.statusCode >= 400  {
                if let reason = (response.result.value as? Dictionary<String, Array<Dictionary<String, Any>>>)?["errors"]?[0]["title"] as? String {
                    callback?(reason)
                } else {
                    callback?("Unknown error")
                }
                return
            }
            callback?(nil)
        }
    }
}
