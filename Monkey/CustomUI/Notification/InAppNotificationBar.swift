//
//  InAppNotificationBar.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/1.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

class InAppNotificationBar: MakeUIViewGreatAgain {
	
	enum Style {
		case VideoCall
		case PairRequest
		case TwopInvite
		
		var lifeTime: TimeInterval {
			switch self {
			case .VideoCall:
				return 30
			default:
				return 5
			}
		}
		
		static func random() -> Style {
			let index = abs(Int.arc4random() % 3)
			return allValues[index]
		}
		
		static let allValues = [TwopInvite, PairRequest, VideoCall]
	}
	
	@IBOutlet var profileImageView: CachedImageView!
	@IBOutlet var profileNameLabel: UILabel!
	@IBOutlet var notificationDescriptionLabel: UILabel!
	
	@IBOutlet weak var rejectLabel: EmojiLabel!
	@IBOutlet weak var acceptLabel: EmojiLabel!
	@IBOutlet weak var acceptActivity: UIActivityIndicatorView!
	
	@IBOutlet weak var rejectButton: BigYellowButton!
	@IBOutlet weak var acceptButton: JigglyButton!
	
	/// Closure that will be executed if the notification banner accept is tapped
	var onAccept: (() -> Void)!
	var didAccept: (() -> Void)!
	var willDismiss: (() -> Void)!
	var didDismiss: (() -> Void)!
	var onDismiss: (() -> Void)!
	
	// audo dismiss delay
	private var dismissTimer: Timer?
	private var isDismissed = false
	
	private var lifeTime: TimeInterval = 5.0
	var barStyle: Style! {
		didSet(oldStyle) {
			self.lifeTime = barStyle.lifeTime
			switch barStyle {
			case .PairRequest:
				self.notificationDescriptionLabel.text = "wants to pair with you now"
			case .TwopInvite:
				self.notificationDescriptionLabel.text = "wants to invite you on 2P mode"
			case .VideoCall:
				self.notificationDescriptionLabel.text = "video call"
				self.acceptButton.backgroundColor = UIColor.init(red: 107.0 / 255.0, green: 68.0 / 255.0, blue: 1.0, alpha: 0.07)
				self.rejectLabel.text = "❌"
				self.acceptLabel.text = "📞"
			default:
				break
			}
		}
	}
	
	private var user: RealmUser! {
		didSet(oldValue) {
			// update apperance
			var imageName = "ProfileImageDefaultMale"
			if user.gender == Gender.female.rawValue {
				imageName = "ProfileImageDefaultFemale"
			}
			self.profileImageView.placeholder = imageName
			self.profileImageView.url = user.profile_photo_url
			self.profileNameLabel.text = user.first_name ?? "Your friend"
		}
	}
	
	class func instanceFromNib(user: RealmUser, style: Style) -> InAppNotificationBar {
		let view = UINib(nibName: "InAppNotificationBar", bundle: nil).instantiate(withOwner: nil, options: nil).first as! InAppNotificationBar
		view.isHidden = true
		view.frame = CGRect.init(x: 0, y: 0, width: Environment.ScreenWidth - 10, height: 76)
		view.user = user
		view.barStyle = style
		return view
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.configureApperance()
	}
	
	private func configureApperance() {
		self.profileImageView.layer.cornerRadius = 24
		self.profileImageView.layer.masksToBounds = true
		self.layer.cornerRadius = 13
		self.layer.masksToBounds = true
		self.backgroundColor = UIColor.white
		self.acceptActivity.isHidden = true
	}
	
	override func willMove(toWindow newWindow: UIWindow?) {
		super.willMove(toWindow: newWindow)
		
		if newWindow != nil {
			self.startTimer()
		}else {
			self.stopTimer()
		}
	}
	
	private func startTimer() {
		guard dismissTimer == nil else {
			return
		}
		
		dismissTimer = Timer.scheduledTimer(timeInterval: self.lifeTime,
											target: self,
											selector: #selector(notifyDismiss),
											userInfo: nil,
											repeats: false)
	}
	
	private func stopTimer() {
		guard let dismissTimer = dismissTimer else {
			return
		}
		
		dismissTimer.invalidate()
		self.dismissTimer = nil
	}
	
	
	@IBAction func ignore(_ sender: UIButton) {
		self.acceptButton.isEnabled = false
		self.notifyDismiss()
		self.didDismiss()
	}
	
	@IBAction func accept(_ sender: UIButton) {
		self.rejectButton.isEnabled = false
		self.acceptButton.isEnabled = false
		self.acceptActivity.isHidden = false
		self.acceptActivity.startAnimating()
		self.acceptLabel.removeFromSuperview()
		self.stopTimer()
		self.onAccept()
		self.didAccept()
	}
	
	@objc private func notifyDismiss() {
		self.willDismiss()
	}
	
	func present(animated: Bool) {
		if animated == false {
			self.isHidden = false
			self.alpha = 0
			UIView.animate(withDuration: 0.5, animations: {
				self.alpha = 1
			})
		}else {
			UIView.animate(withDuration: 0.5, animations: {
				self.isHidden = false
			})
		}
	}
	
	func dismiss(animated: Bool) {
		guard isDismissed == false else { return }
		isDismissed = true
		self.acceptButton.isEnabled = false
		self.rejectButton.isEnabled = false
		
		if animated == false {
			UIView.animate(withDuration: 0.5, animations: {
				self.alpha = 0
			}) { [weak self] (success) in
				self?.removeFromSuperview()
				self?.onDismiss()
			}
		}else {
			UIView.animate(withDuration: 0.5, animations: {
				self.isHidden = true
			}, completion: { [weak self] (success) in
				self?.removeFromSuperview()
				self?.onDismiss()
			})
		}
	}
}
