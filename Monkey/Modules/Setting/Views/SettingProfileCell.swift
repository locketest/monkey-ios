//
//  SettingProfileCell.swift
//  Monkey
//
//  Created by fank on 2018/5/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  setting profile cell

import UIKit

protocol SettingProfileCellDelegate : NSObjectProtocol {
    func editProfileBtnClickFunc()
    func uploadedProfileImageSuccessFunc()
}

class SettingProfileCell: UITableViewCell, ProfilePhotoButtonViewDelegate {
    
    var viewController : UIViewController?
    
    var delegate : SettingProfileCellDelegate?

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var editProfileButton: UIButton!
    
    @IBOutlet weak var profilePhotoView: ProfilePhotoButtonView!
    
    @IBAction func editProfileBtnClickFunc(_ sender: UIButton) {
        
//        self.editProfileButton.isSelected = !self.editProfileButton.isSelected
        
        if self.delegate != nil {
            self.delegate!.editProfileBtnClickFunc()
        } else {
            print("代理为空")
        }
    }
    
    var settingModel : SettingModel {
        get {
            return SettingModel()
        }
        set(newSettingModel){
            
            self.selectionStyle = .none
            
            self.profilePhotoView.delegate = self
            self.profilePhotoView.lightPlaceholderTheme = true
            self.profilePhotoView.presentingViewController = self.viewController!
            
            self.nameLabel.text = newSettingModel.textString
            
            self.timeLabel.text = newSettingModel.timeString
            
            if let photoURL = APIController.shared.currentUser?.profile_photo_upload_url {
                _ = ImageCache.shared.load(url: photoURL, callback: {(result) in
                    switch result {
                    case .error(let error):
                        print("Get user profile photo error : \(error)")
                    case .success(let cacheImage):
                        if let image = cacheImage.image {
                            self.profilePhotoView.setProfile(image: image)
                        }
                    }
                })
            }
        }
        
    }
    
    func profilePhotoButtonView(_ profilePhotoButtonView: ProfilePhotoButtonView, selectedImage: UIImage) {
        self.profilePhotoView.profileImage = selectedImage
        self.profilePhotoView.uploadProfileImage {
            print("Uploaded profile image")
            
            if self.delegate != nil {
                self.delegate!.uploadedProfileImageSuccessFunc()
            } else {
                print("代理为空")
            }
        }
    }
    
}
