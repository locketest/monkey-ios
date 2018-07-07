//
//  FilterViewController.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class FilterViewController: SwipeableViewController {

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
		let currentFilter = Achievements.shared.selectMonkeyFilter
		let keep = initialFilter == currentFilter
		AnalyticsCenter.log(withEvent: .videoFilterSelect, andParameter: [
			"type": keep ? "keep" : "change",
			"name": currentFilter,
			])
	}

	func configureApperance() {
		self.filterCollection.frame = CGRect.init(x: 6, y: self.view.frame.size.height - 100 - 107, width: self.view.frame.size.width - 12, height: 107)
		self.filterCollection.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		self.view.addSubview(self.filterCollection)

		let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(closeFilterCollection))
		self.view.addGestureRecognizer(tapGesture)
		tapGesture.delegate = self
	}

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
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
