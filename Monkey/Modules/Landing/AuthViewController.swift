//
//  AuthViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/14/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift

class AuthViewController: MonkeyViewController {
	
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var onboardingContainerView: UIView!
	
	/// When true, don't present a new VC on viewDidAppear
	var presentingErrorCallback: (() -> Void)?
	
	private var currentAppVersionIsSupported: Bool {
		guard let minimumAppVersion = APIController.shared.currentExperiment?.minimum_version.value else {
			print("Error: could not check if version was supported.")
			return true
		}
		return minimumAppVersion <= Environment.version
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
//		guard self.onboardingContainerView.superview == nil else {
//			return
//		}
//		self.view.addSubview(self.onboardingContainerView)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.startAuth()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.onboardingContainerView.removeFromSuperview()
	}
	
	func startAuth() {
		guard self.presentingErrorCallback == nil else {
			return // Will be called when error dismissed.
		}
		
		RealmDataController.shared.setupRealm { (setupError: APIError?) in
			if let apiError = setupError {
				self.show(error: apiError, onRetry: {
					self.startAuth()
				})
				return
			}
		
			if APIController.authorization == nil {
				// 未登录，跳转到登录
				DispatchQueue.main.asyncAfter(deadline: DispatchTime.after(seconds: 0.1), execute: {
					let vc = self.storyboard!.instantiateViewController(withIdentifier: "welcomeVC")
					vc.modalTransitionStyle = .crossDissolve
					self.present(vc, animated: true, completion: nil)
				})
			} else {
				// 如果是已经登录的账号
				self.sync()
			}
		}
	}
	/// Forces update of Experiments from cache or network if required then performs checks based off of Experiments
	func sync() {
		guard UIApplication.shared.applicationState == .active else {
			NotificationCenter.default.addObserver(self, selector: #selector(self.sync), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
			return
		}
		
		// If we have a cache, show the VC now and let the update continue in the background
		if APIController.shared.currentExperiment != nil {
			self.nextVC()
		} else {
			self.activityIndicator.startAnimating()
		}
		
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		self.reloadCurrentUser {
			dispatchGroup.leave()
		}
		dispatchGroup.enter()
		self.updateExperiments {
			dispatchGroup.leave()
		}
		dispatchGroup.notify(queue: .main) {
			guard self.presentedViewController != nil else {
				self.nextVC()
				return
			}
			
			guard let currentUser = APIController.shared.currentUser else {
				print("Error: Current user should be defined by now.")
				return
			}
			
			// 存储用户资料到共享 app groups 存储区
			Achievements.shared.group_first_name = currentUser.first_name;
			Achievements.shared.group_username = currentUser.username;
			Achievements.shared.group_user_id = currentUser.user_id;
			Achievements.shared.group_birth_date = currentUser.birth_date?.timeIntervalSince1970;
			Achievements.shared.group_gender = currentUser.gender;
			Achievements.shared.group_profile_photo = currentUser.profile_photo_url;
			
			// 如果资料完整
			if currentUser.isCompleteProfile() {
				APIController.trackCodeVerifyIfNeed(result: true, isProfileComp: true)
				
			}else {
				APIController.trackCodeVerifyIfNeed(result: true, isProfileComp: false)
				
				// 资料不全，编辑信息
				let accountVC = self.storyboard!.instantiateViewController(withIdentifier: (self.view.window?.frame.height ?? 0.0) < 667.0  ? "editAccountSmallVC" : "editAccountVC") as! EditAccountViewController
				(self.presentedViewController as? MainViewController)?.present(accountVC, animated: true, completion: nil)
			}
			
			print("Updates completed in background")
		}
	}
	
	func reloadCurrentUser(completion: @escaping () -> Void) {
		guard let currentUser = APIController.shared.currentUser else {
			print("Error: Current user should be defined by now.")
			completion()
			return
		}
		currentUser.reload { (error: APIError?) in
			if let error = error {
				if error.status == "401" {
					self.resetToWelcome()
					completion()
				}else {
					self.show(error: error) {
						self.reloadCurrentUser(completion: completion)
					}
				}
			}else {
				completion()
			}
		}
	}
	
	func resetToWelcome() {
		RealmDataController.shared.deleteAllData { (error) in
			guard error == nil else {
				error?.log()
				return
			}
			APIController.authorization = nil
			UserDefaults.standard.removeObject(forKey: "user_id")
			// This is okay because it should currently only happen when switching between servers. however, in the future it could happen if we invalidate old logins so eventually recovery should be possible.
			self.presentedViewController?.dismiss(animated: true, completion: {
				print("INVALID SESSION: Reset to welcome screen")
			})
			if let presentedViewController = self.presentedViewController {
				presentedViewController.dismiss(animated: true, completion: nil)
			}else {
				self.startAuth()
			}
		}
	}
	
	func updateExperiments(completion: @escaping () -> Void) {
		RealmExperiment.create { (result: JSONAPIResult<RealmExperiment>) in
			switch result {
			case .error(let error):
				print(error)
			case .success(let newObject):
				print(newObject)
			}
			completion()
		}
	}
	
	/**
	Shows an error alert after dismissing any presented view controller (if one exists).
	
	- parameter error: The error to show.
	*/
	func show(error: APIError, onRetry: @escaping () -> Void) {
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
	Presents the next view controller after authentication completes.
	
	Called after values for Experiments first become available (cached or from server).
	*/
	func nextVC() {
		self.activityIndicator.stopAnimating()
		
		// Ensure version is supported. Other experiments values have been stored for use later as necessary.
		guard self.currentAppVersionIsSupported else {
			print("Running unsupported version of Monkey discovered through experiments refresh.")
			self.showUnsupportedVersionErrorAlert()
			return
		}
		
		AnaliticsCenter.loginAccount()
        
        if let _ = APIController.shared.currentUser?.delete_at.value {
            let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "ResumeMyAccountViewController") as! ResumeMyAccountViewController
            self.present(vc, animated: false)
        } else if APIController.shared.currentUser?.isCompleteProfile() == false {
			// 资料不全，编辑信息
			let accountVC = self.storyboard!.instantiateViewController(withIdentifier: (self.view.window?.frame.height ?? 0.0) < 667.0  ? "editAccountSmallVC" : "editAccountVC") as! EditAccountViewController
			accountVC.shouldDismissAfterEntry = true
			self.present(accountVC, animated: false)
		} else if Achievements.shared.grantedPermissionsV2 == false {
			let permissionsVC = self.storyboard!.instantiateViewController(withIdentifier: "permVC")
			self.present(permissionsVC, animated: false)
		} else {
			// Finish setting up and launching app and initial view controller
			guard  UIApplication.shared.applicationState == .active else {
				NotificationCenter.default.addObserver(self, selector: #selector(self.finishLaunchSetup), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
				return
			}
			self.finishLaunchSetup()
		}
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
	
	/// Should be called when ready to open the mainVC after launch setup is complete. Also manages opening to chat if necessary and beginning the background experiments update.
	func finishLaunchSetup() {
		NotificationCenter.default.removeObserver(self)
		DispatchQueue.main.async {
			guard let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "mainVC") as? MainViewController else {
				print("Error: No main VC to present")
				return
			}
			self.present(mainVC, animated: false, completion:nil)
		}
	}
}
