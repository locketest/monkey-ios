//
//  FriendsViewModel.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift

protocol FriendsViewModelDelegate: class {
	func reloadFriendships()
}

class FriendsViewModel {
	
	static var sharedFreindsViewModel = FriendsViewModel()
	weak var delegate: FriendsViewModelDelegate?
	private var friendshipsNotificationToken: NotificationToken?
	
	private init() {}
	
	func setup() {
		self.friendshipsNotificationToken = self.friendships?.observe { (change) in
			self.delegate?.reloadFriendships()
		}
		self.refreshMessageList()
		self.refreshFriendships()
	}
	
	func reset() {
		self.currentMessagesJSONAPIRequest?.cancel()
		self.currentFriendshipsJSONAPIRequest?.cancel()
		self.friendshipsNotificationToken?.invalidate()
	}
	
	private weak var currentMessagesJSONAPIRequest: JSONAPIRequest?
	private weak var currentFriendshipsJSONAPIRequest: JSONAPIRequest?
	private func refreshMessageList() {
		self.currentMessagesJSONAPIRequest?.cancel()
		self.currentMessagesJSONAPIRequest = RealmMessage.fetchAll { (result: JSONAPIResult<[RealmMessage]>) in
			switch result {
			case .success(_):
				break
			case .error(let error):
				error.log(context: "RealmMessage sync failed")
			}
		}
	}
	
	private func refreshFriendships() {
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
					} catch (_) {
						APIError.unableToSave.log(context: "Deleting old friendships.")
					}
				}
			case .error(let error):
				error.log(context: "RealmFriendship sync failed")
			}
		}
	}
	
	var friendships: Results<RealmFriendship>? {
		let userId = APIController.shared.currentUser?.user_id ?? ""
		// Predicates restricting which users come back (we don't want friendships as a result from blocks)
		let isNotCurrentUser = NSPredicate(format: "user.user_id != \"\(userId)\"")
		let isNotBlocker = NSPredicate(format: "is_blocker == NO")
		let isNotBlocking = NSPredicate(format: "is_blocking == NO")
		
		let realm = try? Realm()
		let friendships  = realm?.objects(RealmFriendship.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
			isNotCurrentUser,
			isNotBlocker,
			isNotBlocking,
			])).sorted(byKeyPath: "last_message_at", ascending: false)
		return friendships
	}
	
	func latestMessageForFriendship(friendship: RealmFriendship) -> String {
		let messages = friendship.messages.sorted(byKeyPath: "created_at", ascending: false)
		return messages.first?.text ?? "New Friend! 🎉"
	}
	
	deinit {
		self.friendshipsNotificationToken?.invalidate()
	}
}
