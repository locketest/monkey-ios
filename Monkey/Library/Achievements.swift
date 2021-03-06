//
//  Achievements.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/20/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation

/// match mode the user selected
///
/// - TextMode: text mode first
/// - VideoMode: only video mode
public enum MatchMode: String {
	init(string: String) {
		switch string {
		case MatchMode.EventMode.rawValue:
			self = .EventMode
		case MatchMode.TextMode.rawValue:
			self = .TextMode
		case MatchMode.VideoMode.rawValue:
			self = .VideoMode
		case MatchMode.PairMode.rawValue:
			self = .PairMode
		default:
			self = .VideoMode
		}
	}

	case VideoMode = "1"
	case TextMode = "2"
	case EventMode = "3"
	case PairMode = "4"
	
	var backgroundColor: UIColor {
		switch self {
		case .PairMode:
			fallthrough
		case .VideoMode:
			return UIColor.init(red: 100.0 / 255.0, green: 74.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
		case .TextMode:
			fallthrough
		case .EventMode:
			return UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
		}
	}
	
	var titleColor: UIColor {
		switch self {
		case .PairMode:
			fallthrough
		case .VideoMode:
			fallthrough
		case .TextMode:
			return UIColor.white
		case .EventMode:
			return UIColor.init(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1)
		}
	}
	
	var borderColor: CGColor {
		switch self {
		case .PairMode:
			fallthrough
		case .VideoMode:
			fallthrough
		case .TextMode:
			return UIColor.clear.cgColor
		case .EventMode:
			return UIColor.init(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 1.0 / 255.0, alpha: 1).cgColor
		}
	}
	
	var pedding: CGFloat {
		switch self {
		case .PairMode:
			return 120
		case .VideoMode:
			fallthrough
		case .TextMode:
			return 0
		case .EventMode:
			return 14
		}
	}
	
	var title: String {
		switch self {
		case .PairMode:
			return "2P Mode"
		case .VideoMode:
			return "Video Chat"
		case .TextMode:
			return "Text Chat"
		case .EventMode:
			return "Fan Meet"
		}
	}
	
	var emoji: String {
		switch self {
		case .PairMode:
			return "🙌"
		case .VideoMode:
			return "🎦"
		case .TextMode:
			return "💬"
		case .EventMode:
			return "🤩"
		}
	}
}

class Achievements {
	static let shared = Achievements()
	private init() {}
	private let defaults = UserDefaults.standard

	// No longer used but may be saved to user devices
	/*
	var loggedInWithFacebook: Bool {
		set {
			defaults.set(newValue, forKey: "logged_in_with_facebook")
		}
		get {
			return defaults.bool(forKey: "logged_in_with_facebook") == true
		}
	}

	var skippedFacebook: Bool {
		set {
			defaults.set(newValue, forKey: "skipped_facebook")
		}
		get {
			return defaults.bool(forKey: "skipped_facebook") == true
		}
	}
	var facebookReminderSent: Bool {
		set {
			defaults.set(newValue, forKey: "facebook_reminder_sent")
		}
		get {
			return defaults.bool(forKey: "facebook_reminder_sent") == true
		}
	}
	var facebookFriendsInvited: Int {
		set {
			defaults.set(newValue, forKey: "facebook_friends_invited")
		}
		get {
			return defaults.integer(forKey: "facebook_friends_invited")
		}
	}
	var facebookVC:FacebookViewController?
	var shownMagicWand: Bool {
		set {
			defaults.set(newValue, forKey: "shown_magic_wand")
		}
		get {
			return defaults.bool(forKey: "shown_magic_wand") == true
		}
	}
	var autoAcceptCalls: Bool {
		set {
			defaults.set(newValue, forKey: "auto_accept_calls")
		}
		get {
			return defaults.bool(forKey: "auto_accept_calls") == true
		}
	}
	var secretScreenshotAbility: Bool {
		set {
			defaults.set(newValue, forKey: "secret_screenshot_ability")
		}
		get {
			return defaults.bool(forKey: "secret_screenshot_ability") == true
		}
	}
	var shownWelcomePage: Bool {
		set {
			defaults.set(newValue, forKey: "shown_welcome_page")
		}
		get {
			return defaults.bool(forKey: "shown_welcome_page") == true
		}
	}
	var shownReview: Bool {
		set {
			defaults.set(newValue, forKey: "shown_review_\(Environment.version)")
		}
		get {
			return defaults.bool(forKey: "shown_review_\(Environment.version)") == true
		}
	}
	var agreedToTerms: Bool {
		set {
			defaults.set(newValue, forKey: "agreed_to_terms")
		}
		get {
			return defaults.bool(forKey: "agreed_to_terms") == true
		}
	}
	var finishedOnboarding: Bool {
		set {
			defaults.set(newValue, forKey: "isOnboarded")
		}
		get {
			return defaults.bool(forKey: "isOnboarded") == true
		}
	}
	var watchedOnboardingVideo: Bool {
		set {
			defaults.set(newValue, forKey: "watched_onboarding_video")
		}
		get {
			return defaults.bool(forKey: "watched_onboarding_video") == true
		}
	}
	var acceptedFirstCall: Bool {
		set {
			defaults.set(newValue, forKey: "accepted_first_call")
		}
		get {
			return defaults.bool(forKey: "accepted_first_call") == true
		}
	}
	var acceptedCallMatches: Int {
		set {
			defaults.set(newValue, forKey: "accepted_call_matches")
		}
		get {
			return defaults.integer(forKey: "accepted_call_matches")
		}
	}
	var addedFirstMinute: Bool {
		set {
			defaults.set(newValue, forKey: "added_first_minute")
		}
		get {
			return defaults.bool(forKey: "added_first_minute") == true
		}
	}
	var shownNotifs: [NotificationType] {
		set {
			defaults.set(newValue.map({ (notificationType) -> Int in
				notificationType.rawValue
			}), forKey: "shown_notifs")
		}
		get {
			return (defaults.array(forKey: "shown_notifs") as? [Int] ?? [Int]()).map({ (notificationTypeRawValue) -> NotificationType in
				NotificationType(rawValue: notificationTypeRawValue) ?? NotificationType.default
			})
		}
	}
	var loadingBaitEmoji: String? {
		set {
			defaults.set(newValue, forKey: "loading_bait_emoji")
		}
		get {
			return defaults.string(forKey: "loading_bait_emoji")
		}
	}
	var loadingAnimalEmoji: String? {
		set {
			defaults.set(newValue, forKey: "loading_animal_emoji")
		}
		get {
			return defaults.string(forKey: "loading_animal_emoji")
		}
	}
	var invitedSnapchatFriends: Bool {
		set {
			defaults.set(newValue, forKey: "invited_snapchat_friends")
		}
		get {
			return defaults.bool(forKey: "invited_snapchat_friends") == true
		}
	}
	var hashtag: String? {
		set {
			defaults.set(newValue, forKey: "tag_name")
		}
		get {
			return defaults.string(forKey: "tag_name")
		}
	}
	var hashtagId: String? {
		set {
			defaults.set(newValue, forKey: "tag_id")
		}
		get {
			return defaults.string(forKey: "tag_id")
		}
	}
	var matchingMode: String {
		set {
			defaults.set(newValue, forKey: "matching_mode")
		}
		get {
			return defaults.string(forKey: "matching_mode") ?? "discover"
		}
	}
	var invitedFriends: Bool {
		set {
			defaults.set(newValue, forKey: "invited_friends")
		}
		get {
			return defaults.bool(forKey: "invited_friends") == true
		}
	}
	var authorizedFacebookForBonusBananas: Bool {
		set {
			defaults.set(newValue, forKey: "authorized_facebook_for_bonus_bananas")
		}
		get {
			return defaults.bool(forKey: "authorized_facebook_for_bonus_bananas") == true
		}
	}
	/// User has tapped on tutorial for instagramPopupVC
	var shownInstagramTutorial: Bool {
		set {
			defaults.set(newValue, forKey: "shown_instagram_tutorial")
		}
		get {
			return defaults.bool(forKey: "shown_instagram_tutorial") == true
		}
	}

	/// app group
	private let groupDefaults: UserDefaults = UserDefaults.init(suiteName: "group.monkey.ios") ?? shared.defaults
	
	var group_authorization: String? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_authorization")
		}
		get {
			return groupDefaults.string(forKey: "Monkey_authorization")
		}
	}
	var group_first_name: String? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_first_name")
		}
		get {
			return groupDefaults.string(forKey: "Monkey_first_name")
		}
	}
	var group_username: String? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_username")
		}
		get {
			return groupDefaults.string(forKey: "Monkey_username")
		}
	}
	var group_user_id: String? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_user_id")
		}
		get {
			return groupDefaults.string(forKey: "Monkey_user_id")
		}
	}
	var group_birth_date: Double? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_birth_date")
		}
		get {
			return groupDefaults.double(forKey: "Monkey_birth_date")
		}
	}
	var group_gender: String? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_gender")
		}
		get {
			return groupDefaults.string(forKey: "Monkey_gender")
		}
	}
	var group_profile_photo: String? {
		set {
			groupDefaults.set(newValue, forKey: "Monkey_profile_photo_url")
		}
		get {
			return groupDefaults.string(forKey: "Monkey_profile_photo_url")
		}
	}
	*/
	
	/// User has grantedPermission before
	var grantedPermissionsV1: Bool {
		set {
			defaults.set(newValue, forKey: "granted_permissions")
		}
		get {
			return defaults.bool(forKey: "granted_permissions") == true
		}
	}
	var grantedPermissionsV2: Bool {
		set {
			defaults.set(newValue, forKey: "granted_permissions_v2")
		}
		get {
			return defaults.bool(forKey: "granted_permissions_v2") == true
		}
	}
	var promptedNotifications: Bool {
		set {
			defaults.set(newValue, forKey: "prompted_notifications")
		}
		get {
			return defaults.bool(forKey: "prompted_notifications") == true
		}
	}
	var minuteMatches: Int {
		set {
			defaults.set(newValue, forKey: "minute_matches")
		}
		get {
			return defaults.integer(forKey: "minute_matches")
		}
	}
	var unMuteFirstTextMode: Bool {
		set {
			defaults.set(newValue, forKey: "unmute_first_textmode")
		}
		get {
			return defaults.bool(forKey: "unmute_first_textmode") == true
		}
	}
	var unMutedFirstTextMode: Bool {
		set {
			defaults.set(newValue, forKey: "unmuted_first_textmode")
		}
		get {
			return defaults.bool(forKey: "unmuted_first_textmode") == true
		}
	}
	var addFirstSnapchat: Bool {
		set {
			defaults.set(newValue, forKey: "add_first_snapchat")
		}
		get {
			return defaults.bool(forKey: "add_first_snapchat") == true
		}
	}
	var addedFirstSnapchat: Bool {
		set {
			defaults.set(newValue, forKey: "added_first_snapchat")
		}
		get {
			return defaults.bool(forKey: "added_first_snapchat") == true
		}
	}
	var snapchatMatches: Int {
		set {
			defaults.set(newValue, forKey: "snapchat_matches")
		}
		get {
			return defaults.integer(forKey: "snapchat_matches")
		}
	}
	var totalChats: Int {
		set {
			defaults.set(newValue, forKey: "total_chats")
		}
		get {
			return defaults.integer(forKey: "total_chats")
		}
	}
	var isOnboardingExplainAddTimePopupCompleted: Bool {
		set {
			defaults.set(newValue, forKey: "is_onboarding_explain_add_time_popup_completed")
		}
		get {
			return defaults.bool(forKey: "is_onboarding_explain_add_time_popup_completed") == true
		}
	}
	var isOnboardingExplainTheyAddTimePopupCompleted: Bool {
		set {
			defaults.set(newValue, forKey: "is_onboarding_explain_they_add_time_popup_completed")
		}
		get {
			return defaults.bool(forKey: "is_onboarding_explain_they_add_time_popup_completed") == true
		}
	}
	var deeplink_source : String {
		set {
			defaults.set(newValue, forKey: "kDeepLinkSourceValue")
		}
		get {
			return defaults.string(forKey: "kDeepLinkSourceValue") ?? ""
		}
	}
	var registerTime: TimeInterval {
		set {
			defaults.set(newValue, forKey: "MonkeyUserRegisterTime")
		}
		get {
			return defaults.double(forKey: "MonkeyUserRegisterTime")
		}
	}
	var selectMatchMode: MatchMode? {
		set {
			defaults.set(newValue?.rawValue, forKey: "MonkeySelectMatchMode")
			defaults.synchronize()
		}
		get {
			var matchMode: MatchMode?
			if let selectMatchMode = defaults.string(forKey: "MonkeySelectMatchMode") {
				matchMode = MatchMode.init(string: selectMatchMode)
				if matchMode == .VideoMode {

				}else if matchMode == .TextMode {
					if RemoteConfigManager.shared.text_chat_mode == false {
						// 如果 text_mode 没有打开
						self.selectMatchMode = .VideoMode
						matchMode = .VideoMode
					}
				}else {

				}
			}

			return matchMode
		}
	}
    var closeAcceptButton: Bool {
        set {
            defaults.set(newValue, forKey: "MonkeyCloseAcceptButton")
        }
        get {
			if let value = defaults.value(forKey: "MonkeyCloseAcceptButton"), value is Bool {
				return value as! Bool
			}
            return true
        }
    }
	var autoAcceptMatch: Bool {
		set(newAutoAcceptMatch) {
			closeAcceptButton = !newAutoAcceptMatch
		}
		get {
			return !closeAcceptButton
		}
	}
    var nearbyMatch: Bool {
        set {
            defaults.set(newValue, forKey: "MonkeyNearbyMatch")
        }
        get {
            return defaults.bool(forKey: "MonkeyNearbyMatch")
        }
    }
	var selectMonkeyFilter: String {
		set {
			defaults.set(newValue, forKey: "MonkeySelectFilter")
		}
		get {
			return defaults.string(forKey: "MonkeySelectFilter") ?? "Normal"
		}
	}
	var apns_token: String? {
		set {
			defaults.set(newValue, forKey: "apns_token")
		}
		get {
			return defaults.string(forKey: "apns_token")
		}
	}
}
