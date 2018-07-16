//
//  MatchPairTransation.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/16.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class MatchPairTransation: MakeUIViewGreatAgain {
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	func configureApperance() {
		self.backgroundColor = UIColor.clear
		
	}
}
