//
//  AuthViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/14/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire
import Amplitude_iOS
import RealmSwift
import FBSDKCoreKit

class AuthViewController: UIViewController {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var onboarded = false
    var isOpeningToChat = false
    var linkOnCompletion:DeepLink?
    @IBOutlet var onboardingContainerView: UIView!

    /// When true, don't present a new VC on viewDidAppear
    var isPresentingErrorCallbacks = [() -> Void]()

    private var currentAppVersionIsSupported: Bool {
        guard let minimumAppVersion = APIController.shared.currentExperiment?.minimum_version.value else {
            print("Error: could not check if version was supported.")
            return true
        }
        return minimumAppVersion <= Environment.version
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startAuth()
    }

    func startAuth() {
        guard self.isPresentingErrorCallbacks.count == 0 else {
            return // Will be called when error dismissed.
        }
        RealmDataController.shared.setupRealm(presentingErrorsOnViewController: self) {

            if APIController.authorization != nil {
                self.sync()
            } else {
                let when = DispatchTime.now() + (Double(0.1))
                DispatchQueue.main.asyncAfter(deadline: when) {
                    let vc = self.storyboard!.instantiateViewController(withIdentifier: "welcomeVC")
                    vc.modalTransitionStyle = .crossDissolve
                    self.present(vc, animated: true, completion: nil)
                    self.onboardingContainerView.removeFromSuperview()
                }
            }

            let isAuth = (APIController.authorization == nil)
            if (isAuth || !Achievements.shared.grantedPermissionsV2) {
                self.view.backgroundColor = Colors.purple
            } else {
                self.view.backgroundColor = .black
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
            nextVC()
        } else {
            self.activityIndicator.startAnimating()
        }

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        reloadCurrentUser {
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        updateExperiments {
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            guard self.presentedViewController != nil else {
                self.nextVC()
                return
            }
			var loginResult: String = "new"
			
            if APIController.shared.currentUser?.birth_date == nil || APIController.shared.currentUser?.first_name == nil || APIController.shared.currentUser?.gender == nil  {
                    let accountVC = self.storyboard!.instantiateViewController(withIdentifier: (self.view.window?.frame.height ?? 0.0) < 667.0  ? "editAccountSmallVC" : "editAccountVC") as! EditAccountViewController
                    accountVC.shouldDismissAfterEntry = true
                    (self.presentedViewController as? MainViewController)?.present(accountVC, animated: true, completion: nil)
				loginResult = "new"
				
				UserDefaults.standard.set(true, forKey: "MonkeySignUp")
				UserDefaults.standard.set(true, forKey: "MonkeyLogEventFirstMatchRequest")
				UserDefaults.standard.set(true, forKey: "MonkeyLogEventFirstMatchSuccess")
				UserDefaults.standard.synchronize()
			}else {
				guard let currentUser = APIController.shared.currentUser else {
					print("Error: Current user should be defined by now.")
					return
				}
				
				AppGroupDataManager.appGroupUserDefaults?.set(currentUser.first_name, forKey: "Monkey_first_name")
				AppGroupDataManager.appGroupUserDefaults?.set(currentUser.username, forKey: "Monkey_username")
				AppGroupDataManager.appGroupUserDefaults?.set(currentUser.user_id, forKey: "Monkey_user_id")
				AppGroupDataManager.appGroupUserDefaults?.set(currentUser.birth_date, forKey: "Monkey_birth_date")
				AppGroupDataManager.appGroupUserDefaults?.set(currentUser.gender, forKey: "Monkey_gender")
			}
			
			Amplitude.shared.logEvent("SIGNUP_LOGIN", withEventProperties: ["result": loginResult])
			FBSDKAppEvents.logEvent("SIGNUP_LOGIN", parameters: ["result": loginResult])
            print("Updates completed in background")
        }
    }

    func reloadCurrentUser(completion: @escaping () -> Void) {
        guard let currentUser = APIController.shared.currentUser else {
            print("Error: Current user should be defined by now.")
            return
        }
        currentUser.reload {[weak currentUser] (error: APIError?) in
            guard error == nil else {
                if error!.status == "401" {
                    return self.resetToWelcome()
                }
                self.show(error: error!) {
                    self.reloadCurrentUser(completion: completion)
                }
                return
            }

            // FIXME: the current user object may be nil , the func will not execute when it is nil
            if let is_snapcode_uploaded = currentUser?.is_snapcode_uploaded.value {
                if is_snapcode_uploaded == false {
                    self.fetchAndUploadSnapcode()
                }
            }

            print("Reloaded current user")
            completion()
        }
    }


    /// Fetches the snapcode fom the server then passes it to create a RealmSnapcode
    func fetchAndUploadSnapcode() {
        guard APIController.shared.currentExperiment?.enable_snapcodes.value == true else {
            return
        }

        guard let snapchatUsername = APIController.shared.currentUser?.snapchat_username else {
            return
        }

        let requestURL = "https://feelinsonice-hrd.appspot.com/web/deeplink/snapcode?username=\(snapchatUsername)&type=SVG&bitmoji=enable"

        Alamofire.request(requestURL, method: .get, parameters: nil).responseString { (response) in
            if let error = response.error {
                print("Error getting snapcode: \(error)")
                return
            }

            guard let resultString = response.result.value else {
                return
            }

            self.createSnapcode(svgString: resultString, snapchatUsername: snapchatUsername)
        }
    }

    /// Creates a RealmSnapcode with the passed string
    ///
    /// - Parameter svgString: snapcode svg string
    func createSnapcode(svgString:String, snapchatUsername:String) {
        let parameters:[String:Any] = [
            "data":[
                "type":"snapcodes",
                "attributes":[
                    "svg":svgString,
                    "snapchat_username":snapchatUsername
                ]
            ]
        ]
        RealmSnapcode.create(parameters: parameters) { (result: JSONAPIResult<[RealmSnapcode]>) in
            switch result {
            case .success(_):
                print("Snapcode uploaded")
            case .error(let error):
                error.log()
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
            SyncUser.current?.logOut()
            UserDefaults.standard.removeObject(forKey: "user_id")
            Apns.update(callback: nil)
            // This is okay because it should currently only happen when switching between servers. however, in the future it could happen if we invalidate old logins so eventually recovery should be possible.
            self.presentedViewController?.dismiss(animated: true, completion: {
                print("INVALID SESSION: Reset to welcome screen")
            })
        }

    }

    func updateExperiments(completion: @escaping () -> Void) {
        RealmExperiment.fetch(id: APIController.shared.appVersion, completion: { (error: APIError?, experiment: RealmExperiment?) in
            guard error == nil else {
                if error!.status == "401" {
                    return
                }
                self.show(error: error!) {
                    self.updateExperiments(completion: completion)
                }
                return
            }
            print("Updated experiments")
            completion()
        })
    }
    func crashInvalidSession() {
        RealmDataController.shared.deleteAllData { (error) in
            guard error == nil else {
                error?.log()
                return
            }
            APIController.authorization = nil
            SyncUser.current?.logOut()
            UserDefaults.standard.removeObject(forKey: "user_id")
            Apns.update(callback: nil)
            // This is okay because it should currently only happen when switching between servers. however, in the future it could happen if we invalidate old logins so eventually recovery should be possible.
            fatalError("Bad session")
        }
    }
    /**
     Shows an error alert after dismissing any presented view controller (if one exists).

     - parameter error: The error to show.
    */
    func show(error: APIError, onRetry: @escaping () -> Void) {
        guard self.isPresentingErrorCallbacks.count == 0 else {
            self.isPresentingErrorCallbacks.append(onRetry)
            return
        }
        let errorAlert = error.toAlert(onRetry: { (action) in
            while self.isPresentingErrorCallbacks.count != 0 {
                self.isPresentingErrorCallbacks.removeFirst()()
            }
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

        // Ensure version is supported
        guard self.currentAppVersionIsSupported else {
            print("Running unsupported version of Monkey")
            self.showUnsupportedVersionErrorAlert()
            return
        }
        if APIController.shared.currentUser?.gender == nil {
            if (self.view.window?.frame.height ?? 0.0) < 667.0 {
               self.present((self.storyboard!.instantiateViewController(withIdentifier: "editAccountSmallVC")), animated: false, completion: nil)
            } else {
                self.present((self.storyboard!.instantiateViewController(withIdentifier: "editAccountVC")), animated: false, completion: nil)
            }
        } else if APIController.shared.currentUser?.snapchat_username == nil {
            if (self.view.window?.frame.height ?? 0.0) < 667.0 {
                self.present((self.storyboard!.instantiateViewController(withIdentifier: "editAccountSmallVC")), animated: false, completion: nil)
            } else {
                self.present((self.storyboard!.instantiateViewController(withIdentifier: "editAccountVC")), animated: false, completion: nil)
            }        } else if !Achievements.shared.grantedPermissionsV2 {
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
			self.openURL("itms-apps://itunes.apple.com/app/id1165924249")
		}));
        guard let presentedViewController = self.presentedViewController else {
            self.present(unsuportedVersionAlert, animated: true, completion: nil)
            return
        }
        presentedViewController.dismiss(animated: true, completion: {
            self.present(unsuportedVersionAlert, animated: true, completion: nil)
        })
    }
	
	func openURL(_ urlString: String)
	{
		guard let url = URL(string: urlString) else {
			return
		}
		UIApplication.shared.openURL(url)
	}
    /// Should be called when ready to open the mainVC after launch setup is complete. Also manages opening to chat if necessary and beginning the background experiments update.
    func finishLaunchSetup() {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            guard let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "mainVC") as? MainViewController else {
                print("Error: No main VC to present")
                return
            }
            self.present(mainVC, animated: false, completion: {
                // Ensure version is supported. Other experiments values have been stored for use later as necessary.
                guard self.currentAppVersionIsSupported else {
                    print("Running unsupported version of Monkey discovered through experiments refresh.")
                    self.showUnsupportedVersionErrorAlert()
                    return
                }

                // Process pending deep link
                if self.linkOnCompletion != nil {
                    guard let destination = self.linkOnCompletion?.destination else {
                        return
                    }

                    let specifier = self.linkOnCompletion?.specifier
                    let options = self.linkOnCompletion?.parameters

                    var viewControllerToPresent:UIViewController! = mainVC.swipableViewControllerToPresentOnLeft!

                    switch destination {
                    case .chat, .messages:
                        viewControllerToPresent = mainVC.swipableViewControllerToPresentOnLeft!

                        if let friendsViewController = viewControllerToPresent as? FriendsViewController {
                            friendsViewController.initialConversation = specifier
                            friendsViewController.initialConversationOptions = options
                        }

                    case .trees:
                        viewControllerToPresent = mainVC.swipableViewControllerToPresentOnRight!
                    case .settings:
                        viewControllerToPresent = mainVC.swipableViewControllerToPresentOnBottom!
                    default:
                        break
                    }

                    mainVC.present(viewControllerToPresent, animated: true)
                }
            })
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
