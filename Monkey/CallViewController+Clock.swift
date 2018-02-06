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
    
    func minuteAdded(in chatSession:ChatSession) {
        APIController.trackChatAddTimeSuccess()
        self.enableAddMinute()
        
        clockLabel.formatBlock = {
            (value) in
            return "\(String(format: "%02d", (Int(value / 1000) / 60))):\(String(format: "%02d", Int(value / 1000) % 60))"
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
                self.clockTime -= Int(duration)*1000
                self.clockLabel.countFrom(CGFloat(oldValue), to: CGFloat(self.clockTime), withDuration:duration)
        })
        
        
        soundPlayer.play(sound: .score)
        for _ in 1...18 {
            let emojiLabel = UILabel()
            emojiLabel.text = String(clocks[clocks.index(clocks.startIndex, offsetBy: (Int(arc4random_uniform(UInt32(clocks.count)))))])
            emojiLabel.font = UIFont.systemFont(ofSize: 39.0)
            let xDifference:CGFloat = CGFloat(arc4random_uniform(100))
            emojiLabel.frame = CGRect(x: self.addMinuteButton.frame.origin.x + xDifference, y: self.addMinuteButton.frame.origin.y, width: 50, height: 50)
            UIView.animate(withDuration: TimeInterval(CGFloat(arc4random_uniform(200)) / 100.0), animations: {
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
        clock.tag = 71074
        if arc4random_uniform(2) == 0 {
            clock.text = "🕑"
        } else {
            if self.chatSession?.friendMatched == true {
                clock.text = "✌️"
            } else {
                clock.text = "‼️"
            }
        }
        clock.font = UIFont.systemFont(ofSize: 39.0)
        let size:CGFloat = 60
        clock.frame = CGRect(x: self.statusCornerView.frame.origin.x + self.statusCornerView.frame.size.width - size, y: self.statusCornerView.frame.origin.y + self.statusCornerView.frame.size.height - size, width: size, height: size)
        self.containerView.insertSubview(clock, belowSubview: statusCornerView)
        UIView.animate(withDuration: 0.7, delay: 0.3, options: .curveEaseIn, animations:{
            clock.layer.opacity = 0
        })
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseOut, animations: {
            let radius:Double = 300
            let angle:Double = Double(self.randomBetweenNumbers(firstNum: 0.1, secondNum: 0.510) * CGFloat.pi)
            let x:Double = cos(angle)
            let y:Double = sin(angle)
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
        
        if self.chatSession?.isDialedCall == true {
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
                if let reported = self.chatSession?.isReportedChat , !reported {
                    dripClock()
                }
            }
            if clockTime == 3900 {
                if let reported = self.chatSession?.isReportedChat , !reported {
                    self.soundPlayer.play(sound: .clock)
                }
            } else if clockTime == 900 {
                // self.soundPlayer.play(sound: .fail)
            } else if clockTime == 400 {
                self.chatSession?.disconnect(.consumed)
            }
        }
    }
    
    // MARK: - Minute Button
    @IBAction func addMinute(_ sender: BigYellowButton) {
        guard Achievements.shared.isOnboardingExplainAddTimePopupCompleted else {
            let chatSession = self.chatSession
            let explainAddTimeAlert = UIAlertController(title: "🕑 Time?", message: "Tapping the Time button suggests that you want to keep talking.", preferredStyle: .alert)
            explainAddTimeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            explainAddTimeAlert.addAction(UIAlertAction(title: "Time", style: .default, handler: { (UIAlertAction) in
                if chatSession == self.chatSession && chatSession?.status == .connected {
                    self.addMinute()
                    Achievements.shared.isOnboardingExplainAddTimePopupCompleted = true
                }
            }))
            self.present(explainAddTimeAlert, animated: true)
            return
        }
        self.addMinute()
    }
    
    func addMinute() {
		AnaliticsCenter.log(event: .requestedMinuteDuringCall)
        self.disableAddMinute()
        let isWaiting = self.chatSession?.sendMinute() ?? false
        if isWaiting && !Achievements.shared.isOnboardingExplainTheyAddTimePopupCompleted {
            let explainAddTimeAlert = UIAlertController(title: "😢 You both have to tap Time", message: "The person you're talking to has to tap the Time button too for the call to continue.", preferredStyle: .alert)
            explainAddTimeAlert.addAction(UIAlertAction(title: "Got it!", style: .default, handler: { (UIAlertAction) in
                Achievements.shared.isOnboardingExplainTheyAddTimePopupCompleted = true
            }))
            self.present(explainAddTimeAlert, animated: true)
        }
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
