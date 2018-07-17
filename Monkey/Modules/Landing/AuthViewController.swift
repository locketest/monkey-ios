//
//  AuthViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/14/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit

class AuthViewController: MonkeyViewController {
	
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var onboardingContainerView: UIView!
	
	/// When true, don't present a new VC on viewDidAppear
	private var presentingErrorCallback: (() -> Void)?
	private var currentAppVersionIsSupported: Bool {
		guard let minimumAppVersion = UserManager.shared.currentExperiment?.minimum_version.value else {
			print("Error: could not check if version was supported.")
			return true
		}
		return minimumAppVersion <= Environment.version
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.startAuth()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.onboardingContainerView.removeFromSuperview()
	}
	
	private func startAuth() {
		guard self.presentingErrorCallback == nil else {
			return // Will be called when error dismissed.
		}
		
		UserManager.shared.login { (error) in
			guard let loginError = error else {
				self.sync()
				return
			}
			self.show(error: loginError, onRetry: {
				self.startAuth()
			})
		}
	}
	
	/// Forces update of Experiments from cache or network if required then performs checks based off of Experiments
	fileprivate func sync() {
		// 如果未登录成功
		guard UserManager.shared.isUserLogin() == true, let currentUser = UserManager.shared.currentUser else {
			self.resetToWelcome()
			return
		}
		
		// signup finish
		UserManager.shared.trackSignUpFinish()
		
		// If we have a cache, show the VC now and let the update continue in the background
		if UserManager.shared.currentExperiment != nil {
			self.nextVC()
		}else {
			self.activityIndicator.startAnimating()
		}
		
		let dispatchGroup = DispatchGroup()
		let leaveGroup = {
			dispatchGroup.leave()
		}
		
		dispatchGroup.enter()
		self.reloadUser(user: currentUser, completion: leaveGroup)
		dispatchGroup.enter()
		self.updateExperiments(completion: leaveGroup)
		
		dispatchGroup.notify(queue: .main) {
			self.activityIndicator.stopAnimating()
			
			// 如果登录失败
			guard UserManager.shared.isUserLogin() == true else {
				return
			}
			
			// code verify 打点
			UserManager.shared.trackCodeVerify()
			
			// 如果是已经进入到 main vc
			guard self.presentedViewController != nil else {
				self.nextVC()
				return
			}
		}
	}
	
	private func reloadUser(user: RealmUser, completion: @escaping () -> Void) {
		user.reload { (error: APIError?) in
			if let error = error, error.status != "401" {
				self.show(error: error) {
					self.reloadUser(user: user, completion: completion)
				}
			}else {
				// set user_id for some analytics
				AnalyticsCenter.loginAccount()
				// refresh user data
				UserManager.shared.refreshUserData()
				completion()
			}
		}
	}
	
	private func updateExperiments(completion: @escaping () -> Void) {
		RealmExperiment.create { (_: JSONAPIResult<RealmExperiment>) in
			completion()
		}
	}
	
	/**
	Presents the next view controller after authentication completes.
	
	Called after values for Experiments first become available (cached or from server).
	*/
	private func nextVC() {
		// Ensure version is supported. Other experiments values have been stored for use later as necessary.
		guard self.currentAppVersionIsSupported else {
			print("Running unsupported version of Monkey discovered through experiments refresh.")
			self.showUnsupportedVersionErrorAlert()
			return
		}
		
		// 登录之后添加监听
		UserManager.shared.addMessageObserver(observer: self)
		var presentingVC: UIViewController!
        if let delete_at = APIController.shared.currentUser?.delete_at, delete_at > 0 {
			// 如果用户被删除
            presentingVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "ResumeMyAccountViewController") as! ResumeMyAccountViewController
        } else if APIController.shared.currentUser?.isCompleteProfile() == false {
			// 资料不全，编辑信息
			let accountVC = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: Environment.ScreenHeight < 667.0 ? "editAccountSmallVC" : "editAccountVC") as! EditAccountViewController
			presentingVC = accountVC
		} else if Achievements.shared.grantedPermissionsV2 == false {
			// 没有给权限，跳转权限页
			presentingVC = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "permVC")
		} else {
			// 跳转到 discover
			presentingVC = UIStoryboard(name: "Match", bundle: nil).instantiateViewController(withIdentifier: "mainVC")
		}
		
		/// Should be called when ready to open the mainVC after launch setup is complete. Also manages opening to chat if necessary and beginning the background experiments update.
		DispatchQueue.main.async {
			self.present(presentingVC, animated: false)
		}
	}
	
	private func resetToWelcome() {
		let showWelcome = {
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 0.1), execute: {
				let vc = UIStoryboard.init(name: "Onboarding", bundle: nil).instantiateInitialViewController()!
				vc.modalTransitionStyle = .crossDissolve
				self.present(vc, animated: true, completion: nil)
			})
		}
		
		// 如果没有 presentedViewController
		guard let presentedViewController = self.presentedViewController else {
			showWelcome()
			return
		}
		
		// 如果已经是 welcome vc
		if presentedViewController is WelcomeViewController {
			return
		}
		
		// 如果不是，先 dismiss, 然后 present
		self.dismiss(animated: true, completion: showWelcome)
	}
	
	/**
	Shows an error alert after dismissing any presented view controller (if one exists).
	
	- parameter error: The error to show.
	*/
	private func show(error: APIError, onRetry: @escaping () -> Void) {
		guard self.presentingErrorCallback == nil else {
			return
		}
		self.presentingErrorCallback = onRetry
		let errorAlert = error.toAlert(onRetry: { (action) in
			onRetry()
		})
		
		guard let presentedViewController = self.presentedViewController else {
			self.present(errorAlert, animated: true, completion: nil)
			return
		}
		presentedViewController.present(errorAlert, animated: true, completion: nil)
	}
	
	/**
	Dismisses any presented view controller(s) and shows the unsupported version error.
	*/
	private func showUnsupportedVersionErrorAlert() {
		let unsuportedVersionAlert = UIAlertController(title: "Unsupported Version", message: "You need to update the app to keep using Monkey.", preferredStyle: .alert)
		unsuportedVersionAlert.addAction(UIAlertAction.init(title: "update", style: UIAlertActionStyle.default, handler: { (_) in
			guard let url = URL(string: Environment.MonkeyAppStoreUrl) else {
				return
			}
			UIApplication.shared.openURL(url)
		}));
		guard let presentedViewController = self.presentedViewController else {
			self.present(unsuportedVersionAlert, animated: true, completion: nil)
			return
		}
		presentedViewController.dismiss(animated: true, completion: {
			self.present(unsuportedVersionAlert, animated: true, completion: nil)
		})
	}
}

extension AuthViewController: UserObserver {
	func currentUserDidLogout() {
		// 同步数据或者跳转到登录页
		self.sync()
	}
}
