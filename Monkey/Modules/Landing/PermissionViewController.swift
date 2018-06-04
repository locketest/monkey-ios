//
//  PermissionViewController.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/20/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher
import CoreLocation
import UserNotifications

class PermissionViewController: UIViewController, CLLocationManagerDelegate {
    
    /// Rounded container view that contains the animated GIF UIImageView
    @IBOutlet var imageContainerView:MakeUIViewGreatAgain!
    /// Yellow button below content, triggers permission request when pressed
    @IBOutlet var permissionButton:BigYellowButton!
    /// The UILabel at the top of the screen, representing what permission we are currently asking for
    @IBOutlet var permissionLabel:UILabel!
    /// The UIImageView, located in its container, that shows the animated GIF for each permission.
    @IBOutlet var imageView: AnimatedImageView!
    /// The sole child of the VC's superview. Houses all subviews and is used to animate subviews
    /// over the superview background color when presenting or dismissing
    @IBOutlet weak var containerView: UIView!
    /// The speed the UI animates into view after displaying Colors.blue.
    let transitionTime = 0.4
    /// The delay before the UI animates into view after displaying Colors.blue.
    let transitionDelay = 0.1
    /// The trailing constraint on the container view. Used to animate UI in and out
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    /// Whether or not camera has been granted, on set, if true, goes to the next screen
    var grantedCamera:Bool = false {
        didSet {
            if grantedCamera {
                self.nextVC()
            }
            self.updatedGrants()
        }
    }
    /// Whether or not microphone has been granted, on set, if true, goes to the next screen
    var grantedMic:Bool = false {
        didSet {
            if grantedMic {
                self.nextVC()
            }
            self.updatedGrants()
        }
    }
    /// Whether or not location has been granted, on set, if true, goes to the next screen
    var grantedLocation:Bool = false {
        didSet {
            if grantedLocation {
                self.nextVC()
            }
            self.updatedGrants()
        }
    }
    
    /// The CLLocationManager used to verify location permissions, not instantitated until first use
    lazy var locationManager: CLLocationManager = CLLocationManager()
    
    /// The currently represented permission type (which decides which content is displayed & what happens when the permission button is pressed), defaults to microphone, is the presenting view controllers responsibility to set the correct permission before presentation
    var permissionType:PermissionType = .microphone
    
    /// The content that is to be displayed, which is created based on the PermissionType
    var permissionContent:PermissionContent? {
        didSet {
            // update content
            self.permissionLabel.text = self.permissionContent?.titleText ?? ""
            self.permissionButton.setTitle(self.permissionContent?.buttonText ?? "", for: .normal)
            self.permissionButton.emoji = self.permissionContent?.emojiString ?? ""
            self.imageView.kf.setImage(with: Bundle.main.url(forResource: self.permissionContent?.gifName, withExtension: "gif"))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.permissionContent = PermissionContent(permissionType: self.permissionType)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.rightConstraint.constant = -self.containerView.frame.size.width
        self.containerView.layer.opacity = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		self.imageView.startAnimating()
        UIView.animate(
            withDuration: transitionTime,
            delay: transitionDelay,
            options: .curveEaseInOut,
            animations: {
                self.containerView.layer.opacity = 1
                self.rightConstraint.constant = 0
                self.view.layoutIfNeeded()
        })
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.imageView.stopAnimating()
		self.permissionLabel.text = nil
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func displayPermissionAlert(sender: BigYellowButton) {
        switch self.permissionType {
        case .camera:
            self.grantCamera(sender)
            break
        case .microphone:
            self.grantMicrophone(sender)
            break
        case .location:
            self.grantLocation(sender)
			break
        case .notifications:
            self.grantNotifications()
            break
        }
    }
    
    func updatedGrants() {
        if Achievements.shared.grantedPermissionsV2 || (grantedCamera && grantedMic && grantedLocation) {
            Achievements.shared.grantedPermissionsV2 = true
        }
    }

    
    func grantCamera(_ sender: BigYellowButton) {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != .authorized {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (videoGranted: Bool) -> Void in
                if !videoGranted {
                    let alert = UIAlertController(title: "Monkey needs access to camera 📷", message: "Please give Monkey access to camera in the Settings app.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Sure", style: .cancel, handler: {
                        (UIAlertAction) in
                        
                        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.openURL(settingsUrl)
                            self.grantedCamera = true
                        }
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.grantedCamera = true
                }
            })
        }
        else {
            self.grantedCamera = true
        }
    }
    
    func grantLocation(_ sender: BigYellowButton) {
        guard CLLocationManager.authorizationStatus() == .notDetermined else {
            grantedLocation = true
            return
        }
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Called when location authorization is changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // We want to set grantedLocation to true regardless of whether the user granted location access or not.
        // However, when the location permissions popup appears, the authorization status changes to .notDetermined, in which case we don't want grantedLocation to change.
        guard status != .notDetermined else {
            return
        }
        grantedLocation = true
    }
    
    
    func grantMicrophone(_ sender: BigYellowButton) {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (audioGranted: Bool) -> Void in
            if (audioGranted) {
                self.grantedMic = true
            } else {
                let alert = UIAlertController(title: "Monkey needs access to microphone 🎙", message: "Please give Monkey access to microphone in the Settings app.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Sure", style: .cancel, handler: {
                    (UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        self.grantedMic = true
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func grantNotifications() {
        // iOS 10 notification granting
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
                Achievements.shared.promptedNotifications = granted
            }
        } else { // iOS 9 notification granting
            UIApplication.shared.registerForRemoteNotifications()
        }
       
        self.doneWithPermisssions()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func nextVC() {
        DispatchQueue.main.async {
            
            var nextViewController:UIViewController?
            
            switch self.permissionType {
            case .camera:
                let locVC = self.storyboard?.instantiateViewController(withIdentifier: "permVC") as? PermissionViewController
                locVC?.permissionType = .location
                nextViewController = locVC
                break
            case .microphone:
                let camVC = self.storyboard?.instantiateViewController(withIdentifier: "permVC") as? PermissionViewController
                camVC?.permissionType = .camera
                nextViewController = camVC
                break
            case .location:
                let notifVC = self.storyboard?.instantiateViewController(withIdentifier: "permVC") as? PermissionViewController
                notifVC?.permissionType = .notifications
                nextViewController = notifVC
                break
            case .notifications:
                self.doneWithPermisssions()
                break
           }
            
            guard let vcToPush = nextViewController else {
                return
            }
            
            UIView.animate(
                withDuration: self.transitionTime,
                delay: self.transitionDelay,
                options:.curveEaseInOut,
                animations: {
                    self.rightConstraint.constant = self.containerView.frame.width
                    self.containerView.alpha = 0
                    self.view.layoutIfNeeded()
            })
            
            // 0.7 seconds refers to the delay for content to move to the side before allowing the next view controller to appear without animation (but appear smooth)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (Double(0.7))) {
                self.present(vcToPush, animated: false)
            }
        }
    }
    
    func doneWithPermisssions() {
        DispatchQueue.main.async {
            guard let mainVC = self.storyboard!.instantiateViewController(withIdentifier: "mainVC") as? MainViewController else {
                return
            }
            mainVC.modalTransitionStyle = .crossDissolve
            
            self.present(mainVC, animated: true, completion: { _ in })
            Achievements.shared.grantedPermissionsV2 = true
        }
    }
}

enum PermissionType: String {
    case camera = "Camera"
    case microphone = "Microphone"
    case location = "Location"
    case notifications = "Notifications"
}

struct PermissionContent {
    var permissionType:PermissionType
    var titleText:String?
    var buttonText:String?
    var gifName:String?
    var emojiString:String?
    
    init(permissionType:PermissionType) {
        self.permissionType = permissionType
        
        switch self.permissionType {
        case .camera:
            self.titleText = "Kanye hates the paparazzi"
            self.buttonText = "Give up your camera"
            self.gifName = "onboarding-2"
            self.emojiString = "📷"
            break
        case .microphone:
            self.titleText = "Kanye wants to rant"
            self.buttonText = "Pass him your mic"
            self.gifName = "onboarding-1"
            self.emojiString = "🎤"
            break
        case .location:
            self.titleText = "Kim can’t find Kanye"
            self.buttonText = "Share your location"
            self.gifName = "onboarding-3"
            self.emojiString = "🌍"
            break
        case .notifications:
            self.titleText = "OK we’re out of Kanye jokes"
            self.buttonText = "Enable notifications anyway"
            self.gifName = "onboarding-4"
            self.emojiString = "🔔"
            break
        }
    }
}
