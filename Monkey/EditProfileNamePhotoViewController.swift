//
//  EditProfileNamePhotoViewController.swift
//  Monkey
//
//  Created by Harrison Weinerman on 5/3/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import Amplitude_iOS
import MMSProfileImagePicker

class EditProfileNamePhotoViewController: MonkeyViewController, MMSProfileImagePickerDelegate {

    /// A scroll view which contains all content except for the pickerContainerView.
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    /// When tapped, launches action sheet for Camera or Photo Library
    @IBOutlet weak var addPhotoButton: UIButton!
    
    /// Title label of the VC
    @IBOutlet var titleLabel: UILabel!
    
    /// Used to capture user first name
    @IBOutlet var firstNameTextField: UITextField!
    
    /// Triggers profile save/transition to next VC
    @IBOutlet var nextButton: BigYellowButton!
    
    /// The speed the UI animates into view after displaying Colors.blue.
    let transitionTime = 1.3
    /// The delay before the UI animates into view after displaying Colors.blue.
    let transitionDelay = 0.1
    /// Toggles transition to settings or main VC
    var isNewUser = true
    /// Selected profile image, or previously set profile image if available from server.
    var profileImage : UIImage? {
        didSet {
            addPhotoButton.setImage(profileImage, for: .normal)
            addPhotoButton.imageView!.contentMode = .scaleAspectFit
            addPhotoButton.layer.cornerRadius = addPhotoButton.frame.size.width / 2
            addPhotoButton.layer.masksToBounds = true
        }
    }
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var profilePicker : MMSProfileImagePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.firstNameTextField.becomeFirstResponder()
        // User has already signed up and set profile photo and is likely signing in on new installation. Show previously set profile photo from server.
        if let storedImageData = APIController.sharedInstance.currentUser?.photo {
            profileImage = UIImage(data: storedImageData as Data)
        }
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func selectProfilePhoto(_ sender: UIButton) {
        
        profilePicker = MMSProfileImagePicker()
        profilePicker.delegate = self
        
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { (action) in
            self.profilePicker.select(fromCamera: self)
        }
        controller.addAction(camera)
        
        let library = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            self.profilePicker.select(fromPhotoLibrary: self)
        }
        controller.addAction(library)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancel)
        
        self.present(controller, animated: true, completion: nil)
        
    }
    
    
    
    func mmsImagePickerControllerDidCancel(_ picker: MMSProfileImagePicker) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func mmsImagePickerController(_ picker: MMSProfileImagePicker, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info["UIImagePickerControllerEditedImage"] as? UIImage {
            // Got image, set property and update UI to indicate image is ready to be uploaded
            profileImage = image
        } else {
            print("Error: could not extract profile image after selection.")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }


    override func viewWillAppear(_ animated: Bool) {
        contentScrollView.alpha = 0
        UIView.animate(
            withDuration: transitionTime,
            delay: transitionDelay,
            usingSpringWithDamping: CGFloat(0.6),
            initialSpringVelocity: CGFloat(1.5),
            options: UIViewAnimationOptions.allowUserInteraction,
            animations: {
                self.contentScrollView.alpha = 1
        }, completion: nil)
    }
    
    /**
     Will trigger data submission except when the provided data is invalid.
     */
    @IBAction func nextVC(_ sender: BigYellowButton) {
        Amplitude.instance().logEvent("Edit Profile Name/Photo Completed")
        self.nextButton.isHidden = true
        self.activityIndicator.startAnimating()
        self.uploadProfile()
    }
    
    /**
     Uploads a users profile and then navigates to the next VC.
     */
    private func uploadProfile() {
        
        // You should not be able to access edit profile when not signed in.
        let currentUser = APIController.sharedInstance.currentUser!
        
        let attributes: [RealmUser.Attribute] = [
            .first_name(self.firstNameTextField.text),
            .photo(profileImage?.imageData as NSData?)
            ]
        
        currentUser.update(attributes: attributes) {(error) in
            guard error == nil else {
                let errorAlert = error!.toAlert(onRetry: { (UIAlertAction) in
                    self.uploadProfile()
                })
                self.present(errorAlert, animated: true)
                return
            }
            let identity = AMPIdentify()
            
            currentUser.first_name.then { identity.set("first_name", value: $0 as NSString) }
            currentUser.photo.then{ identity.set("photo", value: $0 as NSData) }
            
            Amplitude.instance().identify(identity)
            Achievements.sharedInstance.finishedOnboarding = true
            self.activityIndicator.stopAnimating()
            self.nextVC()
        }
    }
    
    /**
     Transitions to the next VC or dismisses depending on context.
     */
    private func nextVC() {
        if isNewUser {
            self.firstNameTextField.resignFirstResponder()
            
            UIView.animate(
                withDuration: transitionTime,
                delay: transitionDelay,
                usingSpringWithDamping: CGFloat(0.6),
                initialSpringVelocity: CGFloat(1.5),
                options: UIViewAnimationOptions.allowUserInteraction,
                animations: {
                    self.contentScrollView.layer.opacity = 0
            })
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (Double(0.7))) {
                if Achievements.sharedInstance.grantedPermissionsV2 {
                    self.present(self.storyboard!.instantiateViewController(withIdentifier: "mainVC"), animated: false, completion: nil)
                } else {
                    self.present(self.storyboard!.instantiateViewController(withIdentifier: "warningVC"), animated: false, completion: nil)
                }
            }
        } else {
            // Edit profile was presented over the settings VC.
            self.dismiss(animated: true, completion: nil)
        }
    }
 
}
