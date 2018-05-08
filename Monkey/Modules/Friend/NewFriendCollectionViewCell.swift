//
//  NewFriendCollectionViewCell.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class NewFriendCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profileImage: CachedImageView!
    var userId:String?
    
    override func layoutSubviews() {
        if self.profileImage != nil {
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2
        }
    }
    
}
