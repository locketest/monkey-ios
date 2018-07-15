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
import ObjectMapper

protocol ChatViewModelDelegate: class {
	func reloadData()
	func callFailed()
	func callSuccess(videoCall: VideoCallModel)
}

/// Represents a message that has been created locally and is currently being sent to server.
/// It is used to display pending messages until their equivilant RealmMessage is returned from the server
struct PendingMessage {
	/// The message text being sent
	var text: String
	/// The user who sent the message
	let sender: RealmUser? = APIController.shared.currentUser
	/// An identifier used to match against RealmMessages returned from the server. If there is a match we remove from pending messages array
	var uuid: String
	init(text: String, uuid:String) {
		self.text = text
		self.uuid = uuid
	}
}

class ChatViewModel {
	
	var messages: Results<RealmMessage>?
	/// An array of PendingMessages used to instanteneously display messages while they are processed on the server.
	/// Once the server returns the equivilant RealmMessage, the pending message is deleted so that the actual RealmMessage can be displayed instead.
	var pendingMessages: [PendingMessage] = []
	
	/// Returns the message count. If there are any pendingMessages, add their count to the messageCount
	var messageCount: Int {
		return messages.count + pendingMessages.count
	}
	
	weak var delegate: ChatViewModelDelegate?
	
	private var messagesNotificationToken: NotificationToken?
	/// The id of the friendship the chat model is managing. Allows for threadsafe realm getter
	var friendshipId: String? {
		didSet{
			guard let friendship = self.friendship else{
				print("Error: ChatViewModel unable to retrieve friendship from realm on didSet")
				return
			}
			self.setupFriendship(friendship)
		}
	}
	
	/// Friendship object between user and who chat is with
	var friendship: RealmFriendship? {
		get {
			let realm = try? Realm()
			return realm?.object(ofType: RealmFriendship.self, forPrimaryKey: friendshipId)
		}
	}
	
	var userLastOnlineAtString: String {
		if let lastOnlineAt: TimeInterval = friendship?.user?.last_online_at?.timeIntervalSinceNow {
			var secondsSinceOnline: TimeInterval = max(lastOnlineAt, friendship?.last_message_received_at?.timeIntervalSinceNow ?? -TimeInterval.greatestFiniteMagnitude)
			var localizedTime: String = ""
			let seconds: TimeInterval = 60
			let hours: TimeInterval = 60
			let days: TimeInterval = 24
			
			secondsSinceOnline = -secondsSinceOnline
			if secondsSinceOnline > seconds * hours * days * 2 {
				localizedTime = "A few days ago"
			} else if secondsSinceOnline > seconds * hours * days {
				let daysAgo: Int = Int(secondsSinceOnline / (seconds * hours * days))
				let plurality: String = daysAgo > 1 ? "s" : ""
				localizedTime = "\(daysAgo) day\(plurality) ago"
			} else if secondsSinceOnline > seconds * hours {
				let hoursAgo: Int = Int(secondsSinceOnline / (seconds * hours))
				let plurality: String = hoursAgo > 1 ? "s" : ""
				localizedTime = "\(hoursAgo) hour\(plurality) ago"
			} else if secondsSinceOnline > seconds {
				let minutesAgo: Int = Int(secondsSinceOnline / seconds)
				let plurality: String = minutesAgo > 1 ? "s" : ""
				localizedTime = "\(minutesAgo) minute\(plurality) ago"
			} else {
				localizedTime = "Online"
			}
			
			return localizedTime
		}
		
		return "A few days ago"
	}
	
	func setupFriendship(_ friendship: RealmFriendship) {
		
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
			self?.clearPeddingMessage()
			self?.delegate?.reloadData()
		}
	}
	
	func addSnapchat() {
		guard let snapchat_username = friendship?.user?.snapchat_username else {
			print("Error: could not get snapchat username to add")
			return
		}
		
		guard let url = URL(string: "snapchat://add/\(snapchat_username)") else {
			print("Error: could not get snapchat username to add")
			return
		}
		
		if UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.openURL(url)
		} else if let backupUrl = URL(string: "https://www.snapchat.com/add/\(snapchat_username)") {
			UIApplication.shared.openURL(backupUrl)
		}
	}
	
	/// Sends a message through the socket
	///
	/// - Parameter message: The text to send or nil to send a random message
	func sendText(_ message: String?) {
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
		
		Socket.shared.send(message: messageData, to: "post_message")
	}
	
	/// Makes the API request and returns the parameters necessary for initializing a chat session.
	func initiateCall() {
		guard let userId = self.friendship?.user?.user_id else {
			print("Error: Missing user id which makes no sense")
			return
		}
		
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/\(ApiType.Videocall.rawValue)/request/\(userId)", method: .post) { (result: JSONAPIResult<[String: Any]>) in
			switch result {
			case .error(let error):
				// revert fade animation back to screen
				// notify user call failed
				error.log(context: "Create (POST) on an initiated call")
				self.delegate?.callFailed()
			case .success(let responseJSON):
				if let videoCall = self.parsed(response: responseJSON) {
					self.delegate?.callSuccess(videoCall: videoCall)
				}
			}
		}
	}
	
	func parsed(response: [String: Any]) -> VideoCallModel? {
		
		var callDic: [String: Any] = response
		let friend_id = callDic["friend_id"] as? Int
		let friend: [String: Any] = [
			"id": friend_id as Any
		]
		callDic["friend"] = friend
		callDic["match_id"] = friend_id
		
		var videoCall: VideoCallModel?
		if let parsedCall = Mapper<VideoCallModel>().map(JSON: callDic) {
			videoCall = parsedCall
			videoCall?.call_out = true
		}
		return videoCall
	}
	
	/// Makes the API request and returns the parameters necessary for initializing a chat session.
	func cancelCall() {
		guard let userId = self.friendship?.user?.user_id else {
			print("Error: Missing user id which makes no sense")
			return
		}
		
		MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/\(ApiType.Videocall.rawValue)/cancel/\(userId)", method: .post) { (_) in
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
		
		// 消息有发送者
		guard let lastSender = self.messages?.last?.sender else {
			return
		}
		
		// 对方发送的消息
		if lastSender.user_id != UserManager.UserID {
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
	func clearPeddingMessage() {
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
