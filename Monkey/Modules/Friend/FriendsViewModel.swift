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
    func reloadNewFriends()
    func reloadOpenChats()
    func reloadData()
}

class FriendsViewModel {
    
    static var sharedFreindsViewModel = FriendsViewModel()
    
    weak var delegate:FriendsViewModelDelegate?
    
    var friendships: Results<RealmFriendship>? {
        let isNotBlocker = NSPredicate(format: "is_blocker == NO")
        let isNotBlocking = NSPredicate(format: "is_blocking == NO")
        
        let userId = APIController.shared.currentUser?.user_id ?? ""
        
        // Predicates restricting which users come back (we don't want friendships as a result from blocks)
        let isNotCurrentUser = NSPredicate(format: "user.user_id != \"\(userId)\"")
        
        let realm = try? Realm()
        
        return realm?.objects(RealmFriendship.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
            isNotBlocker,
            isNotBlocking,
            isNotCurrentUser
            ]))
    }
    var newFriendsNotificationToken:NotificationToken?
    var openChatsNotificationToken:NotificationToken?
    
    var openChats: Results<RealmFriendship>? {
        let isInConversation = NSPredicate(format: "last_message_at != nil")
        
        //  if last message is nil , use create at
        self.newFriends?.forEach({ (friendShip) in
            if friendShip.last_message_at == nil {
                let realm = try? Realm()
                try? realm?.write({
                    friendShip.last_message_at = friendShip.created_at
                })
            }
        })
        
        let realm = try? Realm()
        let friendships = realm?.objects(RealmFriendship.self).filter(isInConversation).sorted(byKeyPath: "last_message_at", ascending: false)
        return friendships
    }
    
    // TODO: this should be deleted
    var newFriends: Results<RealmFriendship>? {
        let isNotBlocker = NSPredicate(format: "is_blocker == NO")
        let isNotBlocking = NSPredicate(format: "is_blocking == NO")
        let isNotInConversation = NSPredicate(format: "last_message_at == nil")
        
        let realm = try? Realm()
        return realm?.objects(RealmFriendship.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
            isNotInConversation,
            isNotBlocker,
            isNotBlocking,
            ])).sorted(byKeyPath: "created_at", ascending: false)
    }
    
    init() {
        setup()
    }
    
    func setup() {
		self.newFriendsNotificationToken = self.newFriends?.observe { (changes) in
            switch changes {
            case .error(let error):
                print("Error: \(error.localizedDescription)")
            case .initial(_):
                self.delegate?.reloadNewFriends()
            case .update(_, deletions: let deletions, insertions: let insertions, modifications: _):
                if deletions.count > 0 || insertions.count > 0 {
                    self.delegate?.reloadNewFriends()
                }
            }
        }
            
		self.openChatsNotificationToken = self.openChats?.observe { (change) in
            self.delegate?.reloadOpenChats()
        }
    }
    
    func needReloadData(){
        self.delegate?.reloadOpenChats()
    }

    
    func latestMessageForFriendship(friendship: RealmFriendship) -> String {
        let messages = friendship.messages.sorted(byKeyPath: "created_at", ascending: false)
        return messages.first?.text ?? "New Friend! 🎉"
    }
    
    deinit {
		self.openChatsNotificationToken?.invalidate()
		self.newFriendsNotificationToken?.invalidate()
    }
}
