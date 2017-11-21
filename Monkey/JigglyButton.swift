//
//  JigglyButton.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/17/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class JigglyButton: BigYellowButton {

    @IBInspectable var isJiggling = false {
        didSet {
            guard oldValue != isJiggling else {
                return
            }
            
            if isJiggling {
                self.jiggleAndWait {}
            } else {
                self.numberOfJigglesLeft = 0
            }
        }
    }
    
    /// If jiggling, this will override stop that and start spinning instead
    var isSpinning = false {
        didSet {
            guard oldValue != isSpinning else {
                return
            }
            
            if isSpinning {
                if self.isJiggling {
                    self.isJiggling = false
                }
                self.straighten {
                    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
                    rotateAnimation.fromValue = 0.0
                    rotateAnimation.toValue = CGFloat(.pi * 2.0)
                    rotateAnimation.duration = 1.5
                    rotateAnimation.isRemovedOnCompletion = false
                    rotateAnimation.repeatCount = .infinity
                    
                    self.emojiLabel?.layer.add(rotateAnimation, forKey: nil)
                }
            } else {
                self.emojiLabel?.layer.removeAllAnimations()
                self.straighten { }
            }
        }
    }

    /// Default number of seconds between sets of jiggle cycles
    var delayBetweenJiggleCycles = 0.8
    
    /// Default umber of movements left and right between pauses
    var numberOfJigglesPerCycle = 6
    
    /// Default time to complete jiggles
    var secondsPerJiggleMovement = 0.12
    
    /// Number of movements left and right before the animation will stop. Set to 8 when jiggling endlessly and set to 0 to intercept the animation and stop at the next motion (used for instance when a call comes in to stop the animation ASAP without looking broken)
    private var numberOfJigglesLeft = 0
    
    private func jiggleAndWait(completion: @escaping() -> Void) {
        
        guard self.isJiggling else {
            // `isJiggling` was set to false during the delay between cycles of jiggles, so
            self.straighten(completion: completion)
            return
        }
        
        self.numberOfJigglesLeft = self.numberOfJigglesPerCycle
        self.jiggle {
            // Check to see if we should continue waiting and jiggling
            if self.isJiggling && !self.isSpinning {
                self.straighten {
                    self.delay(self.delayBetweenJiggleCycles, closure: {
                        self.jiggleAndWait(completion: completion)
                    })
                }
            } else {
                // No longer jiggling, so return button to normal state and finish
                self.straighten(completion: completion)
            }
        }
    }
    
    /// Jiggles the specified number of times before completing
    private func jiggle(completion: @escaping() -> Void) {
        // Check to see if we should stop jiggling and move to a pause
        if self.numberOfJigglesLeft > 0 {
            // Alternate left and right once
            self.jiggleCycle {
                self.numberOfJigglesLeft += -1
                // Call `jiggle` again to see if we should proceeed with another cycle or finish.
                self.jiggle(completion: completion)
            }
        } else {
            // No more jiggle cycles requested
            completion()
        }
    }
    
    private func jiggleCycle(completion: @escaping() -> Void) {
        
        // Jiggle to the right
        self.jiggleRight {
            // Jiggle to the left
            self.jiggleLeft {
                // Complete this cycle
                completion()
            }
        }
    }

    private func jiggleRight(completion: @escaping () -> Void) {
        // Transform 45 degrees clockwise
        UIView.animate(withDuration: secondsPerJiggleMovement, delay: 0, options: .beginFromCurrentState, animations: {
            self.emojiLabel?.transform = CGAffineTransform(rotationAngle: 45 * 2 * CGFloat.pi / 360)
        }, completion: { done in
            completion()
        })
    }
    
    private func jiggleLeft(completion: @escaping () -> Void) {
        // Transform 45 degrees counterclockwise
        UIView.animate(withDuration: secondsPerJiggleMovement, delay: 0, options: .beginFromCurrentState, animations: {
            self.emojiLabel?.transform = CGAffineTransform(rotationAngle: 45 * 2 * -CGFloat.pi / 360)
        }, completion: { done in
            completion()
        })
    }
    
    private func straighten(completion: @escaping () -> Void) {
        // Transform to the identity
        UIView.animate(withDuration: secondsPerJiggleMovement, delay: 0, options: .beginFromCurrentState, animations: {
            self.emojiLabel?.transform = .identity
        }, completion: { done in
            completion()
        })
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

