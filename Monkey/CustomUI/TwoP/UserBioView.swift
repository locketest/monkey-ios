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
	var avatarBorder: UIView = UIView()
	var avatarView: UIImageView = UIImageView()
	var bioLabel: UILabel = UILabel()
	
	func configureApperance() {
		self.backgroundColor = UIColor.clear
		
		self.bioLabel.font = UIFont.systemFont(ofSize: 13)
		self.bioLabel.textColor = UIColor.white
		self.bioLabel.textAlignment = .center
		
		self.avatarBorder.layer.cornerRadius = 28
		self.avatarBorder.layer.borderColor = UIColor.init(red: 125.0 / 255.0, green: 116.0 / 255.0, blue: 153.0 / 255.0, alpha: 1).cgColor
		self.avatarBorder.layer.masksToBounds = true
		self.avatarBorder.layer.borderWidth = 2.0
		
		self.avatarView.layer.cornerRadius = 26
		self.avatarView.layer.masksToBounds = true
		self.avatarBorder.addSubview(self.avatarView)
		self.avatarView.snp.makeConstraints { (maker) in
			maker.center.equalTo(0)
			maker.width.height.equalTo(52)
		}
		
		self.container.alignment = .fill
		self.container.distribution = .equalSpacing
		self.container.axis = .vertical
		self.container.spacing = 13.0
		self.container.addArrangedSubview(self.avatarBorder)
		self.container.addArrangedSubview(self.bioLabel)
		self.avatarBorder.snp.makeConstraints { (maker) in
			maker.width.height.equalTo(56)
		}
		
		self.addSubview(container)
		self.container.snp.makeConstraints { (maker) in
			maker.center.equalTo(0)
		}
	}
	
	func show(with user: MatchUser) {
		let avatarUrl: URL? = URL.init(string: user.photo_read_url ?? "")
		let placeholder: UIImage? = UIImage.init(named: user.defaltAvatar)
		self.avatarView.kf.setImage(with: avatarUrl, placeholder: placeholder)
		self.bioLabel.text = user.showedBio()
	}
}

