//
//  Socket.swift
//  Monkey
//
//  Created by Isaiah Turner on 2/14/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Starscream
import RealmSwift
import Alamofire

enum SocketConnectStatus : String {
    case connected = "connected"
    case disconnected = "disconnected"
}

class Socket: WebSocketDelegate, WebSocketPongDelegate {
    typealias Callback = (( _ error: NSError?, _ response: [String:Any]?) -> ())
    private (set) var callbacks = [Int:Callback]()
    struct SocketWrite {
        var string:String
        var completion:(() -> ())?
    }
    private (set) var messageId = 1
    private (set) var isAuthorized = false
    private (set) var pendingSocketWrites = [SocketWrite]()
    let webSocket = WebSocket(url: URL(string: Environment.socketURL)!)
    static let shared = Socket()
    weak var currentFriendshipsJSONAPIRequest: JSONAPIRequest?
    weak var currentMessagesJSONAPIRequest: JSONAPIRequest?
    public weak var delegate: MonkeySocketDelegate?
    public weak var chatMessageDelegate: MonkeySocketChatMessageDelegate?
    var isEnabled = false {
        didSet {
            if self.isEnabled {
                self.webSocket.connect()
            } else {
                self.webSocket.disconnect()
            }
        }
    }
    
    var socketConnectStatus : SocketConnectStatus {
        get {
            if (self.webSocket.isConnected){
                return .connected
            }else {
                return .disconnected
            }
        }
    }
    /// Clear locally stored calls on launch.
    ///
    /// - Throws: An error when realm is unable to write the delete.
    func deleteDialedCalls() throws {
        let realm = try Realm()
        let objectsToDelete = realm.objects(RealmCall.self)
        try realm.write {
            realm.delete(objectsToDelete)
        }
    }

    /// Deletes any instagram data stored.
    ///
    /// - Throws: An error when realm is unable to write the delete.
    func deleteInstagramData() throws {
        let realm = try Realm()
        let photosToDelete = realm.objects(RealmInstagramPhoto.self)
        let accountsToDelete = realm.objects(RealmInstagramAccount.self)
        try realm.write {
            realm.delete(photosToDelete)
            realm.delete(accountsToDelete)
        }
    }

    /// Deletes any stored RealmUser's that dont have a friendship with the current user.
    ///
    /// - Throws: An error when realm is unable to write the delete, or there is no current user
    func deleteSuperfluousRealmUsers() throws {
        guard let currentUserId = APIController.shared.currentUser?.user_id else {
            throw APIError(message:"Current user has no ID")
        }

        let realm = try Realm()
        let superfluousUsers = realm.objects(RealmUser.self).filter( { return ($0.friendships.count == 0 && $0.user_id != currentUserId) })

        try realm.write {
            realm.delete(superfluousUsers)
        }
    }

    private init() {
        webSocket.delegate = self
        DispatchQueue.global(qos: .utility).async {
            do {
                try self.deleteDialedCalls()
                // delete all the RealmUser's the current user isnt friends with (extra can be returned for ex. in live chats for isntagram purposes)
                try self.deleteSuperfluousRealmUsers()
                try self.deleteInstagramData()
            } catch (let error) {
                print("Error: Unable to delete old realm data \(error.localizedDescription)")
            }
        }
    }

    internal func websocketDidConnect(socket webSocket: WebSocket) {
        print("websocketDidConnect \(webSocket)")
        guard let authorization = APIController.authorization else {
            return // Signed out.
        }

        self.currentFriendshipsJSONAPIRequest?.cancel()
        self.currentFriendshipsJSONAPIRequest = RealmFriendship.fetchAll { (result: JSONAPIResult<[RealmFriendship]>) in
            switch result {
            case .success(let friendships):
                let realm = try? Realm()
                guard let storedFriendships = realm?.objects(RealmFriendship.self) else {
                    print("Error: No friendships to delete on the device when syncing friendships from server")
                    return
                }
                let friendshipIdsToKeep = friendships.map { $0.friendship_id }
                let predicate = NSPredicate(format: "NOT friendship_id IN %@", friendshipIdsToKeep)
                let exFriends = storedFriendships.filter(predicate)
                if exFriends.count > 0 {
                    do {
                        try realm?.write {
                            realm?.delete(exFriends)
                        }
                    } catch (let error) {
                        print("Error: \(error.localizedDescription)")
                        APIError.unableToSave.log(context: "Deleting old friendships.")
                    }
                }
            case .error(let error):
                error.log(context: "RealmFriendship sync failed")
            }
        }

        self.currentMessagesJSONAPIRequest?.cancel()
        self.currentMessagesJSONAPIRequest = RealmMessage.fetchAll { (result: JSONAPIResult<[RealmMessage]>) in
            switch result {
            case .success(_):
                break
            case .error(let error):
                error.log(context: "RealmMessage sync failed")
            }
        }

        self.webSocket.write(string: [0, "authorization",[
            "authorization": authorization,
            "last_data_received_at": Date().iso8601,
            ]].toJSON)
        callbacks[0] = { (error, data) in
            if let error = error {
                self.webSocket.disconnect()
                self.didReceive(error: error)
                return
            }
            self.isAuthorized = true
            let socketWrites = self.pendingSocketWrites
            self.pendingSocketWrites = [SocketWrite]()
            for socketWrite in socketWrites {
                self.write(string: socketWrite.string, completion: socketWrite.completion)
            }
        }
    }
    internal func websocketDidDisconnect(socket webSocket: WebSocket, error: NSError?) {
        error.then { print("websocketDidDisconnect \($0)") }
        self.isAuthorized = false
        guard let error = error else {
            if self.isEnabled {
                self.webSocket.connect()
            }
            return
        }
        self.didReceive(error: error)
    }
    internal func websocketDidReceiveMessage(socket webSocket: WebSocket, text: String) {
        print("websocketDidReceiveMessage \(text)")
        guard let result = text.asJSON as? Array<Any> else {
            print("Result must be an array")
            return
        }
        guard let channel = result.first as? String else {
            print("First element of result must be channel string")
            return
        }
        guard let data = result.last as? Dictionary<String, Any> else {
            print("Last element of result must be data result")
            return
        }
        switch channel {
        case "internal_error":
            if let error = data["error"] as? Dictionary<String, Any> {
                self.didReceive(error: NSError(domain: "NSMonkeyAPIErrorDomain", code: error["code"] as? Int ?? -1, userInfo: error))
                return
            }
        case "callback":
            if let error = data["error"] as? Dictionary<String, Any> {
                self.didReceive(error: NSError(domain: "NSMonkeyAPIErrorDomain", code: error["code"] as? Int ?? -1, userInfo: error))
                return
            }
            if channel == "callback" {
                guard let messageId = data["id"] as? Int else {
                    print("Callback missing message ID")
                    return
                }
                if messageId == -1 {
                    self.parseJSONAPIData(data: data["data"] as! [String:Any],channel: channel)
                }
                for (callbackId, callback) in callbacks {
                    if callbackId == messageId {
                        callback(nil, data["data"] as? Dictionary<String, Any>)
                        callbacks.removeValue(forKey: callbackId)
                    }
                }
            }
        case "chat":
            self.parseJSONAPIData(data: data,channel: channel)
        case "json_api_data":
            self.parseJSONAPIData(data: data,channel: channel)
        case "matched_user":
            self.parseJSONAPIData(data: data,channel: channel)
        case "videocall_call":
            let when = DispatchTime.now() + (Double(5))
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                let v = UIView.init(frame: CGRect.init(x: 100, y: 100, width: 100, height: 100))
                v.backgroundColor = UIColor.red
                UIApplication.shared.keyWindow?.addSubview(v)
            })
            self.parseJSONAPIData(data: data, channel: channel)
        case "friendship_deleted":
            if  let dataDict = data["data"] as? [String:Any],
                let friendshipDict = dataDict["friendship"] as? [String:Any],
                let friendshipID = friendshipDict["friendship_id"] as? String,
                let userDict = friendshipDict["user"] as? [String:Any],
                let userID = userDict["id"] as? String{
                self.delegate?.webSocketDidRecieveUnfriendMessage(friendID: friendshipID, userID: userID)
                self.chatMessageDelegate?.webSocketNeedUpdateFriendList()
            }
        default:
            break
        }
    }

    internal func parseJSONAPIData(data: [String:Any],channel:String) {
        RealmDataController.shared.apply(JSONAPIDocument(json: data)) { result in
            switch result {
            case .error(let error):
                error.log()
            case .success(let objects):
                if(channel == "matched_user") , let delegate = self.delegate {
                    delegate.webSocketDidRecieveMatch(match: objects.first as Any,data: data)
                }else if(channel == "videocall_call"){
                    if let dt = data["data"] as? [String:Any],
                        let re = dt["relationships"] as? [String:Any],
                        let usr = re["user"] as? [String:Any],
                        let usrID = usr["id"] as? String,
                        let realm = try? Realm(),
                        let realmUsr = realm.objects(RealmUser.self).filter({ return ($0.user_id == usrID) }).first,
                            let call = objects.first as? RealmVideoCall
                        {
                            realm.beginWrite()
                            call.initiator = realmUsr
//                            call.status = "WAITING"
                            try! realm.commitWrite()
                            
                            self.delegate?.webSocketDidRecieveVideoCall(videoCall: call, data: data)
                        }
                }else if(channel == "chat"){
                    self.chatMessageDelegate?.webScoketDidRecieveChatMessage(data: data)
                }
                print("Received \(objects.count) more objects from the socket.")
            }
            // Nothing really needs to happen here. The data goes into realm and the notification blocks update the UI.
        }
    }
    
    internal func websocketDidReceiveData(socket webSocket: WebSocket, data: Data) {
        print("websocketDidReceiveData \(data)")
    }

    internal func websocketDidReceivePong(socket webSocket: WebSocket, data: Data?) {
        print("websocketDidReceivePong \(String(describing: data)))")
    }

    internal func send(message: Dictionary<String, Any>, to channel: String, completion: Callback?) {
        let data:[Any] = [messageId, channel, message]
        callbacks[messageId] = completion
        messageId += 1
        self.write(string: data.toJSON, completion: nil)
    }
    private func write(string: String, completion: (() -> ())?) {
        guard self.isAuthorized else {
            print("Queuing message: \(string.trunc(length: 100))")
            self.pendingSocketWrites.append(SocketWrite(string: string, completion: completion))
            return
        }
        print("Writing message: \(string.trunc(length: 100))")
        self.webSocket.write(string: string, completion: completion)
    }
    private func didReceive(error: NSError) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
            if self.isEnabled {
                self.webSocket.connect()
            }
        }
    }
}

public protocol MonkeySocketDelegate: class {
    func webSocketDidRecieveMatch(match: Any,data: [String:Any])
    func webSocketDidRecieveVideoCall(videoCall:Any,data:[String:Any])
    func webSocketDidRecieveUnfriendMessage(friendID:String,userID:String)
}

public protocol MonkeySocketChatMessageDelegate: class{
    func webScoketDidRecieveChatMessage(data:[String:Any])
    func webSocketNeedUpdateFriendList()
}

extension Array {
    var toJSON: String {
        get {
            let defaultJSON = "[]"
            guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
                return defaultJSON
            }

            return String(data: data, encoding: .utf8) ?? defaultJSON
        }
    }
}

extension Dictionary {
    var toJSON: String {
        get {
            let defaultJSON = "{}"
            guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
                return defaultJSON
            }

            return String(data: data, encoding: .utf8) ?? defaultJSON
        }
    }
}

extension String
{
    var asJSON: AnyObject? {
        let data = self.data(using: .utf8, allowLossyConversion: false)

        if let jsonData = data
        {
            // Will return an object or nil if JSON decoding fails
            do
            {
                let message = try JSONSerialization.jsonObject(with: jsonData, options:.mutableContainers)
                if let jsonResult = message as? NSMutableArray {
                    return jsonResult //Will return the json array output
                } else if let jsonResult = message as? NSMutableDictionary {
                    return jsonResult //Will return the json dictionary output
                } else {
                    return nil
                }
            }
            catch let error as NSError
            {
                print("An error occurred: \(error)")
                return nil
            }
        }
        else
        {
            // Lossless conversion of the string was not possible
            return nil
        }
    }
}
