//
//  LocalPreviewContainer.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/9.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import SnapKit
import Hero

class LocalPreviewContainer: UIView {
	
	var switchCamerButton: SmallYellowButton?
	var pixellateable: Bool = false {
		didSet {
			if pixellateable {
				self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePublisherEffects)))
			}
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureApperance()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configureApperance()
	}
	
	func configureApperance() {
		self.layer.cornerRadius = 6.0
		self.layer.masksToBounds = true
//		self.hero.id = "LocalPreviewContainer"
//		self.hero.modifiers = [.cornerRadius(6), .ignoreSubviewModifiers]
	}
	
	func addLocalPreview() {
		HWCameraManager.shared().removePixellate()
		HWCameraManager.shared().changeCameraPosition(to: .front)
		let localPreview = HWCameraManager.shared().localPreviewView
		if localPreview.superview != self {
			self.addSubview(localPreview)
			self.sendSubview(toBack: localPreview)
		}
		localPreview.frame = self.bounds
		localPreview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	}
	
	func showSwitchCamera() {
		let switchCamerButton = SmallYellowButton.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
		switchCamerButton.emoji = "🔄"
		switchCamerButton.roundedSquare = true
		switchCamerButton.layer.cornerRadius = 0
		switchCamerButton.setBackgroundImage(UIImage.init(named: "switch_camera_back"), for: .normal)
		switchCamerButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
		self.addSubview(switchCamerButton)
		self.switchCamerButton = switchCamerButton
	}
	
	func togglePublisherEffects() {
		if HWCameraManager.shared().pixellated == false {
			HWCameraManager.shared().addPixellate()
		} else {
			HWCameraManager.shared().removePixellate()
		}
	}
	
	func switchCamera() {
		HWCameraManager.shared().rotateCameraPosition()
	}
}

