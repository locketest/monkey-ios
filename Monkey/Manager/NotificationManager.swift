//
//  NotificationManager.swift
//  Monkey
//
//  Created by Philip Bernstein on 7/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import UserNotifications
import UserNotificationsUI
import RealmSwift
import Alamofire

protocol SlideViewManager:class {
    func shouldShowNotification()->Bool
    func shouldExecuteNotification()->Bool
}

let EmojiNotificationKey:String = "e"
let TypeNotificationKey:String = "n"
let URLSNotificationKey:String = "u"
let TextNotificationKey:String = "t"
let APSNotificationKey:String = "aps"

class NotificationManager {
    static let shared = NotificationManager()
    weak var viewManager: SlideViewManager?
    weak var chatSessionLoadingDelegate: ChatSessionLoadingDelegate?
    var friendships:Results<RealmFriendship>?
    weak var showingNotification:MessageNotificationView?
    
    private init() {
        let realm = try? Realm()
        self.friendships = realm?.objects(RealmFriendship.self)
    }
    
    /// Takes in any dictionary that represents a notification and creates and displays a corresponding notification view. Notification dictionary must have a value for key 'u'
    func handleNotification(_ notification:[AnyHashable:Any]) {
        
        if notification["n"] as? Int == 8 {
            return
        }
        
        let constructedNotification = AppNotification(notification)
        
        guard let urlString = constructedNotification.urls?.first, let url = URL(string:urlString) else {
            return
        }

        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL:false)
        
        /// Guards against an incoming call notification, will make more specific once we link to specific messages in a conversation (or other parameters start coming back)
        guard urlComponents?.queryItems == nil || urlComponents?.queryItems?.count == 0 else {
            return
        }
        
        
        guard constructedNotification.urls != nil, constructedNotification.urls?.count != 0 else {
            return
        }
        
        guard self.viewManager?.shouldShowNotification() == true else {
            return
        }
        
        self.showNotification(constructedNotification)
    }
    
    /// Creates a notification view from an AppNotification (struct representing notification data) and displays it on the screen. The MessageNotificationView manages its own dismissal.
    private func showNotification(_ notification:AppNotification) {
        let notificationView = MessageNotificationView.instanceFromNib()
        
        let frame = CGRect(x: 0, y: -94, width: UIScreen.main.bounds.width, height: 94)
        notificationView.frame = frame
        
        guard let url = notification.urls?.first else {
            return
        }
        
        let friendshipId = self.friendshipIdFromURL(url)
        
        guard !friendshipId.isEmpty else {
            return
        }
        
        let filter = NSPredicate(format:"friendship_id == \"\(friendshipId)\"")
        
        guard let friendship = self.friendships?.filter(filter).first else {
            return
        }
		
		var imageName = "ProfileImageDefaultMale"
		if friendship.user?.gender == Gender.female.rawValue {
			imageName = "ProfileImageDefaultFemale"
		}
		notificationView.profileImageView.placeholder = imageName
		notificationView.profileImageView.url = friendship.user?.profile_photo_url

        if let firstName = friendship.user?.first_name {
            notificationView.profileNameLabel.text = firstName
        } else if let username = friendship.user?.username {
            notificationView.profileNameLabel.text = username
        } else if let snapchat = friendship.user?.snapchat_username {
            notificationView.profileNameLabel.text = snapchat
        } else {
            notificationView.profileNameLabel.text = "Your friend"
        }
        
        notificationView.onTap = { [weak self] in
            self?.executeNotification(notification)
        }
        
        notificationView.onSwipeUp = { [weak self] in
            self?.dismissNotification(notification)
        }
        
        if let pastNotification = self.showingNotification {
            notificationView.onShow = {
                pastNotification.removeFromSuperview()
            }
        }
        
        notificationView.notificationDescriptionLabel.text = "sent you a new message"
        notificationView.show()
        TapticFeedback.impact(style:.light)
        
        self.showingNotification = notificationView
    }
    
    /// Called from main vc for now (in future, callvc), shows a notification allowing a user to rate the call passed in as 'chatId' as nice or mean
    func showRatingNotification(_ chatSession:ChatSession, completion:@escaping ()->Void) {
       // self.viewManager?.stopFindingChats(andDisconnect: false, forReason: "notification")
        guard let chat = chatSession.chat else {
            return
        }

        let ratingNotification = RatingNotificationView.instanceFromNib()
        if let pastNotification = self.showingNotification {
            ratingNotification.onShow = {
                pastNotification.removeFromSuperview()
            }
        }
        
        ratingNotification.profileNameLabel.text = "Rate your last match"
        
        let chatId = chat.chatId
        
        ratingNotification.onRate = { [unowned self] (rating) in
            ratingNotification.isUserInteractionEnabled = false // Prevent double tapping buttons
            self.rateFriendship(rating, chatId: chatId)
            ratingNotification.dismiss()
        }
        
        ratingNotification.onSwipeUp = {
            completion()
        }
        
        ratingNotification.onDismiss = {
            completion()
        }
        
        ratingNotification.show()
        self.showingNotification = ratingNotification
    }
    
    /// Called from the MessageNotificationView that has been displayed, it is called on to execute the notification attached to its view. For now, this method calls for the application delegate to handle the url ope
    private func executeNotification(_ notification:AppNotification) {
        guard let conversationUrlString = notification.urls?.first else {
            return
        }
        
        guard self.viewManager?.shouldExecuteNotification() == true else {
            return
        }
        
        let url = URL(string: conversationUrlString)!
        (UIApplication.shared.delegate as? AppDelegate)?.handleOpen(url: url)
    }
    
    /// Empty for now, this method is called by a MessageNotificationView that has been swiped up or dismissed on its 4 second timeout
    private func dismissNotification(_ notification: AppNotification) {
        
    }
    
    /// Pulls the friendship ID from a url string, provided by the notification dictionary.
    private func friendshipIdFromURL(_ url:String) -> String {
        return url.components(separatedBy: "/").last ?? ""
    }
    
    private func rateFriendship(_ rating:ChatRating, chatId:String) {
        let paramaters = [
            "data": [
                "type": "chats",
                "id": chatId,
                "attributes": [
                    "rating": rating.rawValue
                ],
            ]
        ]
        
        JSONAPIRequest(url: "\(Environment.baseURL)/api/v1.0/chats/\(chatId)", method: .patch, parameters: paramaters, options: [
            .header("Authorization", APIController.authorization),
            ]).addCompletionHandler { (result) in
                switch result {
                case .error(let error):
                    error.log()
                case .success(_):
                    break
                }
        }
    }
    
    func showCallNotification(chatSession:ChatSession, completion: @escaping (_ result:CallResponse)->Void)->CallNotificationView {
        
         let notification = CallNotificationView.instanceFromNib()
        notification.chatSession = chatSession
        
        if let userID = chatSession.chat?.user_id {
            let realm = try? Realm()
            let filter = NSPredicate(format:"user_id == \"\(userID)\"")
            let user = realm?.objects(RealmUser.self).filter(filter).first
			
			var imageName = "ProfileImageDefaultMale"
			if user?.gender == Gender.female.rawValue {
				imageName = "ProfileImageDefaultFemale"
			}
			notification.profileImageView.placeholder = imageName
			notification.profileImageView.url = user?.profile_photo_url

            notification.profileNameLabel.text = user?.first_name ?? "Your friend"
        }
        
        notification.notificationDescriptionLabel.text = "video call"
        
        notification.onAccept = {
            completion(.accepted)
        }
        notification.onSwipeUp = {
            completion(.declined)
        }

        if let pastNotification = self.showingNotification {
            notification.onShow = {
                pastNotification.removeFromSuperview()
            }
        }
        
        notification.show()
        notification.callButton.isJiggling = true
        showingNotification?.dismiss()
        showingNotification = notification
        
        return notification
    }
}

enum ChatRating:String {
    case nice = "NICE"
    case mean = "MEAN"
    case neutral = "NEUTRAL"
}

struct AppNotification {
    let emoji:String?
    let type:String?
    let text:String?
    let urls:[String]?
    
    init(emoji:String?, type:String?, text:String?, urls:[String]?) {
        self.emoji = emoji
        self.type = type
        self.text = text
        self.urls = urls
    }
    
    init(_ notification:[AnyHashable:Any]) {
        let emoji = notification[EmojiNotificationKey] as? String
        let type = notification[TypeNotificationKey] as? String
        let urls = notification[URLSNotificationKey] as? [String] ?? [String]()
        let text = notification[TextNotificationKey] as? String
        self.init(emoji: emoji, type: type, text: text, urls: urls)
    }
}
