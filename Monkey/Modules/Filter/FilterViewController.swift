//
//  FilterViewController.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class FilterViewController: SwipeableViewController {
	
	override var contentHeight: CGFloat {
		return UIScreen.main.bounds.size.height - 50
	}
	
//	var arrowButton: BigYellowButton = BigYellowButton.init(frame: CGRect.zero)
	var filterCollection: FilterCollectionView = FilterCollectionView.init(frame: CGRect.zero)
	var initialFilter = Achievements.shared.selectMonkeyFilter

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.configureApperance()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.filterCollection.resetSpotedFilter()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		var currentFilter = Achievements.shared.selectMonkeyFilter
		var keep = initialFilter == currentFilter
		AnalyticsCenter.log(withEvent: .videoFilterSelect, andParameter: [
			"type": keep ? "keep" : "change",
			"name": currentFilter,
			])
	}
	
	func configureApperance() {
//		self.arrowButton.setImage(#imageLiteral(resourceName: "ArrowButtonDown"), for: .normal)
//		self.arrowButton.frame = CGRect.init(x: (self.view.frame.size.width - 47) / 2, y: self.view.frame.size.height - 50 - 30, width: 47, height: 30)
//		self.arrowButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin]
//		self.view.addSubview(self.arrowButton)
//		self.arrowButton.isUserInteractionEnabled = false
		
		self.filterCollection.frame = CGRect.init(x: 6, y: self.view.frame.size.height - 100 - 107, width: self.view.frame.size.width - 12, height: 107)
		self.filterCollection.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		self.view.addSubview(self.filterCollection)
		
		let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(closeFilterCollection))
		self.view.addGestureRecognizer(tapGesture)
		tapGesture.delegate = self
	}
	
	override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		var touchView: UIView? = touch.view
		while touchView != nil {
			if (touchView is FilterCollectionView) {
				return false
			}
			touchView = touchView?.superview
		}
		return true
	}
	
	func closeFilterCollection() {
		self.panningTowardsSide = .top
		self.dismiss(animated: true, completion: nil)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

