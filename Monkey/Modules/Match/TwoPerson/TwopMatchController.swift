//
//  TwopMatchController.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class TwopMatchController: MonkeyViewController {
	
	private var dashboard: DashboardMainViewController?
	private var unlockPanel: TwoPersonPlanViewController?
	fileprivate var initialPanel: UIViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.configureApperance()
		self.view.backgroundColor = UIColor.clear
	}
	
	private func configureApperance() {
		guard let currentUser = UserManager.shared.currentUser else { return }
		
		// initial panel
		if currentUser.cached_unlocked_two_p {
			// dashboard
			self.initialPanel = UIStoryboard.init(name: "TwoPerson", bundle: nil).instantiateViewController(withIdentifier: "DashboardMainViewController") as! DashboardMainViewController
		}else {
			// unlock panel
			let unlockPanel = UIStoryboard.init(name: "TwoPerson", bundle: nil).instantiateViewController(withIdentifier: "TwoPersonPlanViewController") as! TwoPersonPlanViewController
			if currentUser.two_p_user_group_type == UnlockPlan.A.rawValue {
				// plan A
				unlockPanel.isPlanBIsUnLockedTuple = (false, false)
			}else {
				// plan B
				unlockPanel.isPlanBIsUnLockedTuple = (true, false)
			}
			self.initialPanel = unlockPanel
		}
	}
	
	func showInitialContent(complete: (() -> Void)?) {
		guard let initialPanel = self.initialPanel else { return }
		
		self.addChildViewController(initialPanel)
		initialPanel.beginAppearanceTransition(true, animated: true)
		self.view.addSubview(initialPanel.view)
		initialPanel.view.frame = self.view.bounds
		initialPanel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		initialPanel.view.alpha = 0
		
		UIView.animate(withDuration: 0.3, animations: {
			initialPanel.view.alpha = 1
		}) { (finished) in
//			initialPanel.endAppearanceTransition()
			initialPanel.didMove(toParentViewController: self)
			complete?()
		}
	}
	
	func hideInitialContent(complete: (() -> Void)?) {
		guard let initialPanel = self.initialPanel else { return }
		
		initialPanel.willMove(toParentViewController: nil)
		initialPanel.beginAppearanceTransition(false, animated: true)
		
		UIView.animate(withDuration: 0.3, animations: {
			initialPanel.view.alpha = 0
		}) { (finished) in
			initialPanel.view.removeFromSuperview()
			initialPanel.endAppearanceTransition()
			initialPanel.removeFromParentViewController()
			
			complete?()
		}
	}
}

extension TwopMatchController: MatchObserver {
	func appMovedToBackground() {
		
	}
	
	func appMovedToForeground() {
		
	}
	
	func appWillTerminate() {
		
	}
}

extension TwopMatchController: TransationDelegate {
	func appear(animated flag: Bool, complete: (() -> Void)?) {
		self.showInitialContent(complete: complete)
	}
	
	func disappear(animated flag: Bool, complete: (() -> Void)?) {
		complete?()
	}
	
	func didMoveTo(screen: UIViewController) {
		
	}
	
	func didShowFrom(screen: UIViewController) {
		
	}
}

