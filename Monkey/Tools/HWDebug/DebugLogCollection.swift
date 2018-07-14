//
//  DebugLogCollection.swift
//  Monkey
//
//  Created by 王广威 on 2018/6/14.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

enum MonkeyLogType: String {
	case SendChannelMessage = "Send Channel Message"
	case ReceiveChannelMessage = "Receive Channel Message"
	case SendSocketMessage = "Send Socket Message"
	case ReceiveSocketMessage = "Receive Socket Message"
	case ReceiveMatchMessage = "Receive Match Message"
	case CustomLog = "Custom Action"
	case EventTrack = "Event Track"
	case ApiRequest = "Api Request"
	case ChannelServiceCallback = "Channel Service Callback"
}

class MonkeyLog : NSObject {
	var type: String
	var subTitle: String?
	var time = Date.init()
	var info: [String: Any]?
	
	init(type: MonkeyLogType, subTitle: String?, info: [String: Any]?) {
		self.type = type.rawValue
		self.subTitle = subTitle
		self.info = info
		super.init()
	}
}

@objc
protocol LogObserver {
	func LogCollectionChanged()
}


class LogManager: NSObject {
	
	static let shared = LogManager()
	private override init() {}
	
	var logObserver: LogObserver?
	var logCollection = [MonkeyLog]()
	func addLog(type: MonkeyLogType = .CustomLog, subTitle: String? = nil, info: [String: Any]? = nil) {
		DispatchQueue.main.async {
			let thisLog = MonkeyLog.init(type: type, subTitle: subTitle, info: info)
			self.logCollection.append(thisLog)
			self.logObserver?.LogCollectionChanged()
			HWTipView.showTip("\(thisLog.type)\n\(thisLog.subTitle ?? "")", at: HWTipPositionTop, complete: nil)
		}
	}
	
	func clearLog() {
		logCollection.removeAll()
		logObserver?.LogCollectionChanged()
	}
}


