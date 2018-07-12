//
//  MainViewController+Clock.swift
//  Monkey
//
//  Created by Philip Bernstein on 7/9/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import AudioToolbox

// Extension for MainViewController to help with Timimg
extension CallViewController: CountingLabelDelegate {
	func minuteAdded() {
		self.enableAddMinute()
		
		clockLabel.formatBlock = {
			(value) in
			let seconds = Int(value / 1000)
			let minute: Int = seconds / 60
			let second: Int = seconds % 60
			return String(format: "%02d:%02d", minute, second)
		}
		
		clockLabel.completionBlock = {
			self.isAnimatingMinuteAdd = false
			UIView.animate(
				withDuration: 0.3,
				delay: 0,
				options: UIViewAnimationOptions.allowUserInteraction,
				animations: {
					for subview in self.clockLabelBackgroundView.subviews {
						subview.transform = CGAffineTransform.identity
					}
					self.clockLabelBackgroundView.transform = CGAffineTransform.identity
			})
		}
		AudioServicesPlayAlertSound(1519) // kSystemSoundID_Vibrate: (this is  `Peek` or a weak boom, 1520 is `Pop` or a strong boom)
		Achievements.shared.minuteMatches += 1
		let oldValue = clockTime
		clockTime += 60 * 1000
		self.isAnimatingMinuteAdd = true
		UIView.animate(
			withDuration: 0.3,
			delay: 0,
			options: UIViewAnimationOptions.allowUserInteraction,
			animations: {
				for subview in self.clockLabelBackgroundView.subviews {
					subview.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
				}
				self.clockLabelBackgroundView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
		},
			completion: { Bool in
				// We pause ticks while the label is animating so we need to account for the time that would have been ticked down
				let duration = TimeInterval(2)
				self.clockTime -= Int(duration) * 1000
				self.clockLabel.countFrom(CGFloat(oldValue), to: CGFloat(self.clockTime), withDuration:duration)
		})
		
		
		soundPlayer.play(sound: .score)
		for _ in 1...18 {
			let emojiLabel = UILabel()
			let clockEmojiCount: Int = clocks.count
			let offSet: Int = abs(Int.arc4random()) % clockEmojiCount
			
			emojiLabel.text = String(clocks[clocks.index(clocks.startIndex, offsetBy: offSet)])
			emojiLabel.font = UIFont.systemFont(ofSize: 39.0)
			let xDifference: CGFloat = CGFloat(arc4random_uniform(100))
			
			let originX: CGFloat = self.addMinuteButton.frame.origin.x + xDifference
			emojiLabel.frame = CGRect(x: originX, y: self.addMinuteButton.frame.origin.y, width: 50, height: 50)
			
			let duration: TimeInterval = (TimeInterval(arc4random_uniform(200)) / 100)
			UIView.animate(withDuration: duration, animations: {
				emojiLabel.layer.opacity = 0.0
				emojiLabel.frame.origin.y = self.containerView.frame.size.height - 350
			}) { (Bool) in
				emojiLabel.removeFromSuperview()
			}
			self.containerView.insertSubview(emojiLabel, belowSubview: self.addMinuteButton)
		}
	}
	
	func dripClock() {
		let clock = UILabel()
		
		if arc4random_uniform(2) == 0 {
			clock.text = "🕑"
		} else if self.matchModel.left.friendMatched == true {
			clock.text = "✌️"
		} else {
			clock.text = "‼️"
		}
		
		clock.font = UIFont.systemFont(ofSize: 39.0)
		let size:CGFloat = 60
		clock.frame = CGRect(x: self.statusCornerView.frame.origin.x + self.statusCornerView.frame.size.width - size, y: self.statusCornerView.frame.origin.y + self.statusCornerView.frame.size.height - size, width: size, height: size)
		self.containerView.insertSubview(clock, belowSubview: statusCornerView)
		UIView.animate(withDuration: 0.7, delay: 0.3, options: .curveEaseIn, animations:{
			clock.layer.opacity = 0
		})
		UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseOut, animations: {
			let radius: Double = 300
			let angle: Double = Double(self.randomBetweenNumbers(firstNum: 0.1, secondNum: 0.510) * CGFloat.pi)
			let x: Double = cos(angle)
			let y: Double = sin(angle)
			clock.frame = CGRect(x: x * radius, y: y * radius, width: 60, height: 60)
		}) { (Bool) in
			clock.removeFromSuperview()
		}
	}
	
	func tick() {
		if isAnimatingMinuteAdd { return }
		
		if clockTime <= -1 {
			clockLabel.text = "99:99"
			return
		}
		
		if self.matchModel.isVideoCall {
			clockTime += 100
			clockLabel.text = "\(String(format: "%02d", (Int(clockTime / 1000) / 60))):\(String(format: "%02d", Int(clockTime / 1000) % 60))"
			currentMatchPastTime = 0
		} else {
			if clockTime > 0 {
				clockTime -= 100
				clockLabel.text = "\(String(format: "%02d", (Int(clockTime / 1000) / 60))):\(String(format: "%02d", Int(clockTime / 1000) % 60))"
				
				currentMatchPastTime += 100
				if currentMatchPastTime == 5000 {
					autoScreenShotUpload(source: .match_5s)
				}
			}
			if clockTime <= 3900 && clockTime > 300 {
				if let chat = self.matchModel as? MatchModel, chat.isReportPeople() == false {
					dripClock()
				}
			}
			if clockTime == 3900 {
				if let chat = self.matchModel as? MatchModel, chat.isReportedPeople() == false {
					self.soundPlayer.play(sound: .clock)
				}
			} else if clockTime == 900 {
				self.soundPlayer.play(sound: .fail)
			} else if clockTime == 400 {
				self.dismiss(complete: nil)
			}
		}
	}
	
	func addFriendSuccess() {
		// friend added
		Achievements.shared.snapchatMatches += 1
		
		soundPlayer.play(sound: .win)
		animator.removeAllBehaviors()
		let gravityBehaviour = UIGravityBehavior()
		gravityBehaviour.gravityDirection = CGVector(dx: 0.0, dy: 1.6)
		animator.addBehavior(gravityBehaviour)
		var emojiLabels = Array<UILabel>()
		TapticFeedback.impact(style: .medium)
		
		for _ in 1...130 {
			let emojiLabel = UILabel()
			let randomIndex: Int = abs(Int.arc4random()) % winEmojis.count
			emojiLabel.text = String(winEmojis[winEmojis.index(winEmojis.startIndex, offsetBy: randomIndex)])
			emojiLabel.font = UIFont.systemFont(ofSize: 39.0)
			let positionX: CGFloat = self.snapchatButton.frame.origin.x + 30
			emojiLabel.frame = CGRect(x: positionX, y: self.snapchatButton.frame.origin.y, width: 50, height: 50)
			self.containerView.insertSubview(emojiLabel, belowSubview: self.snapchatButton)
			
			gravityBehaviour.addItem(emojiLabel)
			
			// This behaviour is included so that the alert view tilts when it falls, otherwise it will go straight down
			let itemBehaviour: UIDynamicItemBehavior = UIDynamicItemBehavior(items: [emojiLabel])
			itemBehaviour.addAngularVelocity(-(CGFloat.pi / 2), for: emojiLabel)
			animator.addBehavior(itemBehaviour)
			
			let pushBehavior: UIPushBehavior = UIPushBehavior(items: [emojiLabel], mode: .instantaneous)
			pushBehavior.pushDirection = CGVector(dx: self.randomBetweenNumbers(firstNum: -200, secondNum: 100), dy: -self.randomBetweenNumbers(firstNum: 0, secondNum: self.containerView.frame.size.height))
			pushBehavior.magnitude = self.randomBetweenNumbers(firstNum: 1.0, secondNum: 4.0)
			animator.addBehavior(pushBehavior)
			emojiLabels.append(emojiLabel)
		}
		
		// Animate out the overlay, remove the alert view from its superview and set it to nil
		// If you don't set it to nil, it keeps falling off the screen and when Show Alert button is
		// tapped again, it will snap into view from below. It won't have the location settings we defined in createAlert()
		// And the more it 'falls' off the screen, the longer it takes to come back into view, so when the Show Alert button
		// is tapped again after a considerable time passes, the app seems unresponsive for a bit of time as the alert view
		// comes back up to the screen
		let when = DispatchTime.now() + (Double(4.0))
		DispatchQueue.main.asyncAfter(deadline: when) {
			for emojiLabel in emojiLabels {
				emojiLabel.removeFromSuperview()
			}
		}
		
		self.stopClockTimer()
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) { [weak self] in
			self?.switchClock(open: false)
			self?.refresh(with: true)
		}
	}
	
	func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
		return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
	}
	
	// MARK: Snapchat Button
	@IBAction func addSnapchat(_ sender: BigYellowButton) {
		if Achievements.shared.addFirstSnapchat == false {
			Achievements.shared.addFirstSnapchat = true
			let addFirstSnapchatAlert = UIAlertController(title: nil, message: "To successfully add friends, both users have to tap the button", preferredStyle: .alert)
			addFirstSnapchatAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: { [weak self] (UIAlertAction) in
				guard let `self` = self else { return }
				self.addSnapchat()
			}))
			self.present(addFirstSnapchatAlert, animated: true)
		}else {
			self.addSnapchat()
		}
	}
	
	// MARK: - Minute Button
	@IBAction func addMinute(_ sender: BigYellowButton) {
		if Achievements.shared.isOnboardingExplainAddTimePopupCompleted == false {
			Achievements.shared.isOnboardingExplainAddTimePopupCompleted = true
			let explainAddTimeAlert = UIAlertController(title: nil, message: "To successfully add time, both users have to tap the button", preferredStyle: .alert)
			explainAddTimeAlert.addAction(UIAlertAction(title: "kk", style: .default, handler: { [weak self] (UIAlertAction) in
				guard let `self` = self else { return }
				self.addMinute()
			}))
			self.present(explainAddTimeAlert, animated: true, completion: nil)
		}else {
			self.addMinute()
		}
	}
	
	func addSnapchat() {
		// request to add snapchat
		self.disableAddSnapchat()
		guard let match = self.matchModel else { return }
		guard let authorization = UserManager.authorization else { return }
		
		JSONAPIRequest.init(url: "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/matches/\(match.match_id)/addfriend/\(match.left.user_id)", method: .post, options: [
			.header("Authorization", authorization)
			]).addCompletionHandler { (result) in
				print(result)
		}
		
		if match.left.friendRequested {
			match.left.friendAccept = true
			self.addFriendSuccess()
		}else {
			match.left.friendRequest = true
		}
		OnepMatchManager.default.sendMatchMessage(type: .AddFriend)
	}
	
	func addMinute() {
		// requested to add minute
		self.disableAddMinute()
		guard let match = self.matchModel as? MatchModel else { return }
		
		match.addTimeRequestCount += 1
		if match.addTimeRequestCount == match.left.addTimeCount {
			self.minuteAdded()
		}
		
		OnepMatchManager.default.sendMatchMessage(type: .AddTime)
	}
	
	func receivedAddTime(message: Message) {
		guard let match = self.matchModel as? MatchModel else { return }
		
		match.left.addTimeCount += 1
		if match.addTimeRequestCount == match.left.addTimeCount {
			self.minuteAdded()
		}
	}
	
	func receivedAddSnapchat(message: Message) {
		guard let match = self.matchModel else { return }
		
		if match.left.friendRequest {
			match.left.friendAccepted = true
			self.addFriendSuccess()
		}else {
			match.left.friendRequested = true
		}
	}
	
	func receivedTurnBackground(message: Message) {
		self.autoScreenShotUpload(source: .opponent_background)
	}
	
	func receivedReport(message: Message) {
		self.matchModel.left.reported = true
	}
	
	func disableAddSnapchat() {
		self.snapchatButton.isEnabled = false
		self.snapchatButton.layer.opacity = 0.5
	}
	
	func enableAddMinute() {
		self.addMinuteButton.isEnabled = true
		self.addMinuteButton.layer.opacity = 1.0
	}
	func disableAddMinute() {
		self.addMinuteButton.isEnabled = false
		self.addMinuteButton.layer.opacity = 0.5
	}
	
	// MARK: - CountingLabelDelegate
	func valueUpdated(to currentValue: CGFloat) {
		self.throttleFunction()
	}
}
