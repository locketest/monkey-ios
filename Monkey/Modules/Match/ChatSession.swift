//
//  ChatSession.swift
//  Monkey
//
//  Created by Isaiah Turner on 11/18/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class ChatSession: NSObject {
    weak var callDelegate: ChatSessionCallDelegate?
    weak var loadingDelegate: ChatSessionLoadingDelegate?

	func commonParameters(for event: AnalyticEvent) -> [String: String] {
//		let currentUser = UserManager.shared.currentUser
//		let is_banned = currentUser?.is_banned ?? false
//        var match_type = "video"
//		let selectMatchMode = Achievements.shared.selectMatchMode ?? .VideoMode
//		if selectMatchMode == .TextMode {
//			match_type = "text"
//		}else if selectMatchMode == .VideoMode {
//			match_type = "video"
//		}else {
//			match_type = "event"
//		}
//
		var commonParameters = [String: String]()
//		commonParameters["user_gender"] = currentUser?.gender ?? ""
//		commonParameters["user_age"] = "\(currentUser?.age ?? 0)"
//		commonParameters["user_country"] = currentUser?.location ?? ""
//		commonParameters["user_ban"] = is_banned ? "true" : "false"
//		commonParameters["match_type"] = match_type
//		commonParameters["auto_accept"] = Achievements.shared.autoAcceptMatch ? "true" : "false"
//		commonParameters["user_gender_option"] = APIController.shared.currentUser?.show_gender ?? "both"
//		commonParameters["user_tree"] = APIController.shared.currentUser?.channels.first?.title ?? ""
//		commonParameters["match_same_tree"] = common_tree
//		commonParameters["nearby_status"] = Achievements.shared.nearbyMatch ? "true" : "false"
//
//		if let _ = self.realmCall, let chat = chat {
//			commonParameters["match_with_gender"] = chat.gender ?? ""
//			commonParameters["match_with_country"] = chat.location ?? ""
//			commonParameters["match_with_age"] = "\(chat.age ?? 0)"
//
//            var match_with_type = "video"
//			let match_with_mode = chat.match_mode
//			if match_with_mode == .TextMode {
//				match_with_type = "text"
//			}else if match_with_mode == .VideoMode {
//				match_with_type = "video"
//			}else {
//				match_with_type = "event"
//			}
//            commonParameters["match_with_type"] = match_with_type
//
//			var match_room_type = "video"
//			if matchMode == .TextMode {
//				match_room_type = "text"
//			}else if matchMode == .VideoMode {
//				match_room_type = "video"
//			}else {
//				match_room_type = "event"
//			}
//			commonParameters["match_room_type"] = match_room_type
//
//			if event == .matchFirstAddFriend {
//				commonParameters["in_15s"] = "\(!self.hadAddTime)"
//			}
//
//			if event == .matchInfo {
//				var match_duration = 0
//				if let connectTime = connectTime {
//					match_duration = Int(Date().timeIntervalSince1970 - connectTime)
//				}
//
//				commonParameters["duration"] = "\(match_duration)"
//				let time_add = ((self.chat?.minutesAdded ?? 0) > 0)
//				commonParameters["time_add"] = "\(time_add)"
//				commonParameters["time_add_success_times"] = "\(min(self.chat?.minutesAdded ?? 0, self.chat?.theirMinutesAdded ?? 0))"
//				commonParameters["friend_add"] = "\(self.chat?.sharedSnapchat ?? false)"
//				commonParameters["firend_add_success"] = "\(self.friendMatched)"
//				commonParameters["report"] = "\(self.isReportedChat)"
//
//				if matchMode == .TextMode {
//					commonParameters["sound_open"] = "\(self.chat?.unMute ?? false)"
//					commonParameters["sound_open_success"] = "\(self.isUnMuteSound)"
//                    commonParameters["message_send"] = "\(self.message_send)"
//                    commonParameters["message_receive"] = "\(self.message_receive)"
//				}
//
//				let filter_title = Achievements.shared.selectMonkeyFilter
//				if filter_title != "Normal" {
//					commonParameters["filter"] = filter_title
//				}
//			}
//		}
//
		return commonParameters
	}

	func track(matchEvent: AnalyticEvent) {
		AnalyticsCenter.log(withEvent: matchEvent, andParameter: commonParameters(for: matchEvent))
	}

	func trackMatchingSession() {
//		guard let chat = chat, let currentUser = APIController.shared.currentUser else {
//			return
//		}
//
//		var Mode_type = "1"
//		if matchMode == .TextMode {
//			Mode_type = "2"
//		}else if matchMode == .EventMode {
//			Mode_type = "3"
//		}
//
//		var match_duration = 0
//		if let connectTime = connectTime {
//			match_duration = Int(Date().timeIntervalSince1970 - connectTime)
//		}
//
//		var report_type = "Non-report"
//		if chat.showReport > 0 {
//			report_type = chat.reportReason?.eventTrackValue() ?? "Cancel"
//		}
//
//		var sessionParameters: [String: Any] = [
//			"duration": match_duration,
//			"friend_add_request": chat.sharedSnapchat ? "1" : "0",
//			"friend_add_success": chat.sharedSnapchat && chat.theySharedSnapchat ? "true" : "false",
//			"matching_report_click": chat.showReport,
//			"matching_report_type": report_type,
//			"matching_switch_camera_click": chat.switch_camera_click,
//			"matching_switch_camera_result": chat.switch_camera_click % 2 == 0 ? "Front" : "back",
//			"Mode_type": Mode_type,
//			"user_tree": APIController.shared.currentUser?.channels.first?.title ?? "",
//			"nearby_status": Achievements.shared.nearbyMatch ? "true" : "false",
//			]
//
//		if friendMatched {
//			sessionParameters["pce out"] = (chat.my_pce_out ? currentUser.user_id : chat.user_id) ?? ""
//		}
//
//		let cuttentFilter = Achievements.shared.selectMonkeyFilter
//		if matchMode == .TextMode {
//			sessionParameters["sound_open_click"] = chat.unMute ? "true" : "false"
//			sessionParameters["sound_open_success"] = chat.unMute && chat.theyUnMute ? "true" : "false"
//			sessionParameters["message_send"] = chat.sendedMessage
//			sessionParameters["message_receive"] = chat.receivedMessage
//		}else if matchMode == .VideoMode {
//			sessionParameters["matching_vfilter_click"] = chat.initialFilter == cuttentFilter ? "keep" : "Change"
//			sessionParameters["matching_vfilter_info"] = cuttentFilter
//			sessionParameters["time_add_count"] = chat.minutesAdded
//			sessionParameters["time_add_success_times"] = min(chat.minutesAdded, chat.theirMinutesAdded)
//		}
//
//		AnalyticsCenter.log(withEvent: .matchingSession, andParameter: sessionParameters)
	}

    required init(apiKey: String, sessionId: String, chat: Chat, token: String, loadingDelegate: ChatSessionLoadingDelegate, isDialedCall: Bool) {
        super.init()

    }
}

/**
 ChatSessionStatus describes how the view should appear
*/
enum ChatSessionStatus {
    ///The chat session should be released, it's not going to connect to anyone. Get a new chat.
    case consumed
    ///The chat session should be released, it's not going to connect to anyone. Get a new chat after accepting user input.
    case consumedWithError
    ///The chat is connecting and for a period of time can be skipped
    case skippable
    ///The chat is connected and the video screen should be shown
    case connected
    ///The chat is developing the initial connection and the loading view should be show
    case loading
    ///The chat is about to be consumed but still has something to do (like open snapchat). Don't make a new chat yet.
    case disconnecting
}

/**
 ChatSessionDelegate enum description
 */
protocol ChatSessionCallDelegate: class {
	func friendMatched(in chatSession: ChatSession?)
	func minuteAdded(in chatSession: ChatSession)
	func soundUnMuted(in chatSession: ChatSession)
    func opponentDidTurnToBackground(in chatSession: ChatSession)

	func received(textMessage: TextMessage, in chatSession: ChatSession)
}

@objc protocol ChatSessionLoadingDelegate: class {
    func presentCallViewController(for chatSession: ChatSession)
    func dismissCallViewController(for chatSession: ChatSession)
    func chatSession(_ chatSession: ChatSession, callEndedWithError error: Error?)
	func shouldShowConnectingStatus(in chatSession: ChatSession)
    @objc optional func warnConnectionTimeout(in chatSession: ChatSession)
}
