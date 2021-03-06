//
//  ProfilePhotoButtonView.swift
//  Monkey
//
//  Created by Harrison Weinerman on 5/6/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import Alamofire
import CropViewController

/**
 Contains a button that when tapped, allows user to choose between Camera/Photo Library to set a profile photo. Once cropped and saved, the button uploads and displays the profile photo.

 To use, simply set the `presentingViewController` property and place where desired.
 */
@IBDesignable class ProfilePhotoButtonView: UIView {
    weak var delegate: ProfilePhotoButtonViewDelegate?

    /// When tapped, launches action sheet for Camera or Photo Library
    var addPhotoButton: UIButton!

    var curImageV: UIImageView?

    var cachedImageView: CachedImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    /// Performs the initial setup.
    private func setupView() {
        addPhotoButton = UIButton(type: .custom)
        addPhotoButton.adjustsImageWhenHighlighted = false
        addPhotoButton.addTarget(self, action: #selector(selectProfilePhoto(_:)), for: .touchUpInside)
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addPhotoButton)
        self.addConstraints([
            // Pin right side
            NSLayoutConstraint(item: addPhotoButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0),
            // Pin left side
            NSLayoutConstraint(item: addPhotoButton, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
            // Pin top side
            NSLayoutConstraint(item: addPhotoButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
            // Pin height
            NSLayoutConstraint(item: addPhotoButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
            ])

        APIController.shared.currentUser?.profile_photo_url.then { (profilePhotoUrl) in
            let imageView = CachedImageView(url: profilePhotoUrl)
            self.cachedImageView = imageView
            imageView.translatesAutoresizingMaskIntoConstraints = false

            imageView.contentMode = .scaleAspectFit
            imageView.layer.masksToBounds = true

            imageView.layer.cornerRadius = imageView.frame.size.height / 2

            self.addPhotoButton.setImage(nil, for: .normal)

            imageView.isUserInteractionEnabled = false
            imageView.isExclusiveTouch = false
            self.addSubview(imageView)

			self.addConstraints([
				// Set width to height
				NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0.0),
				// Center X
				NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
				// Pin top side
				NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
				// Equal Height
				NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
				])

        }
    }

    /// When true, swaps the button placeholder image with a light variant. When false, shows the default dark purple graphic.
    @IBInspectable var lightPlaceholderTheme: Bool = false {
        didSet {
            guard self.cachedImageView == nil else {
                return
            }
            
            var defaultImage = "ProfileImageDefaultMale"
            
            if APIController.shared.currentUser?.gender == Gender.female.rawValue {
                defaultImage = "ProfileImageDefaultFemale"
            }
            
            addPhotoButton?.setImage(UIImage(named: defaultImage), for: .normal)
        }
    }

    /// The view controller that will present the picker. This almost always should be set to the ViewController that this button is placed on.
    var presentingViewController : UIViewController?

    /// Selected profile image, or previously set profile image if available from server.
    var profileImage : UIImage?

    func uploadProfileImage(callback: @escaping () -> Void) {
        guard let uploadURL = APIController.shared.currentUser?.profile_photo_upload_url else {
            print("Error: could not get URL to upload profile photo.")
            callback()
            return
        }
        guard let profileImage = self.profileImage else {
            callback()
            return
        }
        let profilePhoto = UIImageJPEGRepresentation(profileImage, 0.5)!

        Alamofire.upload(profilePhoto,
                         to: uploadURL,
                         method: .put,
                         headers: [
                            "Content-Type": "image/jpeg",
                            ])
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success:
                    ImageCache.shared.set(url: uploadURL, imageData: profilePhoto, callback: { (result) in
                        callback()
                    })
                case .failure(let error):
                    let alertController = UIAlertController(title: "Couldn't upload profile image.", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (UIAlertAction) in
                        APIController.shared.currentUser!.reload { (error) in
                            error?.log()
                            self.uploadProfileImage(callback: callback)
                        }
                    }))
                    self.presentingViewController?.present(alertController, animated: true, completion: nil)
                    return
                }
        }
    }

    /**
     Sets up the `addPhotoButton` to properly display circular image and sets the image. Also updates the `profileImage` property. Does not upload to network. If this is required, call `uploadProfileImage()`.
     - Parameter image: the profile image to be set.
     */
    func setProfile(image : UIImage) {
        // Cannot be set on button in profileImage didSet because properties are set before the VC is fully instantiated so properties are nil

        profileImage = image

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.frame = self.addPhotoButton.bounds
        imageView.frame.size.width = imageView.frame.size.height
        imageView.frame.origin.x = (self.frame.size.width - imageView.frame.size.width) / 2 // center x

        imageView.layer.cornerRadius = imageView.frame.size.height / 2

        if let curImgV = self.curImageV {
            curImgV.removeFromSuperview()
        }

        self.curImageV = imageView

        self.addPhotoButton.setImage(nil, for: .normal)

        imageView.isUserInteractionEnabled = false
        imageView.isExclusiveTouch = false
        self.addPhotoButton.addSubview(imageView)
    }

    /** Uploads the profile photo selected and logs how the photo was selected (currently from the photo button, or the menu option).
     - Parameter from: how the user initiated setting a profile photo
     */
    func setProfilePhoto() {
		AnalyticsCenter.log(withEvent: .settingClick, andParameter: [
			"type": "avatar",
			])
		
		let isAccountNew = UserManager.shared.loginMethod == .register
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { (action) in
			self.showPickerOption()
			AnalyticsCenter.log(withEvent: .settingAvatarClick, andParameter: [
				"type": isAccountNew ? "new" : "old",
				"info": "Camera",
				])
        }
        controller.addAction(camera)

        let library = UIAlertAction(title: "Photo Library", style: .default) { (action) in
			self.showPickerOption(sourceType: .photoLibrary)
			AnalyticsCenter.log(withEvent: .settingAvatarClick, andParameter: [
				"type": isAccountNew ? "new" : "old",
				"info": "Photo Library",
				])
        }
        controller.addAction(library)

		let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
			AnalyticsCenter.log(withEvent: .settingAvatarClick, andParameter: [
				"type": isAccountNew ? "new" : "old",
				"info": "Cancel",
				])
		}
		
        controller.addAction(cancel)

        presentingViewController?.present(controller, animated: true, completion: nil)
    }

    func selectProfilePhoto(_ sender: UIButton) {
        setProfilePhoto()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.cachedImageView?.layer.cornerRadius = self.bounds.height / 2
    }
}

extension ProfilePhotoButtonView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func showPickerOption(sourceType: UIImagePickerControllerSourceType = .camera) {
		let cameraImagePicker = UIImagePickerController()
		cameraImagePicker.delegate = self
		cameraImagePicker.sourceType = sourceType
		cameraImagePicker.allowsEditing = false
		self.presentingViewController?.present(cameraImagePicker, animated: true, completion: nil)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if let selectImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
			self.showImageProcess(handle: selectImage, from: picker)
		}else {
			picker.dismiss(animated: true, completion: nil)
		}
	}
}

extension ProfilePhotoButtonView: CropViewControllerDelegate {
	func showImageProcess(handle: UIImage, from: UINavigationController) {
		let cropViewController = CropViewController.init(croppingStyle: .circular, image: handle)
		cropViewController.delegate = self;
		cropViewController.rotateButtonsHidden = true;
		
		cropViewController.title = "Move and Scale";
		cropViewController.doneButtonTitle = "Choose";
		cropViewController.cancelButtonTitle = "Cancel";
		
		from.pushViewController(cropViewController, animated: true)
	}
	/**
	Called by profile picker controller when profile image has been selected. Updates profile image UI and uploads to server.
	- Parameters:
	- picker: the profile picker that selected the image
	- info: dictionary containing the original and cropped image. `UIImagePickerControllerEditedImage` key is the one we use.
	*/
	func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
		cropViewController.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	
	func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
		setProfile(image: image)
		self.cachedImageView?.removeFromSuperview()
		self.delegate?.profilePhotoButtonView(self, selectedImage: image)
		cropViewController.navigationController?.dismiss(animated: true, completion: nil)
	}
}

protocol ProfilePhotoButtonViewDelegate: class {
    func profilePhotoButtonView(_ profilePhotoButtonView: ProfilePhotoButtonView, selectedImage: UIImage)
}
