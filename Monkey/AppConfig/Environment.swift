
//  Environment.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/17/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

struct Environment {
    enum ENV: String {
        /*
         If you add a value here, update "allValues" below!!
         */
        case sandbox = "Sandbox"
        case release = "Release"
        static let allValues = [sandbox, release]
    }
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
    static var environment: ENV {
        let envString = (Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String ?? "").lowercased()
        return ENV.allValues.first { $0.rawValue.lowercased().contains(envString) } ?? .sandbox
    }
    static var baseURL: String {
        switch self.environment {
        case .sandbox: return "http://test.monkey.cool"
        case .release: return "https://api.monkey.cool"
        }
    }
    static var socketURL: String {
        switch self.environment {
        case .sandbox: return "ws://test.monkey.cool/api/v2.0/sockets/websocket"
        case .release: return "wss://ws.monkey.cool/api/v2.0/sockets/websocket"
        }
    }
	static var amplitudeKey: String {
		switch self.environment {
		case .sandbox: return "04f72fae8a9c614c47cc38e822778a36"
		case .release: return "a7f21c75b22fc7cd2e054da19f629870"
		}
	}
    
    static let adjustToken = "w8wlqq6li0w0"
    static var deeplink_source : String {
        get {
            return UserDefaults.standard.string(forKey: "kDeepLinkSourceValue") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "kDeepLinkSourceValue")
        }
    }
	
	static let MonkeyAppStoreUrl = "itms-apps://itunes.apple.com/app/id1165924249"
    static let MonkeyAppRateURL = "https://itunes.apple.com/us/app/id1165924249?action=write-review"
	static let MonkeyChatAppStoreUrl = "itms-apps://itunes.apple.com/app/id1330119861"
	static let MonkeyChatScheme = "monkeychat://"
}
