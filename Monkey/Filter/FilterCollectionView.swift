//
//  FilterCollectionView.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import ObjectMapper

class FilterCollectionView: MakeUIViewGreatAgain {
	
	var collectionView: UICollectionView!
	var flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
	
	static var filters: [MonkeyFilter] = FilterCollectionView.built_in_filters
	
	static var built_in_filters: [MonkeyFilter] {
		let built_in_filters_info: [[String: Any]] = [
			[
				"filter_title" : "Normal",
				"filter_icon" : "icon_normal",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "1977",
				"filter_icon" : "icon_1977",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Amaro",
				"filter_icon" : "icon_amaro",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Brannan",
				"filter_icon" : "icon_brannan",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Early Brid",
				"filter_icon" : "icon_earlybrid",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Hefe",
				"filter_icon" : "icon_hefe",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Hudson",
				"filter_icon" : "icon_hudson",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Inkwell",
				"filter_icon" : "icon_inkwell",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Lo-fi",
				"filter_icon" : "icon_lofi",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "LoardKelvin",
				"filter_icon" : "icon_loardkelvin",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Naville",
				"filter_icon" : "icon_naville",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Rise",
				"filter_icon" : "icon_rise",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Sierra",
				"filter_icon" : "icon_sierra",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Sutro",
				"filter_icon" : "icon_sutro",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Toaster",
				"filter_icon" : "icon_toaster",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Valencia",
				"filter_icon" : "icon_valencia",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "Walden",
				"filter_icon" : "icon_walden",
				"spoted": false,
				"download_complete": true,
				],
			[
				"filter_title" : "XproII",
				"filter_icon" : "icon_xproii",
				"spoted": false,
				"download_complete": true,
				],
		]
		let built_in_filters: [MonkeyFilter] = Mapper<MonkeyFilter>().mapArray(JSONArray: built_in_filters_info)
		return built_in_filters
	}
	
	var spotedIndex: Int = 0
	
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	func configureApperance() {
		self.cornerRadius = 12
		self.backgroundColor = UIColor.init(white: 0, alpha: 0.65)
		self.flowLayout.itemSize = CGSize.init(width: 70, height: 95)
		self.flowLayout.scrollDirection = .horizontal
		self.flowLayout.minimumInteritemSpacing = 6
		self.flowLayout.sectionInset = UIEdgeInsets.init(top: 6, left: 6, bottom: 6, right: 6)
		self.collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: self.flowLayout)
		self.addSubview(self.collectionView)
		self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.collectionView.showsVerticalScrollIndicator = false
		self.collectionView.showsHorizontalScrollIndicator = false
		self.collectionView.backgroundColor = UIColor.clear
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
		
		self.collectionView.register(UINib.init(nibName: "MonkeyFilterCell", bundle: Bundle.main), forCellWithReuseIdentifier: "MonkeyFilter")
		self.resetSpotedFilter()
	}
	
	func resetSpotedFilter() {
		for (index, filter) in FilterCollectionView.filters.enumerated() {
			if filter.filter_title == Achievements.shared.selectMonkeyFilter {
				filter.spoted = true
				spotedIndex = index
			}else {
				filter.spoted = false
			}
		}
		collectionView.scrollToItem(at: IndexPath.init(item: spotedIndex, section: 0), at: .centeredHorizontally, animated: true)
		collectionView.reloadData()
	}
}


extension FilterCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let selectFilter = FilterCollectionView.filters[indexPath.item]
		Achievements.shared.selectMonkeyFilter = selectFilter.filter_title ?? "Normal"
		HWCameraManager.shared().filterType = Achievements.shared.selectMonkeyFilter
		self.resetSpotedFilter()
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return FilterCollectionView.filters.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let filterCell: MonkeyFilterCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonkeyFilter", for: indexPath) as! MonkeyFilterCell
		filterCell.configure(with: FilterCollectionView.filters[indexPath.row])
		return filterCell
	}
}
