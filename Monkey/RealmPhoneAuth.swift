//
//  RealmPhoneAuth.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/26/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import Alamofire

class RealmPhoneAuth: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "phone_auths"
    
    let code_length = RealmOptional<Int>()
    let resend_after = RealmOptional<Double>()
    let resend_count = RealmOptional<Int>()
    let is_validated = RealmOptional<Bool>()
    
    dynamic var phone_auth_id: String?
    dynamic var character_set: String?
    dynamic var code: String?
    dynamic var country_code: String?
    dynamic var phone_number: String?
    dynamic var method: String?
    dynamic var token: String?
    dynamic var user: RealmUser?
    
    override static func primaryKey() -> String {
        return "phone_auth_id"
    }
    
    func update(attributesJSON: [String:Any], completion: @escaping (_ error: APIError?,_ response : JSONAPIDocument?) -> Void) {
        guard let auth_id = self.phone_auth_id else {
            completion(APIError(code: "-1", status: nil, message: "A ID must exist for updates."),nil)
            return
        }
        
        JSONAPIRequest(url: "\(Environment.baseURL)/api/\(APIController.shared.apiVersion)/phone_auths/\(auth_id)", method: .patch, parameters: [
            "data": [
                "id": auth_id,
                "type": "phone_auths",
                "attributes": attributesJSON,
            ],
            ], options: [
                .header("Authorization", APIController.authorization),
                ]).addCompletionHandler { (response) in
                    switch response {
                    case .error(let error):
                        return completion(error,nil)
                    case .success(let jsonAPIDocument):
                        RealmDataController.shared.apply(jsonAPIDocument) { (result) in
                            switch result {
                            case .error(let error):
                                return completion(error,nil)
                            case .success(_):
                                return completion(nil,jsonAPIDocument)
                            }
                        }
                    }
            }
    }
}

