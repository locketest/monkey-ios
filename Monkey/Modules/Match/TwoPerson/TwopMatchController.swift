//
//  TwopMatchController.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/4.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import ObjectMapper

class TwopMatchController: MonkeyViewController {
	
	fileprivate var pairMatchViewController: PairMatchViewController?
	
	fileprivate weak var initialPanel: UIViewController?
	fileprivate var matchManager = TwopMatchManager.default
	fileprivate var friendPairModel: FriendPairModel?
	fileprivate var pairSuccess = false
	
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
			let dashboard = UIStoryboard.init(name: "TwoPerson", bundle: nil).instantiateViewController(withIdentifier: "DashboardMainViewController") as! DashboardMainViewController
			dashboard.delegate = self
			self.initialPanel = dashboard
		}else {
			// unlock panel
			let unlockPanel = UIStoryboard.init(name: "TwoPerson", bundle: nil).instantiateViewController(withIdentifier: "TwoPersonPlanViewController") as! TwoPersonPlanViewController
			if currentUser.two_puser_group_type == UnlockPlan.A.rawValue {
				// plan A
				unlockPanel.isPlanBIsUnLockedTuple = (false, false)
			}else {
				// plan B
				unlockPanel.isPlanBIsUnLockedTuple = (true, false)
			}
			self.initialPanel = unlockPanel
		}
	}
	
	func refreshInitialVC() {
		self.hideInitialContent {
			self.initialPanel = nil
			self.configureApperance()
			self.showInitialContent(complete: nil)
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
		
		UIView.animate(withDuration: 0.25, animations: {
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
		
		UIView.animate(withDuration: 0.25, animations: {
			initialPanel.view.alpha = 0
		}) { (finished) in
			initialPanel.view.removeFromSuperview()
			initialPanel.endAppearanceTransition()
			initialPanel.removeFromParentViewController()
			
			complete?()
		}
	}
}

extension TwopMatchController {
	func beginPairConnect() {
		self.mainViewController?.startMatch()
		self.mainViewController?.beginMatchProcess()
	}
	
	func beginPairMatch() {
		guard let friendPairModel = self.friendPairModel else { return }
		
		self.hideInitialContent { [weak self] in
			self?.showPairMatch(with: friendPairModel)
		}
	}
	
	func showPairMatch(with friendPairModel: FriendPairModel) {
		let pairMatchViewController = self.storyboard?.instantiateViewController(withIdentifier: "PairMatch") as! PairMatchViewController
		self.pairMatchViewController = pairMatchViewController
		pairMatchViewController.present(from: self, with: friendPairModel, complete: nil)
	}
	
	func dismissPairMatch() {
		self.pairMatchViewController = nil
		self.showInitialContent(complete: nil)
		self.endPairMatch()
		self.endPairConnect()
	}
	
	func endPairMatch() {
		self.matchManager.stopConnect(with: self.friendPairModel)
		self.friendPairModel = nil
		self.pairSuccess = false
	}
	
	func endPairConnect() {
		self.mainViewController?.endMatchProcess()
		self.mainViewController?.endMatch()
	}
}

extension TwopMatchController: DashboardMainViewControllerDelegate {
	func twopPreConnectingFunc() {
		self.beginPairConnect()
	}
	
	func twopStartConnectingFunc(pairRequestAcceptModel: PairRequestAcceptModel) {
		
		if let friend_id = pairRequestAcceptModel.friendIdInt,
			let pair_id = pairRequestAcceptModel.pairIdString,
			let channel_name = pairRequestAcceptModel.channelNameString,
			let channel_key = pairRequestAcceptModel.channelKeyString {
			
			let pairJson: [String: Any] = [
				"match_id": pair_id,
				"pair_id": pair_id,
				"channel_name": channel_name,
				"channel_key": channel_key,
				"friend": [
					"id": friend_id,
				],
			]
			// 构造 pair model
			if let friendPairModel = Mapper<FriendPairModel>().map(JSON: pairJson) {
				self.friendPairModel = friendPairModel
				self.matchManager.delegate = self
				self.matchManager.connect(with: friendPairModel)
			}
		}
	}
	
	func twopTimeoutConnectingFunc() {
		if self.pairSuccess == false {
			self.endPairMatch()
			self.endPairConnect()
		}
	}
}

extension TwopMatchController: MatchServiceObserver {
	func disconnect(reason: MatchError) {
		if self.pairSuccess == false {
			self.endPairMatch()
		}else {
			self.dismissPairMatch()
		}
	}
	
	func remoteVideoReceived(user user_id: Int) {
		if self.pairSuccess == false {
			self.pairSuccess = true
			if let dashboard = self.initialPanel as? DashboardMainViewController {
				dashboard.endConnectingFunc()
			}
			self.beginPairMatch()
		}
	}
	
	func channelMessageReceived(message: MatchMessage) {
		self.pairMatchViewController?.channelMessageReceived(message: message)
	}
}

extension TwopMatchController: MessageObserver {
	func didReceiveTwopMatch(match: MatchModel) {
		self.pairMatchViewController?.didReceiveTwopMatch(match: match)
	}
}

extension TwopMatchController: MatchObserver {
	func didReceiveMessage(type: String, in chat: String) {
		self.pairMatchViewController?.didReceiveMessage(type: type, in: chat)
	}
	
	func matchTypeChanged(newType: MatchType) {
		self.pairMatchViewController?.matchTypeChanged(newType: newType)
	}
	
	func appMovedToBackground() {
		self.pairMatchViewController?.appMovedToBackground()
	}
	
	func appMovedToForeground() {
		self.pairMatchViewController?.appMovedToForeground()
	}
	
	func appWillTerminate() {
		self.pairMatchViewController?.appWillTerminate()
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

