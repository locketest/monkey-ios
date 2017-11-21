//
//  CountingLabel.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 9/15/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class CountingLabel: UILabel {
    
    /// A block that converts the raw value into a formatted string for display
    public var formatBlock: ((CGFloat) -> String)?
    /// An optional block of code that performs on completion of the animation. Must be set for every animation because nilled out after running
    public var completionBlock: (() -> Void)?
    /// The value at the start of the animation
    private var startingValue: CGFloat?
    /// The final value at the end of the animation
    private var destinationValue: CGFloat?
    /// How far along (in seconds) we are into the animation
    private var progress: TimeInterval = 0
    /// The time at which the most recent update to the label occurred
    private var lastUpdate: TimeInterval?
    /// The time at which the animation will end at
    private var totalTime: TimeInterval?
    /// A timer object which updates the label based off framerate
    private weak var timer: CADisplayLink?
    /// The delegate for the label, currently only notified of updates to value
    var delegate:CountingLabelDelegate?
    
    
    /// This method triggers the animation of the label
    ///
    /// - Parameters:
    ///   - startValue: The value we want to start the animation with
    ///   - endValue: The value we want to animate the label to
    ///   - duration: Optional. Duration of animation, if left empty will use default value of TimeInterval(2)
    public func countFrom(_ startValue: CGFloat, to endValue: CGFloat, withDuration duration: TimeInterval = TimeInterval(2)) {
        self.startingValue = startValue
        self.destinationValue = endValue
        
        // remove any (possible) old timers
        self.timer?.invalidate()
        self.timer = nil
        
        if duration == 0.0 {
            // No animation
            self.setTextValue(endValue)
            self.runCompletionBlock()
            return
        }
        
        self.progress = 0
        self.totalTime = duration
        self.lastUpdate = Date.timeIntervalSinceReferenceDate
        
        let timer = CADisplayLink(target: self, selector: #selector(CountingLabel.updateValue(_:)))
        if #available(iOS 10.0, *) {
            timer.preferredFramesPerSecond = 30
        } else {
            timer.frameInterval = 2
        }
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        timer.add(to: RunLoop.main, forMode: RunLoopMode.UITrackingRunLoopMode)
        self.timer = timer
    }
    
    
    /// This method triggers the animation of the label starting from the current value
    ///
    /// - Parameters:
    ///   - endValue: The value we want to animate the label to
    ///   - duration: OPtional. Duration of the animation. If left empty will use the default calue of TimeInterval(2)
    public func countFromCurrentValueTo(_ endValue: CGFloat, withDuration duration: TimeInterval = TimeInterval(2)) {
        guard let currentValue = self.currentValue() else {
            return // error will print in currentValue()
        }
        self.countFrom(currentValue, to: endValue, withDuration: duration)
    }
    
    
    /// Returns the current value on the label, and tracks the progress of the animation based of its value.
    ///
    /// - Returns: The current value on the label.
    public func currentValue() -> CGFloat? {
        guard let totalTime = self.totalTime else {
            print("Error: trying to animate countingLabel without a duration ")
            return nil
        }
        
        guard let startingTime = self.startingValue, let destinationTime = self.destinationValue else {
            print("Error: trying to animate countingLabel without a starting or ending value")
            return nil
        }
        
        if self.progress == 0 {
            return 0
        } else if self.progress >= totalTime {
            return self.destinationValue
        }
        
        let percent = self.progress / totalTime
        let updateVal = self.update(CGFloat(percent))
        
        return startingTime + updateVal * (destinationTime - startingTime)
    }
    
    /// Updates the label based off how much time has passed. This function is triggered by the timer.
    ///
    /// - Parameter timer: The timer that triggers updates on the label
    public func updateValue(_ timer: Timer) {
        // update progress
        let now = Date.timeIntervalSinceReferenceDate
        let lastUpdate = self.lastUpdate ?? now
        guard let totalTime = self.totalTime else {
            return
        }
        self.progress = self.progress + now - lastUpdate
        self.lastUpdate = now
        
        if self.progress >= totalTime {
            self.timer?.invalidate()
            self.timer = nil
            self.progress = totalTime
        }
        
        guard let currentValue = self.currentValue() else {
            return
        }
        self.setTextValue(currentValue)
        self.delegate?.valueUpdated(to: currentValue)
        
        if self.progress >= totalTime {
            self.runCompletionBlock()
        }
    }
    
    /// Calculates the actual value that should be displayed on an easeOut animation curve
    ///
    /// - Parameter t: A value represnting the real progress of the animation
    /// - Returns: The adjusted value to display based off an easeOut approximation
    public func update(_ t: CGFloat) -> CGFloat {
        let rate = Float(3.5) // imitates an easeOut animation. The higher the value the more dramatic the beginning and the slower the end
        return CGFloat(1.0 - powf(Float(1.0 - t), rate))
    }
    
    /// Sets the text on the label, formatting it properly if a formatBlock has been set.
    ///
    /// - Parameter value: The value that will be displayed on the label
    private func setTextValue(_ value: CGFloat) {
        if let formatBlock = self.formatBlock {
            self.text = formatBlock(value)
        } else {
            self.text = String(Int(value)) // cast to int because we're counting with int

        }
    }
    
    /// Runs a completion block at the end of the animation, if there was one provided.
    private func runCompletionBlock() {
        if let completionBlock = self.completionBlock {
            completionBlock()
            self.completionBlock = nil
        }
    }
}

protocol CountingLabelDelegate:class {
    func valueUpdated(to currentValue:CGFloat)
}
