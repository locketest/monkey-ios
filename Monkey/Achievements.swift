//
//  Achievements.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/20/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation
class Achievements {
    static let shared = Achievements()
    private let defaults = UserDefaults.standard
    private init() {}
    
    // No longer used but may be saved to user devices
    /*
     var loggedInWithFacebook:Bool {
         set {
             defaults.set(newValue, forKey: "logged_in_with_facebook")
         }
         get {
             return defaults.bool(forKey: "logged_in_with_facebook") == true
             }
          }
 
     var skippedFacebook:Bool {
         set {
             defaults.set(newValue, forKey: "skipped_facebook")
         }
         get {
             return defaults.bool(forKey: "skipped_facebook") == true
         }
     }
    var facebookReminderSent:Bool {
        set {
             defaults.set(newValue, forKey: "facebook_reminder_sent")
         }
         get {
             return defaults.bool(forKey: "facebook_reminder_sent") == true
         }
     }
     var facebookFriendsInvited:Int {
         set {
             defaults.set(newValue, forKey: "facebook_friends_invited")
         }
         get {
             return defaults.integer(forKey: "facebook_friends_invited")
         }
     }
     var facebookVC:FacebookViewController?
  */
    var shownMagicWand:Bool {
        set {
            defaults.set(newValue, forKey: "shown_magic_wand")
        }
        get {
            return defaults.bool(forKey: "shown_magic_wand") == true
        }
    }
    /*
     var autoAcceptCalls:Bool {
         set {
             defaults.set(newValue, forKey: "auto_accept_calls")
         }
         get {
            return defaults.bool(forKey: "auto_accept_calls") == true
         }
     }
    */
    /// User has tapped on tutorial for instagramPopupVC
    var shownInstagramTutorial:Bool {
        set {
            defaults.set(newValue, forKey: "shown_instagram_tutorial")
        }
        get {
            return defaults.bool(forKey: "shown_instagram_tutorial") == true
        }
    }

    var secretScreenshotAbility:Bool {
        set {
            defaults.set(newValue, forKey: "secret_screenshot_ability")
        }
        get {
            return defaults.bool(forKey: "secret_screenshot_ability") == true
        }
    }
    var shownWelcomePage:Bool {
        set {
            defaults.set(newValue, forKey: "shown_welcome_page")
        }
        get {
            return defaults.bool(forKey: "shown_welcome_page") == true
        }
    }
    var invitedFriends:Bool {
        set {
            defaults.set(newValue, forKey: "invited_friends")
        }
        get {
            return defaults.bool(forKey: "invited_friends") == true
        }
    }
    var shownReview:Bool {
        set {
            defaults.set(newValue, forKey: "shown_review_\(Environment.version)")
        }
        get {
            return defaults.bool(forKey: "shown_review_\(Environment.version)") == true
        }
    }
    
    var agreedToTerms:Bool {
        set {
            defaults.set(newValue, forKey: "agreed_to_terms")
        }
        get {
            return defaults.bool(forKey: "agreed_to_terms") == true
        }
    }
    var grantedPermissionsV1:Bool {
        set {
            defaults.set(newValue, forKey: "granted_permissions")
        }
        get {
            return defaults.bool(forKey: "granted_permissions") == true
        }
    }
    var grantedPermissionsV2:Bool {
        set {
            defaults.set(newValue, forKey: "granted_permissions_v2")
        }
        get {
            return defaults.bool(forKey: "granted_permissions_v2") == true
        }
    }
    var promptedNotifications:Bool {
        set {
            defaults.set(newValue, forKey: "prompted_notifications")
        }
        get {
            return defaults.bool(forKey: "prompted_notifications") == true
        }
    }
    var finishedOnboarding:Bool {
        set {
            defaults.set(newValue, forKey: "isOnboarded")
        }
        get {
            return defaults.bool(forKey: "isOnboarded") == true
        }
    }
    var watchedOnboardingVideo:Bool {
        set {
            defaults.set(newValue, forKey: "watched_onboarding_video")
        }
        get {
            return defaults.bool(forKey: "watched_onboarding_video") == true
        }
    }
    var acceptedFirstCall:Bool {
        set {
            defaults.set(newValue, forKey: "accepted_first_call")
        }
        get {
            return defaults.bool(forKey: "accepted_first_call") == true
        }
    }
    var acceptedCallMatches:Int {
        set {
            defaults.set(newValue, forKey: "accepted_call_matches")
        }
        get {
            return defaults.integer(forKey: "accepted_call_matches")
        }
    }
    var addedFirstMinute:Bool {
        set {
            defaults.set(newValue, forKey: "added_first_minute")
        }
        get {
            return defaults.bool(forKey: "added_first_minute") == true
        }
    }
//    var shownNotifs:[NotificationType] {
//        set {
//            defaults.set(newValue.map({ (notificationType) -> Int in
//                notificationType.rawValue
//            }), forKey: "shown_notifs")
//        }
//        get {
//            return (defaults.array(forKey: "shown_notifs") as? [Int] ?? [Int]()).map({ (notificationTypeRawValue) -> NotificationType in
//                NotificationType(rawValue: notificationTypeRawValue) ?? NotificationType.default
//            })
//        }
//    }
    var minuteMatches:Int {
        set {
            defaults.set(newValue, forKey: "minute_matches")
        }
        get {
            return defaults.integer(forKey: "minute_matches")
        }
    }
    var addedFirstSnapchat:Bool {
        set {
            defaults.set(newValue, forKey: "added_first_snapchat")
        }
        get {
            return defaults.bool(forKey: "added_first_snapchat") == true
        }
    }
    var snapchatMatches:Int {
        set {
            defaults.set(newValue, forKey: "snapchat_matches")
        }
        get {
            return defaults.integer(forKey: "snapchat_matches")
        }
    }
    var totalChats:Int {
        set {
            defaults.set(newValue, forKey: "total_chats")
        }
        get {
            return defaults.integer(forKey: "total_chats")
        }
    }
    
    var loadingBaitEmoji:String? {
        set {
            defaults.set(newValue, forKey: "loading_bait_emoji")
        }
        get {
            return defaults.string(forKey: "loading_bait_emoji")
        }
    }
    var loadingAnimalEmoji:String? {
        set {
            defaults.set(newValue, forKey: "loading_animal_emoji")
        }
        get {
            return defaults.string(forKey: "loading_animal_emoji")
        }
    }
    var invitedSnapchatFriends:Bool {
        set {
            defaults.set(newValue, forKey: "invited_snapchat_friends")
        }
        get {
            return defaults.bool(forKey: "invited_snapchat_friends") == true
        }
    }
    var matchingMode:String {
        set {
            defaults.set(newValue, forKey: "matching_mode")
        }
        get {
            return defaults.string(forKey: "matching_mode") ?? "discover"
        }
    }
    var hashtag:String? {
        set {
            defaults.set(newValue, forKey: "tag_name")
        }
        get {
            return defaults.string(forKey: "tag_name")
        }
    }
    var hashtagId:String? {
        set {
            defaults.set(newValue, forKey: "tag_id")
        }
        get {
            return defaults.string(forKey: "tag_id")
        }
    }
    var isOnboardingExplainAddTimePopupCompleted:Bool {
        set {
            defaults.set(newValue, forKey: "is_onboarding_explain_add_time_popup_completed")
        }
        get {
            return defaults.bool(forKey: "is_onboarding_explain_add_time_popup_completed") == true
        }
    }
    var isOnboardingExplainTheyAddTimePopupCompleted:Bool {
        set {
            defaults.set(newValue, forKey: "is_onboarding_explain_they_add_time_popup_completed")
        }
        get {
            return defaults.bool(forKey: "is_onboarding_explain_they_add_time_popup_completed") == true
        }
    }
    
    var authorizedFacebookForBonusBananas:Bool {
        set {
            defaults.set(newValue, forKey: "authorized_facebook_for_bonus_bananas")
        }
        get {
            return defaults.bool(forKey: "authorized_facebook_for_bonus_bananas") == true
        }
    }
}
