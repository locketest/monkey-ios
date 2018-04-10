//
//  MatchViewControllerProtocol.swift
//  Monkey
//
//  Created by 王广威 on 2018/2/7.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation

protocol MatchViewControllerProtocol: ChatSessionCallDelegate {
	func autoScreenShotUpload(source: AutoScreenShotType)
	var isPublisherViewEnlarged: Bool {
		get
		set
	}
	var chatSession: ChatSession? {
		get
		set
	}
    
    var commonTree:RealmChannel?{
        get
        set
    }
}
