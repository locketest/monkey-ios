//
//  MonkeyFilterCell.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class MonkeyFilterCell: UICollectionViewCell {

	@IBOutlet weak var borderView: UIView!
	@IBOutlet weak var filterImage: UIImageView!
	@IBOutlet weak var filterName: UILabel!
	
	func configure(with filter: MonkeyFilter) {
		filterImage.image = UIImage.init(named: filter.filter_icon!)
		filterName.text = filter.filter_title
		
		if filter.spoted == true {
			borderView.layer.borderColor = UIColor.yellow.cgColor
			filterName.textColor = UIColor.yellow
		}else {
			borderView.layer.borderColor = UIColor.clear.cgColor
			filterName.textColor = UIColor.white
		}
	}
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		borderView.layer.cornerRadius = 14
		borderView.layer.masksToBounds = true
		borderView.backgroundColor = UIColor.clear
		borderView.layer.borderColor = UIColor.clear.cgColor
		borderView.layer.borderWidth = 2.0
		
		filterImage.layer.cornerRadius = 12
		filterImage.layer.masksToBounds = true
		
		self.contentView.backgroundColor = UIColor.clear
		self.backgroundColor = UIColor.clear
    }
}
