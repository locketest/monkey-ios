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
	
	/// Closure that will be executed if the notification banner is closed
	var onDismiss: ((_ auto: Bool) -> Void)?
	var onAccept: (() -> Void)?
	
	// audo dismiss delay
	private var dismissTimer: Timer?
	private var isDismissed = false
	
	private var lifeTime: TimeInterval = 5.0
	private var barStyle: Style! {
		didSet(newStyle) {
			switch newStyle {
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
											selector: #selector(dismiss(diy:)),
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
		self.stopTimer()
	}
	
	@IBAction func accept(_ sender: UIButton) {
		self.stopTimer()
	}
	
	func dismiss(diy: Bool = false) {
		guard isDismissed == false else { return }
		isDismissed = true
		
		self.onDismiss?(diy)
		UIView.animate(withDuration: 0.3, animations: {
			var frame = self.frame
			frame.origin.y = -1 * self.frame.size.height
			self.frame = frame
		}, completion: { [weak self] (success) in
			self?.removeFromSuperview()
		})
	}
}
