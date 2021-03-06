//
//  FriendTableViewCell.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: CachedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var unreadMessageContainerRing: MakeUIViewGreatAgain!
    @IBOutlet weak var profilePhotoSizeConstraint: NSLayoutConstraint!
    
    override func layoutSubviews() {
        if self.profileImageView != nil {
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
            self.profileImageView.layer.masksToBounds = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configureWithFriendship(_ friendship: RealmFriendship) {
        
        self.usernameLabel.text = friendship.user?.first_name ?? friendship.user?.username ?? "them"
		
		var imageName = "ProfileImageDefaultMale"
		if friendship.user?.gender == Gender.female.rawValue {
			imageName = "ProfileImageDefaultFemale"
		}
		self.profileImageView.placeholder = imageName
		self.profileImageView.url = friendship.user?.profile_photo_url
    }
}
