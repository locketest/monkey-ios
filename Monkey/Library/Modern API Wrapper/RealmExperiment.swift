//
//  RealmExperiment.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/23/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift
import Alamofire

class RealmExperiment: MonkeyModel {
	
	override class var type: String {
		return ApiType.Experiment.rawValue
	}
	override class func primaryKey() -> String {
		return "experiment_id"
	}
	override class var requst_subfix: String {
		return "\(self.type)/\(Environment.appVersion)"
	}
    
    /// The user_id that authenticated the request for this Experiment.
    dynamic var experiment_id: String?
    // MARK: Experiment strings
    let enable_snapcodes = RealmOptional<Bool>()
    
    /// The phone number to compose a text message to when tapping the "Contact Us" button.
    dynamic var support_phone:String?
    /// The list of facts to cycle through while waiting for chats.
    // dynamic var facts:[String]?
    /// Locales which should be shown the SMS invite friends screen.
    // dynamic var invite_friends:[String]? // Not possible until realm/realm-cocoa#1120 is closed
    /// The minimum version of the app (as specified in Constants.swift)
    let minimum_version = RealmOptional<Int>()
    /// A link to find a nearby nursing home. Unused code used to ban people over the age of 22.
    dynamic var nursing_home_url:String?
    /// The default text to compose to a friend after tapping "Edit Text" on the Invite Friends onboarding page.
    dynamic var sms_invite_text:String?
    /// The default text to compose to a friend after tapping the invite friends button via Settings/MainViewController
    dynamic var sms_invite_friends:String?
    /// The text to display males above the invite friends onboarding page prior to selected the first friend.
    dynamic var male_invite_text:String?
    /// The text to display females above the invite friends onboarding page prior to selected the first friend.
    dynamic var female_invite_text:String?
    /// Unknown purpose.
    dynamic var terms:String?
    /// The hashtag everyone should use by default on Monkey.
    dynamic var default_hashtag:String?
    /// Terms & Conditions to display in a popup with only an "Agree" button after completing the onboarding.
    let onboarding_terms = RealmOptional<Bool>()
    /// An optional link to app credits to display under the Settings legal page.
    dynamic var credits_url:String?
    /// Unknown purpose.
    dynamic var add_friends_details:String?
    /// The phone number to compose a support text to when tapping "Think it's a mistake?" on the banned page.
    @available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    dynamic var banned_phone:String?
    /// Controls how long to wait on the connecting page before giving up and skipping.
    let skip_time = RealmOptional<Double>()
    /// Toggles whether the skip button is transparent until 3 friends are selected on the Invite Friends onboarding page.
    let invite_next_button_transparent = RealmOptional<Bool>()
    /// Toggles wether the skip button can be tapped before 3 friends are selected ont eh Invite Friends onboarding page.
    let invite_next_button_required = RealmOptional<Bool>()
    /// Toggles wether contacts that contain emojis should be invited automatically.
    let ec = RealmOptional<Bool>()
    /// Toggles wether sexuality (show male or female) data should be collected.
    @available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    let sexuality_gender_page_enabled = RealmOptional<Bool>()
    /// Toggles wether calls can be force accepted (e.g. by admins) without tapping the "Accept" button.
    let allow_being_force_accepted = RealmOptional<Bool>()
    /// The time each call should initially start with.
    let call_time = RealmOptional<Int>()
    /// The text to display in the skip button. Usually, Skip or Skip and Decline.
    dynamic var skip_text:String?
    /// The next fact to display before the user completes certain actions (such as completing a call). When tapped, MAY play onboarding video.
    dynamic var onboarding_fact_text:String?
    /// The description of the report reason selection popup.
    dynamic var report_warning_text:String?
    /// The text to display to a blocked user.
    dynamic var blocked_text:String?
    /// A boolean to enable or disable the default onboarding video.
    let onboarding_video = RealmOptional<Bool>()
    /// A link to a video to play automatically after the onboarding.
    @available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    dynamic var onboarding_video_url:String?
    /// The default time to wait for video and audio streams to be established before giving up on a call and skipping automatically.
    let call_loading_timeout = RealmOptional<Double>()
    /// The warning message to display while pausing matching when the user fails to "Accept" or "Skip" a call within a reasonable amount of time.
    let ignored_call_warning = RealmOptional<Double>()
    /// How long to wait before trying to get a new call after tapping "Skip"
    let next_call_delay = RealmOptional<Double>()
    /// Toggles wether contacts that contain emojis should be invited automatically.
    @available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    let invite_emoji_contacts = RealmOptional<Bool>()
    /// The Facebook app id to use for Facebook login.
    dynamic var facebook_app_id:String?
    /// The text to display in the popup requesting the user signs in with Facebook.
    dynamic var facebook_popup_text:String?
    /// The URL to redirect to after signing in with Facebook.
    dynamic var facebook_redirect_url:String?
    /// Toggles wether to prompt for a reason after submitting a report.
    // dynamic var reports_reason_enabled:[Int]? // Not possible until realm/realm-cocoa#1120 is closed
    /// The title of the reports reason prompt.
    dynamic var reports_reason_title:String?
    /// The description of the reports reason prompt.
    dynamic var reports_reason_description:String?
    /// The placeholder text of the reports reason prompt.
    dynamic var reports_reason_placeholder:String?
    /// The submit button title of the reports reason prompt.
    dynamic var reports_reason_submit:String?
    /// The cancel button title of the reports reason prompt.
    dynamic var reports_reason_cancel:String?
    /// An array of notifications to display at various points during the onboarding process.
    //@available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    // dynamic var onboarding_reminder_notifications:[String:[AnyHashable:Any]]? // Not possible until realm/realm-cocoa#1120 is closed
    /// How long to count down on the snapchat invite friends page before dismissing.
    let snapchat_popup_countdown_time = RealmOptional<Int>()
    /// A URL to the image to share via Snapchat when inviting friends through the Snapchat popup.
    dynamic var snapchat_popup_image_url:String?
    /// The text to display in the snapchat invite friends popup.
    dynamic var snapchat_popup_text:String?
    /// The age to select initially during the onboarding. Must be between 13 and 169 (the valid age range).
    let default_age = RealmOptional<Int>()
    /// The width in pixels to base the drawing view off of.
    let drawing_view_width = RealmOptional<Int>()
    /// The first fact to show when opening the app.
    dynamic var initial_fact_discover:String?
    /// dynamic var initial_fact_friends:String?
    dynamic var banned_url:String?
    /// The Opentok API key.
    dynamic var opentok_api_key:String?
    /// The emoji used for the loading page.
    @available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    dynamic var base_loading_emoji:String?
    /// The emoji used for the loading page.
    @available(*, unavailable, message: "Removed prior to Monkey 2.0.4")
    dynamic var chase_loading_emoji:String?
    /// The base emoji to display on the friends page when the user has no friendships.
    dynamic var base_no_messages_emoji:String?
    /// The chase emoji to display on the friends page when the user has no friendships.
    dynamic var chase_no_messages_emoji:String?
    /// The URL for the form to request changes to your profile beyond what is user modifiable
    dynamic var edit_account_request_url:String?
    /// The message displayed below the "talk to" alert in the gender selector.
    dynamic var talk_to_alert_message:String?
    /// The URL we callback to after a successful instagram login (the url is sent with the loaded instagram url)
    dynamic var instagram_login_url:String?
	/// when user launch app, should jump to download monkeychat
	dynamic var monkeychat_link:String?
    dynamic var mc_invite_desc:String?
    dynamic var mc_invite_btn_pos_text:String?
	
	required convenience init?(map: Map) {
		self.init()
	}
}
