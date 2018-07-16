
//  Environment.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/17/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation
import UIKit
import DeviceKit

// 各种环境变量和静态常量
struct Environment {
	// static let version = 17 - last v1
	// static let version = 18 - unreleased for bugs
	// static let version = 19 - 2.0
	// static let version = 20 - 2.0.1
	// static let version = 21 - 2.0.2
	// static let version = 22 - 2.0.3
	// static let version = 23 // 2.0.4
	// static let version = 24 // 2.0.5
	// static let version = 25 // 2.0.6
	// static let version = 26 // 2.1.0
	// static let version = 27 // 2.1.1
	// static let version = 28 // 2.2
	// static let version = 29 // 2.3
	// static let version = 30 // 2.3.1
	// static let version = 31 // 2.3.2
	// static let version = 32 // 2.3.3
	// static let version = 33 // 2.4
	// static let version = 34 // 2.4.1
	// static let version = 35 // 2.4.2, 2.4.3, 2.4.4, 2.4.5
	// static let version = 36 // 2.4.6
	// static let version = 37 // 2.4.7 ~ 2.5.7
	static let version = 38 // 2.5.8
	
	static let bundleId = "cool.monkey.ios"
	
	static var languageString : String {
		return NSLocale.preferredLanguages.first ?? ""
	}
	
	static var appVersion: String {
		return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0" // Use zeros instead of crashing. This should not happen.
	}
	
	static var appBuild: String {
		return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" // Use zeros instead of crashing. This should not happen.
	}
	
	static var environment: ENV {
		let envString = (Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String ?? "").lowercased()
		return ENV.allValues.first { $0.rawValue.lowercased().contains(envString) } ?? .sandbox
	}
	
	static var baseURL: String {
		switch self.environment {
		case .local: fallthrough
		case .sandbox: return "http://test.monkey.cool"
		case .release: return "https://api.monkey.cool"
		}
	}
	
	static var socketURL: String {
		switch self.environment {
		case .local: fallthrough
		case .sandbox: return "ws://test.monkey.cool/api/v2.0/sockets/websocket"
		case .release: return "wss://ws.monkey.cool/api/v2.0/sockets/websocket"
		}
	}
	
	static var amplitudeKey: String {
		switch self.environment {
		case .local: fallthrough
		case .sandbox: return "04f72fae8a9c614c47cc38e822778a36"
		case .release: return "a7f21c75b22fc7cd2e054da19f629870"
		}
	}
	
	#if REALM_SYNC
	// connect to realm://realm-object-server.monkey.cool:9080
	static let RealmSyncHost = "192.168.200.60:9080"
	static let RealmSyncServerUrl = "http://" + RealmSyncHost
	static let MonkeySyncRealmUrl = "realm://" + RealmSyncHost + "/~/monkey-realm"
	#endif
	
	static let ScreenSize: CGSize = UIScreen.main.bounds.size
	static let ScreenBounds: CGRect = UIScreen.main.bounds
	static let ScreenWidth: CGFloat = UIScreen.main.bounds.width
	static let ScreenHeight: CGFloat = UIScreen.main.bounds.height
	static let ScreenAspectRadio: CGFloat = ScreenWidth / ScreenHeight
	
	static let adjustToken = "w8wlqq6li0w0"
	static let MonkeyAppStoreUrl = "itms-apps://itunes.apple.com/app/id1165924249"
	static let MonkeyAppRateURL = "https://itunes.apple.com/us/app/id1165924249?action=write-review"
	static let MonkeyAppTermsURL = "http://monkey.cool/terms"
	static let MonkeyAppPrivacyURL = "http://monkey.cool/privacy"

	
	static var isIphoneX: Bool {
		let isIphoneX: Bool = Device().isOneOf([Device.iPhoneX])
		return isIphoneX
	}
}

let ScreenHeight: CGFloat = Environment.ScreenHeight
let ScreenWidth: CGFloat = Environment.ScreenWidth

enum ENV: String {
	/*
	If you add a value here, update "allValues" below!!
	*/
	case local = "Local"
	case sandbox = "Sandbox"
	case release = "Release"
	static let allValues = [local, sandbox, release]
}

// login method
enum LoginMethod: String {
	case login = "login"
	case register = "register"
	case autoLogin = "autoLogin"
}

// report reason
enum ReportType: Int {
	case mean = 9
	case nudity = 10
	case violence = 11
	case meanOrBully = 12
	case drugsOrWeapon = 13
	case ageOrGender = 14
	case other = 15
	
	func eventTrackValue() -> String {
		switch self {
		case .mean:
			return "Channel"
		case .nudity:
			return "Nude"
		case .violence:
			return "Violent"
		case .meanOrBully:
			return "Bully/racist"
		case .drugsOrWeapon:
			return "Drugs/Weapon"
		case .ageOrGender:
			return "Age/Sex"
		case .other:
			return "Other"
		}
	}
}

// screen shot screen
enum AutoScreenShotType: String {
	case match_5s = "match_5s"
	case match_disconnec = "match_disconnec"
	case opponent_background = "opponent_background"
}

// rate reason
enum showRateAlertReason: String {
	case addFriendJust = "addFriendJust"
	case finishFriendCall = "finishFriendCall"
	case contiLoginThreeDay = "contiLogin"
	
	func eventValue() -> String {
		switch self {
		case .addFriendJust:
			return "Add friend success"
		case .finishFriendCall:
			return "Finish friend call"
		case .contiLoginThreeDay:
			return "Using 3 days"
		}
	}
}

// onep match status
enum OnepStatus {
	case WaitingStart
	case RequestMatch
	case WaitingResponse
	case Connecting
	case Chating
	
	func canSwipe() -> Bool {
		return self == .WaitingStart || self == .RequestMatch
	}
	func processMatch() -> Bool {
		return self.canSwipe() == false
	}
}

// twop match status
enum TwopStatus {
	case DashboardReady
	case PairConnecting
	case RequestMatch
	case WaitingConfirm
	case WaitingResponse
	case Connecting
	case Chating
	case Reconnecting
	
	func processMatch() -> Bool {
		return self != .DashboardReady && self != .PairConnecting && self != .RequestMatch
	}
	
	func connectMatch() -> Bool {
		return self == .Connecting || self == .Chating
	}
}

// match type
@objc enum MatchType: Int {
	case Onep = 1
	case Twop = 2
	
	func reverse() -> MatchType {
		switch self {
		case .Onep:
			return .Twop
		case .Twop:
			return .Onep
		}
	}
}

// unlock plan
@objc enum UnlockPlan: Int {
	case A = 1
	case B = 2
}
