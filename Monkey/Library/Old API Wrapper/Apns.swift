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
	class func update(token: String? = Achievements.shared.apns_token) {
		
		guard let token = token, token.isEmpty == false else { return }
        guard UserManager.shared.isUserLogin() else { return }
		
        let badge = UserDefaults.standard.bool(forKey: "apns_badge") == true
        let sound = UserDefaults.standard.bool(forKey: "apns_sound") == true
        let alert = UserDefaults.standard.bool(forKey: "apns_alert") == true
        let paramaters: Parameters = [
            "data": [
                "type": "apns",
                "id": token,
                "attributes": [
                    "badge": badge,
                    "sound": sound,
                    "alert": alert,
                ]
            ]
        ]
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V10.rawValue)/\(ApiType.Apns.rawValue)", method: .post, parameters: paramaters) { (_) in
			
		}
    }
}
