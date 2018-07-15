//
//  PairMatchViewController+Action.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/12.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import UIKit

extension PairMatchViewController: CountingLabelDelegate {
	func minuteAdded() {
		self.enableAddMinute()
		
		if let matchModel = self.matchModel, matchModel.addTimeCount() == 1 {
			MonkeyModel.request(url: "\(Environment.baseURL)/api/\(ApiVersion.V2)/matches/\(matchModel.match_id)/addtime", method: .post) { (_) in
				
			}
		}
		
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
			
			let originX: CGFloat = self.addTimeButton.frame.origin.x + xDifference
			emojiLabel.frame = CGRect(x: originX, y: self.addTimeButton.frame.origin.y, width: 50, height: 50)
			
			let duration: TimeInterval = (TimeInterval(arc4random_uniform(200)) / 100)
			UIView.animate(withDuration: duration, animations: {
				emojiLabel.layer.opacity = 0.0
				emojiLabel.frame.origin.y = self.view.frame.size.height - 350
			}) { (Bool) in
				emojiLabel.removeFromSuperview()
			}
			self.view.insertSubview(emojiLabel, belowSubview: self.addTimeButton)
		}
	}
	
	func dripClock() {
		let clock = UILabel()
		
		if arc4random_uniform(2) == 0 {
			clock.text = "🕑"
		} else {
			clock.text = "‼️"
		}
		
		clock.font = UIFont.systemFont(ofSize: 39.0)
		let size:CGFloat = 60
		clock.frame = CGRect(x: self.clockLabelBackgroundView.frame.origin.x + self.clockLabelBackgroundView.frame.size.width - size, y: self.clockLabelBackgroundView.frame.origin.y + self.clockLabelBackgroundView.frame.size.height - size, width: size, height: size)
		self.view.insertSubview(clock, belowSubview: self.clockLabelBackgroundView)
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
		
		if clockTime > 0 {
			clockTime -= 100
			clockLabel.text = "\(String(format: "%02d", (Int(clockTime / 1000) / 60))):\(String(format: "%02d", Int(clockTime / 1000) % 60))"
		}
		if clockTime <= 3900 && clockTime > 300 {
			if self.matchModel?.isReportPeople() == false {
				dripClock()
			}
		}
		if clockTime == 3900 {
			if self.matchModel?.isReportedPeople() == false {
				self.soundPlayer.play(sound: .clock)
			}
		} else if clockTime == 900 {
			self.soundPlayer.play(sound: .fail)
		} else if clockTime == 400 {
			self.disconnect(reason: .TimeOver)
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
			let positionX: CGFloat = self.addTimeButton.frame.origin.x + 30
			emojiLabel.frame = CGRect(x: positionX, y: self.addTimeButton.frame.origin.y, width: 50, height: 50)
			self.view.insertSubview(emojiLabel, belowSubview: self.addTimeButton)
			
			gravityBehaviour.addItem(emojiLabel)
			
			// This behaviour is included so that the alert view tilts when it falls, otherwise it will go straight down
			let itemBehaviour: UIDynamicItemBehavior = UIDynamicItemBehavior(items: [emojiLabel])
			itemBehaviour.addAngularVelocity(-(CGFloat.pi / 2), for: emojiLabel)
			animator.addBehavior(itemBehaviour)
			
			let pushBehavior: UIPushBehavior = UIPushBehavior(items: [emojiLabel], mode: .instantaneous)
			pushBehavior.pushDirection = CGVector(dx: self.randomBetweenNumbers(firstNum: -200, secondNum: 100), dy: -self.randomBetweenNumbers(firstNum: 0, secondNum: self.view.frame.size.height))
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
		
		self.checkFriendStatus()
	}
	
	func checkFriendStatus() {
		guard let match = self.matchModel else { return }
		
		if match.matched_pair() {
			if match.left.friendMatched && match.right?.friendMatched == true && match.left.user_info?.isFriendWithPair == true && match.left.user_info?.isFriendWithPair == true {
				self.refresh(with: true)
			}else {
				self.refresh(with: false)
			}
		}else if match.left.friendMatched && match.left.user_info?.isFriendWithPair == true {
			self.refresh(with: true)
		}else {
			self.refresh(with: false)
		}
	}
	
	func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
		return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
	}
	
	// MARK: - Minute Button
	@IBAction func addMinute(_ sender: BigYellowButton) {
		self.addMinute()
	}
	
	func addMinute(fromMySelf: Bool = true) {
		// requested to add minute
		self.disableAddMinute()
		guard let match = self.matchModel else { return }
		
		let addTimeRequestCount = match.addTimeRequestCount
		let matchAddTimeRequestCount = match.left.addTimeCount
		if addTimeRequestCount < matchAddTimeRequestCount {
			self.minuteAdded()
			match.addTimeRequestCount = matchAddTimeRequestCount
			self.friendPairModel.left.addTimeCount = matchAddTimeRequestCount
		}else {
			match.addTimeRequestCount = matchAddTimeRequestCount + 1
			self.friendPairModel.left.addTimeCount = matchAddTimeRequestCount + 1
		}
		
		if fromMySelf {
			OnepMatchManager.default.sendMatchMessage(type: .AddTime)
		}
	}
	
	func receivedAddTime(message: Message) {
		guard let match = self.matchModel else { return }
		if message.sender == self.friendPairModel.left.user_id {
			self.addMinute(fromMySelf: false)
		}else {
			let addTimeRequestCount = match.addTimeRequestCount
			let matchAddTimeRequestCount = match.left.addTimeCount
			if matchAddTimeRequestCount < addTimeRequestCount {
				self.minuteAdded()
				match.left.addTimeCount = addTimeRequestCount
				match.right?.addTimeCount = addTimeRequestCount
			}else {
				match.left.addTimeCount = addTimeRequestCount + 1
				match.right?.addTimeCount = addTimeRequestCount + 1
			}
		}
	}
	
	func receivedAddSnapchat(message: Message) {
		if message.sender == self.friendPairModel.left.user_id {
			if let target = message.target?.first, let user = matchModel?.matchedUser(with: target) {
				if user.user_info?.addFriendRequest == true {
					user.user_info?.addFriendAccept = true
					self.checkFriendStatus()
				}else {
					user.user_info?.addFriendRequest = true
				}
			}
		}else if let user = matchModel?.matchedUser(with: message.sender ?? 0) {
			if let target = message.target?.first, target == self.friendPairModel.left.user_id {
				if user.user_info?.addFriendRequest == true {
					user.user_info?.addFriendAccept = true
					self.checkFriendStatus()
				}else {
					user.user_info?.addFriendRequest = true
				}
			}else {
				if user.friendRequest == true {
					user.friendAccepted = true
					self.addFriendSuccess()
					self.remoteInfo?.addFriend(user: user)
				}else {
					user.friendRequested = true
				}
			}
		}
	}
	
	func receivedTurnBackground(message: Message) {
		self.autoScreenShotUpload(source: .opponent_background)
	}
	
	func receivedReport(message: Message) {
		if message.sender == self.friendPairModel.left.user_id {
			self.reportMatch()
		}
	}
	
	func enableAddMinute() {
		self.addTimeButton.isEnabled = true
		self.addTimeButton.layer.opacity = 1.0
	}
	
	func disableAddMinute() {
		self.addTimeButton.isEnabled = false
		self.addTimeButton.layer.opacity = 0.5
	}
	
	// MARK: - CountingLabelDelegate
	func valueUpdated(to currentValue: CGFloat) {
		self.throttleFunction()
	}
}

