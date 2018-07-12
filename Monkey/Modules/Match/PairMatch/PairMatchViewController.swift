//
//  PairMatchViewController.swift
//  Release
//
//  Created by 王广威 on 2018/7/12.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import UIKit

class PairMatchViewController: MonkeyViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.configureApperance()
		self.view.backgroundColor = UIColor.clear
	}
	
	private func configureApperance() {
		
	}
}

extension PairMatchViewController: MatchObserver {
	func didReceiveMessage(type: String, in chat: String) {
		
	}
	
	func matchTypeChanged(newType: MatchType) {
		
	}
	
	func appMovedToBackground() {
		
	}
	
	func appMovedToForeground() {
		
	}
	
	func appWillTerminate() {
		
	}
}

