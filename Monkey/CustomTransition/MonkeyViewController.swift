//
//  MonkeyViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation

class MonkeyViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("\(self) \(#function)")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		print("\(self) \(#function)")
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		print("\(self) \(#function)")
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		print("\(self) \(#function)")
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		print("\(self) \(#function)")
	}
	
	deinit {
		print("\(self) \(#function)")
	}
}
