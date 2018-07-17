//
//  MonkeyViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Hero

class MonkeyViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
	
	override var prefersStatusBarHidden: Bool {
		if let childVC = self.childViewControllers.first {
			return childVC.prefersStatusBarHidden
		}
		return super.prefersStatusBarHidden
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
		if let window = UIApplication.shared.delegate?.window, let subViews = window?.subviews {
			for subView in subViews {
				if subView is UIStackView {
					window?.bringSubview(toFront: subView)
					break
				}
			}
		}
		print("\(self) \(#function)")
	}
	
	deinit {
		print("\(self) \(#function)")
	}
}
