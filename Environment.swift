
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
        case local = "Local"
        case sandbox = "Sandbox"
        case development = "Development"
        case production = "Production"
        case release = "Release"
        static let allValues = [local, development, sandbox, production, release]
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
	static let version = 37 // 2.4.7, 2.4.8, 2.4.9, 2.5.0

    static var environment: ENV {
        let envString = (Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String ?? "").lowercased()
        return ENV.allValues.first { $0.rawValue.lowercased().contains(envString) } ?? .development
    }
    static var baseURL: String {
        switch self.environment {
        case .local: return "https://ngrok.monkey.engineering:21016"
        case .sandbox: return "http://test.monkey.cool"
        case .development: return "https://monkey-api-development.monkey.engineering"
        case .production: return "https://api.monkey.cool"
        case .release: return "https://api.monkey.cool"
//        case .release: return "https://test.monkey.cool"
        }
    }
    static var socketURL: String {
        switch self.environment {
        case .local: return "wss://ngrok.monkey.engineering:21016/api/v2.0/sockets/websocket"
        case .sandbox: return "ws://test.monkey.cool/api/v2.0/sockets/websocket"
        case .development: return "wss://monkey-api-development.monkey.engineering/api/v2.0/sockets/websocket"
        case .production: return "wss://ws.monkey.cool/api/v2.0/sockets/websocket"
        case .release: return "wss://ws.monkey.cool/api/v2.0/sockets/websocket"
//        case .release: return "ws://test.monkey.cool/api/v2.0/sockets/websocket"
        }
    }
    static var bundleId: String {
        switch self.environment {
        case .local: return "cool.monkey.ios-development"
        case .sandbox: return "cool.monkey.ios-sandbox"
        case .development: return "cool.monkey.ios-development"
        case .production: return "cool.monkey.ios-production"
        case .release: return "cool.monkey.ios"
        }
    }
    #if REALM_SYNC
    static var realmSyncProvider: String {
        switch self.environment {
        case .local: return "custom/jwt_development"
        case .sandbox: return "custom/jwt_development"
        case .development: return "custom/jwt_development"
        case .production: return "custom/jwt"
        case .release: fatalError("Realm Sync is not available in release.")
        }
    }
    // connect to realm://realm-object-server.monkey.cool:9080
    static let realmSyncServerURL = "https://realm-object-server.monkey.cool:9443"
    static let defaultRealmURL = "realms://realm-object-server.monkey.cool:9443/~/default"
    #endif
	
	static var amplitudeKey: String {
		switch self.environment {
		case .production, .release: return "a7f21c75b22fc7cd2e054da19f629870"
		default: return "04f72fae8a9c614c47cc38e822778a36"
		}
	}
	
	static var firebaseConfigurationPath: String {
		switch self.environment {
		case .production, .release: return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
		default: return Bundle.main.path(forResource: "GoogleService-Info-Dev", ofType: "plist")!
		}
	}
	
	static let MonkeyAppStoreUrl = "itms-apps://itunes.apple.com/app/id1165924249"
	static let MonkeyChatAppStoreUrl = "itms-apps://itunes.apple.com/app/id1330119861"
	static let MonkeyChatScheme = "monkeychat://"
}
