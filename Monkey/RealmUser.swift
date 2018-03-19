//
//  RealmModels.swift
//  Monkey
//
//  Created by Jun Hong on 4/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import RealmSwift
import Alamofire

class RealmUser: JSONAPIObject, JSONAPIObjectProtocol {
    static let type = "users"
	static let requst_subfix = RealmUser.type
	static let api_version = APIController.shared.apiVersion
    
    let friendships = LinkingObjects(fromType: RealmFriendship.self, property: "user")
    
    let age = RealmOptional<Int>()
    let latitude = RealmOptional<Double>()
    let longitude = RealmOptional<Double>()
    let seconds_in_app = RealmOptional<Int>()
    let channels = List<RealmChannel>()
    let bananas = RealmOptional<Int>()
    let facebook_friends_invited = RealmOptional<Int>()
    let is_snapcode_uploaded = RealmOptional<Bool>()
	let is_banned = RealmOptional<Bool>()
    dynamic var gender: String?
    dynamic var show_gender: String?
    dynamic var address: String?
    dynamic var location: String?
    dynamic var snapchat_username: String?
    dynamic var username: String?
    dynamic var user_id: String?
    dynamic var first_name: String?
    dynamic var profile_photo_url: String?
    dynamic var profile_photo_upload_url: String?
    dynamic var birth_date: NSDate?
    dynamic var updated_at: NSDate?
    dynamic var created_at: NSDate?
    dynamic var tag: RealmTag?
    dynamic var last_online_at: NSDate?
    dynamic var instagram_account: RealmInstagramAccount?
	
    override static func primaryKey() -> String {
        return "user_id"
    }
    
    /// Each Attribute case corresponds to a User attribute that can be updated/modified.
    enum Attribute {
        case snapchat_username(String?)
        case gender(String?)
        case show_gender(String?)
        case age(Int?)
        case latitude(Double?)
        case longitude(Double?)
        case address(String?)
        case first_name(String?)
        case birth_date(NSDate?)
        case tag(RealmTag?)
        case channels(List<RealmChannel>)
        case seconds_in_app(Int?)
        case facebook_friends_invited(Int?)
		case is_banned(Bool?)
    }
    
 
    /**
     Updates user information both backend and frontend
     
     - parameter attributes: An array of Attribute items to update.
     - parameter callback: Called whent the request completes.
     - parameter error: The error encountered.
     */
    func update(attributes: [Attribute], completion: @escaping (_ error: APIError?) -> Void) {
        guard let user_id = self.user_id else {
            completion(APIError(code: "-1", status: nil, message: "User ID must exist for updates."))
            return
        }
        var relationshipsJSON = [String:Any]()
        var attributesJSON = [String:Any]()
        for attribute in attributes {
            switch attribute {
            case .address(let address):
                attributesJSON["address"] = address ?? NSNull()
            case .age(let age):
                attributesJSON["age"] = age ?? NSNull()
            case .gender(let gender):
                attributesJSON["gender"] = gender ?? NSNull()
            case .show_gender(let show_gender):
                attributesJSON["show_gender"] = show_gender ?? NSNull()
            case .latitude(let latitude):
                attributesJSON["latitude"] = latitude ?? NSNull()
            case .longitude(let longitude):
                attributesJSON["longitude"] = longitude ?? NSNull()
            case .snapchat_username(let snapchat_username):
                attributesJSON["snapchat_username"] = snapchat_username ?? NSNull()
            case .first_name(let first_name):
                attributesJSON["first_name"] = first_name ?? NSNull()
            case .birth_date(let birth_date):
                attributesJSON["birth_date"] = birth_date?.iso8601 ?? NSNull()
            case .tag(let tag):
                relationshipsJSON["tag"] = tag == nil ? NSNull() : [
                    "data": [
                        "type": "tags",
                        "id": tag!.tag_id, // Safe due to nil check above.
                    ]
                ]
            case .channels(let channels):
                relationshipsJSON["channels"] = [
                    "data": Array(channels).map { (channel) in
                        return [
                            "type": "channels",
                            "id": channel.channel_id!,
                            ]
                    }
                ]
            case .seconds_in_app(let seconds_in_app):
                attributesJSON["seconds_in_app"] = seconds_in_app ?? NSNull()
            case .facebook_friends_invited(let friends_invited): 
                attributesJSON["facebook_friends_invited"] = friends_invited ?? NSNull()
			case .is_banned(let is_banned):
				attributesJSON["is_banned"] = is_banned ?? false
            }
            
        }
		
        JSONAPIRequest(url: "\(Environment.baseURL)/api/\(RealmUser.api_version)/\(RealmUser.requst_subfix)/\(user_id)", method: .patch, parameters: [
            "data": [
                "id": user_id,
                "type": RealmUser.type,
                "attributes": attributesJSON,
                "relationships": relationshipsJSON,
            ],
        ], options: [
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
}
