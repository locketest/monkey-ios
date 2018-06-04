    //
//  ChatViewModel.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import Foundation
import RealmSwift

protocol ChatViewModelDelegate:class {
    func reloadData()
    func callFailedBeforeInitializingChatSession()
    func processRecievedRealmCallFromServer(realmVideoCall: RealmVideoCall)
}

/// Represents a message that has been created locally and is currently being sent to server.
/// It is used to display pending messages until their equivilant RealmMessage is returned from the server
struct PendingMessage {
    /// The message text being sent
    var text:String
    /// The user who sent the message
    let sender:RealmUser? = APIController.shared.currentUser
    /// An identifier used to match against RealmMessages returned from the server. If there is a match we remove from pending messages array
    var uuid:String
    init(text:String, uuid:String) {
        self.text = text
        self.uuid = uuid
    }
}

class ChatViewModel {

    var messages: Results<RealmMessage>?
    /// An array of PendingMessages used to instanteneously display messages while they are processed on the server.
    /// Once the server returns the equivilant RealmMessage, the pending message is deleted so that the actual RealmMessage can be displayed instead.
    var pendingMessages:[PendingMessage] = []

    /// Returns the message count. If there are any pendingMessages, add their count to the messageCount
    var messageCount:Int {
        return (messages.count) + pendingMessages.count
    }

    weak var delegate: ChatViewModelDelegate?

    private var messagesNotificationToken: NotificationToken?

    /// The id of the friendship the chat model is managing. Allows for threadsafe realm getter
    var friendshipId:String? {
        didSet{
            guard let friendship = self.friendship else{
                print("Error: ChatViewModel unable to retrieve friendship from realm on didSet")
                return
            }
            self.setupFriendship(friendship)
        }
    }

    /// Friendship object between user and who chat is with
    var friendship:RealmFriendship? {
        get {
            let realm = try? Realm()
            return realm?.object(ofType: RealmFriendship.self, forPrimaryKey: friendshipId)
        }
    }

    init() {}

    var userLastOnlineAtString:String {
        if let lastOnlineAt:TimeInterval = friendship?.user?.last_online_at?.timeIntervalSinceNow {
            var secondsSinceOnline = max(lastOnlineAt, friendship?.last_message_received_at?.timeIntervalSinceNow ?? -TimeInterval.greatestFiniteMagnitude)
            var localizedTime = ""
            let seconds:Double = 60
            let hours:Double = 60
            let days:Double = 24

            secondsSinceOnline = -secondsSinceOnline

            if secondsSinceOnline > seconds * hours * days * 2 {
                localizedTime = "A few days ago"
            } else if secondsSinceOnline > seconds * hours * days {
                let daysAgo = Int(secondsSinceOnline / (seconds * hours * days))
                let plurality = daysAgo > 1 ? "s" : ""
                localizedTime = "\(daysAgo) day\(plurality) ago"
            } else if secondsSinceOnline > seconds * hours {
                let hoursAgo = Int(secondsSinceOnline / (seconds * hours))
                let plurality = hoursAgo > 1 ? "s" : ""
                localizedTime = "\(hoursAgo) hour\(plurality) ago"
            } else if secondsSinceOnline > seconds {
                let minutesAgo = Int(secondsSinceOnline / seconds)
                let plurality = minutesAgo > 1 ? "s" : ""
                localizedTime = "\(minutesAgo) minute\(plurality) ago"
            } else {
                localizedTime = "Online"
            }

            return localizedTime
        }

        return "A few days ago"
    }

    func setupFriendship(_ friendship:RealmFriendship) {

        let emptyPredicate = NSPredicate(format: "text != nil")

        self.messages = friendship.messages.sorted(byKeyPath: "created_at", ascending: true).filter(emptyPredicate)
		self.messagesNotificationToken = self.messages?.observe { [weak self] (changes) in
            switch changes {
            case .error(let error):
                print("Error: \(error.localizedDescription)")
            case .initial(_):
                self?.markRead()
            case .update(_, deletions: _, insertions: let insertions, modifications: _):

                if insertions.count > 0 {
                    if UIApplication.shared.applicationState == .active {
                        self?.markRead()
                        self?.playMessageSoundIfNecessary()
                    }
                }
            }
            self?.removePendingMessages()
            self?.delegate?.reloadData()
        }
    }

    func addSnapchat() {
        guard let username = friendship?.user?.snapchat_username else {
            print("Error: could not get snapchat username to add")
            return
        }

        // TODO: the user have snapchat username but his username is not correct
        guard let url = URL(string: "snapchat://add/\(username)") else {
            print("Error: could not get snapchat username to add")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else {
            let backupUrl = URL(string: "https://www.snapchat.com/add/\(username)")!
            UIApplication.shared.openURL(backupUrl)
        }

    }

    /// Sends a message through the socket
    ///
    /// - Parameter message: The text to send or nil to send a random message
    func sendText(_ message:String?) {
        guard let friendshipId = self.friendship?.friendship_id else {
            print("Error: Missing friendship id.")
            return
        }
        let uuid = UUID().uuidString

        // Check that message is not just whitespace/empty lines
        if let messageToSend = message {
            guard messageToSend.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
               return
            }
            // create the pending message
            let pendingMessage = PendingMessage(text: messageToSend, uuid: uuid)
            self.pendingMessages.append(pendingMessage)
            self.delegate?.reloadData()
        }

        let messageText: Any = message ?? NSNull()

        let messageData =  [
            "data": [
                "type": "messages",
                "attributes": [
                    "type": "text",
                    "text": messageText,
                    "uuid": uuid,
                ],
                "relationships": [
                    "friendship": [
                        "data": [
                            "type": "friendships",
                            "id": friendshipId,
                        ]
                    ]
                ]
            ]
        ]

        Socket.shared.send(message: messageData, to: "post_message", completion: { (error, result) in
            guard let result = result else {
                print("Error: Missing result.")
                return
            }

            RealmDataController.shared.apply(JSONAPIDocument(json: result), completion: { result in
                switch result {
                case .error(let error):
                    return error.log()
                case .success(_):
                    break
                }
            })
        })
    }

    /// Makes the API request and returns the parameters necessary for initializing a chat session.
    func initiateCall() {
        guard let friendshipId = self.friendship?.friendship_id else {
            print("Error: Missing friendship id.")
            return
        }
        guard let userId = self.friendship?.user?.user_id else {
            print("Error: Missing user id which makes no sense")
            return
        }

        let parameters: [String: Any] = [
            "data": [
                "type": "videocall",
                "friendship": [
                    "id" : friendshipId,
                    "friend_id": userId,
                    ]
            ]
        ]

		RealmVideoCall.create(method: .post, parameters: parameters) { (result: JSONAPIResult<RealmVideoCall>) in
			switch result {
			case .error(let error):
				// revert fade animation back to screen
				// notify user call failed
				error.log(context: "Create (POST) on an initiated call")
				self.delegate?.callFailedBeforeInitializingChatSession()
			case .success(let videoCall):
				self.delegate?.processRecievedRealmCallFromServer(realmVideoCall: videoCall)
			}
		}
    }

    func playMessageSoundIfNecessary() {
        guard self.messageCount > 0 else {
            return
        }

        // Don't play sound if it's a pending message
        if self.pendingMessages.count > 0 {
            return
        }

        guard let lastSender = self.messages?[messageCount - 1].sender else {
            return
        }

        if lastSender.user_id != APIController.shared.currentUser?.user_id {
            SoundPlayer.shared.play(sound: .message)
        }
    }

    func markRead() {
        guard let lastMessageAt = self.messages?.last?.created_at else {
            return
        }

        self.friendship?.update(attributes: [.last_message_read_at(lastMessageAt)], completion: { (error) in
            error?.log()
        })
    }

    /// This function is called everytime a new RealmMessage object comes in from the server. If we are currently displaying a PendingMessage that matches the new RealmMessage object, it is not longer needed and removed
    func removePendingMessages() {
        // We iterate through the available messages to see if any of the UUID's match the UUID's we have in self.pendingMessages
        // This means it has been returned from the server and can be deleted from the pendingMessages array
        guard let messages = self.messages else {
            print("Attempting to remove a pending message when there are no RealmMessages")
            return
        }
        for message in messages {
            // remove/"filter" out any pendingMessages that have a uuid with the value of message.uuid
            self.pendingMessages = self.pendingMessages.filter({ $0.uuid != message.uuid })
        }

    }

    deinit {
		self.messagesNotificationToken?.invalidate()
    }
}
