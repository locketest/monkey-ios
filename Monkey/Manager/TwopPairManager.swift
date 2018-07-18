//
//  TwopPairManager.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/18.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

class TwopPairManager: NSObject {
	
	enum Status: Int {
		case UnResponse
		case Accept
		case Ignore
	}
	
	static let shared = TwopPairManager()
	override private init() {}
	
	
}
//websocketDidReceiveMessage ["default",{"msg_id":"dd5178f3-f3b7-4e60-b470-e923af7c8b80","msg_type":3,"sender_id":5264833,"content":"SixPlus invites you to start 2P Chat rn 🙌","ext":{"friend_id":5264833,"expire_time":1531918849613}}]

//websocketDidReceiveMessage ["default",{"msg_id":"e01a0ca5-b3fd-4645-81c3-f90d05944ad7","msg_type":4,"sender_id":5264833,"ext":{"channel_name":"5264844:5264833","friend_id":5264833,"expire_time":1531919058284,"pair_id":"5264844:5264833","channel_key":"005AQAoADhFMDdCRUUwODMyRkMzQTQzOEM1MDMxOTg2Q0UyQzBCQ0IwNjIyMEEQAMOTcG/nyUOpmM9+lnLhMl+5Ok9brT5acgAAAAAAAA=="}}]
