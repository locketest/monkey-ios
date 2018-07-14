//
//  UserBioView.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/11.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import Kingfisher
import SnapKit
import UIKit

class UserBioView: MakeUIViewGreatAgain {
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	var container: UIStackView = UIStackView()
//	var avatarBorder: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 60, height: 60))
	var avatarView: UIImageView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 52, height: 52))
	var bioLabel: UILabel = UILabel()
	
	func configureApperance() {
		self.backgroundColor = UIColor.clear
		
		self.bioLabel.font = UIFont.systemFont(ofSize: 13)
		self.bioLabel.textColor = UIColor.white
		self.bioLabel.textAlignment = .center
//		self.bioLabel.snp.makeConstraints { (maker) in
//			maker.width.lessThanOrEqualTo(80)
//		}
		
//		self.avatarBorder.layer.cornerRadius = 30
//		self.avatarBorder.layer.borderColor = UIColor.init(red: 125.0 / 255.0, green: 116.0 / 255.0, blue: 153.0 / 255.0, alpha: 1).cgColor
//		self.avatarBorder.layer.masksToBounds = true
//		self.avatarBorder.layer.borderWidth = 2.0
//		self.avatarBorder.snp.makeConstraints { (maker) in
//			maker.width.height.equalTo(60)
//		}
		
		self.avatarView.layer.cornerRadius = 26
		self.avatarView.layer.masksToBounds = true
		
		self.avatarView.layer.shadowColor = UIColor.black.cgColor
		self.avatarView.layer.shadowOpacity = 0.5
		self.avatarView.layer.shadowRadius = 4
//		self.avatarBorder.addSubview(self.avatarView)
		self.avatarView.snp.makeConstraints { (maker) in
			maker.width.height.equalTo(52)
//			maker.center.equalToSuperview()
		}
		
		self.container.alignment = .center
		self.container.distribution = .equalSpacing
		self.container.axis = .vertical
		self.container.spacing = 20.0
		self.addSubview(container)
		self.container.snp.makeConstraints { (maker) in
			maker.center.equalToSuperview()
		}
		
		self.container.addArrangedSubview(self.avatarView)
		self.container.addArrangedSubview(self.bioLabel)
	}
	
	func show(with user: MatchUser) {
		let avatarUrl: URL? = URL.init(string: user.photo_read_url ?? "")
		let placeholder: UIImage? = UIImage.init(named: user.defaultAvatar)
		self.avatarView.kf.setImage(with: avatarUrl, placeholder: placeholder)
		self.bioLabel.text = user.showedBio()
	}
}

