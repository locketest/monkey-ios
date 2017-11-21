//
//  RatingNotificationView.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/3/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class RatingNotificationView: MessageNotificationView {
    @IBOutlet var positiveButton:BigYellowButton!
    @IBOutlet var negativeButton:BigYellowButton!
    @IBOutlet var neutralButton:BigYellowButton!
    var onRate: ((ChatRating) -> Void)?
    
    @IBAction func ratePositive(_ sender:BigYellowButton) {
        self.onRate?(.nice)
    }
    
    @IBAction func rateNegative(_ sender:BigYellowButton) {
        self.onRate?(.mean)
    }
    
    @IBAction func rateNeutral(_ sender:BigYellowButton) {
        self.onRate?(.neutral)
    }
    
    override class func instanceFromNib() -> RatingNotificationView {
        let view = UINib(nibName: "RatingNotificationView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! RatingNotificationView
        return view
    }
    
    override func stopTimer() {
        // we don't want a timer for ratings, so left empty on purpose
    }
    override func notificationTapped(sender: UITapGestureRecognizer) {
        // Default implementation will dismiss the notification, we don't want to do that.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.negativeButton.layer.cornerRadius = 24
        self.negativeButton.layer.masksToBounds = true

        self.positiveButton.layer.cornerRadius = 24
        self.positiveButton.layer.masksToBounds = true

        self.neutralButton.layer.cornerRadius = 24
        self.neutralButton.layer.masksToBounds = true
    }
    
    override func show() {
        let frame = CGRect(x: 0, y: -124, width: UIScreen.main.bounds.width, height: 124)
        self.frame = frame
        
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3, animations: {
            let frame = CGRect(x: 0, y: UIApplication.shared.statusBarFrame.size.height + 1, width: UIScreen.main.bounds.width, height: 124)
            self.frame = frame
        }, completion: { [weak self] (success) in
            self?.onShow?()
        })
    }
}
