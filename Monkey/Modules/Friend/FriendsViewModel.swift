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
	var friendshipsNotificationToken: NotificationToken?

	private init() {
		setup()
	}

	func setup() {
		self.friendshipsNotificationToken = self.friendships?.observe { (change) in
			self.delegate?.reloadFriendships()
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
