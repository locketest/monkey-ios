//
//  MessageNotification.swift
//  Monkey
//
//  Created by Philip Bernstein on 7/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class MessageNotificationView: MakeUIViewGreatAgain, UIGestureRecognizerDelegate {
    @IBOutlet var profileImageView:CachedImageView!
    @IBOutlet var profileNameLabel:UILabel!
    @IBOutlet var notificationDescriptionLabel:UILabel!
    
    var lastFrame:CGRect?
    /// How many pixels up need to be swiped to dismiss notification
    let triggerOffset:CGFloat = UIApplication.shared.statusBarFrame.size.height + 1
    /// Closure that will be executed if the notification banner is tapped
    var onTap: (() -> Void)?
    var onShow:(() -> Void)?
    var onDismiss: (() -> Void)?

    /// Closure that will be executed if the notification banner is swiped up
    var onSwipeUp: (() -> Void)?
    var dismissTimer:Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    class func instanceFromNib() -> MessageNotificationView {
        let view = UINib(nibName: "MessageNotificationView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! MessageNotificationView
        return view
    }
    
    func startTimer() {
        guard dismissTimer == nil else {
            return
        }
        
        dismissTimer = Timer.scheduledTimer(timeInterval: 3.00,
                                            target: self,
                                            selector: #selector(dismiss),
                                            userInfo: nil,
                                            repeats: false)
    }
    
    func stopTimer() {
        
        guard dismissTimer != nil else {
            return
        }
        
        if dismissTimer?.isValid == true{
            dismissTimer?.invalidate()
            dismissTimer = nil
        }
    }
    var isDismissed = false
    func dismiss() {
        guard !isDismissed else { return }
        isDismissed = true
        self.onDismiss?()
        UIView.animate(withDuration: 0.3, animations: {
            var frame = self.frame
            frame.origin.y = -1 * self.frame.size.height
            self.frame = frame
        }, completion: { [weak self] (success) in
            self?.removeFromSuperview()
        })
    }
    
    @IBAction func notificationTapped(sender:UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        self.stopTimer()
        
        self.onTap?()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.frame = CGRect(x: 0, y: -1 * self.frame.size.height, width: UIScreen.main.bounds.width, height: self.frame.size.height)
        }, completion: { [weak self] (success) in
            self?.removeFromSuperview()
        })
    }
    
    @IBAction func notificationPanned(sender:UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        
        if sender.state == .began {
            self.stopTimer()
            lastFrame = self.frame
        } else if sender.state == .changed {
            guard let frame = lastFrame else {
                return
            }
            
            var valueToAdd:CGFloat = translation.y
            
            if (valueToAdd > 0 && self.frame.origin.y >= CGFloat(UIApplication.shared.statusBarFrame.size.height + 1)) {
                valueToAdd /= 2
            }
            
            let newY = frame.origin.y + valueToAdd
            var newFrame = frame
            newFrame.origin.y = newY
            self.frame = newFrame
            
        } else if sender.state == .ended || sender.state == .cancelled {
            self.startTimer()
            if self.frame.origin.y < -1 * triggerOffset { // snap back to 0
                UIView.animate(withDuration: 0.3, animations: {
                    var frame = self.frame
                    frame.origin.y = -1 * self.frame.size.height
                    self.frame = frame
                }, completion: { [weak self] (success) in
                    self?.stopTimer()
                    self?.onSwipeUp?()
                    self?.removeFromSuperview()
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    var frame = self.frame
                    frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 1
                    self.frame = frame
                })
            }
        }
    }
    
    public func show() {
        let frame = CGRect(x: 0, y: -94, width: UIScreen.main.bounds.width, height: 94)
        self.frame = frame
        
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3, animations: {
            let frame = CGRect(x: 0, y: UIApplication.shared.statusBarFrame.size.height + 1, width: UIScreen.main.bounds.width, height: 94)
            self.frame = frame
        }, completion: { [weak self] (success) in
            self?.onShow?()
            self?.startTimer()
        })
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
