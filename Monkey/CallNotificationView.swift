//
//  CallNotificationView.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/8/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class CallNotificationView:MessageNotificationView {
    @IBOutlet weak var callButton:JigglyButton!
    @IBOutlet weak var emojiLabel: EmojiLabel!
    var chatSession:ChatSession?
    var onAccept: (() -> Void)?
    var isMissed:Bool?
    
    // Default notification implementation starts a timer to auto dismiss after a few seconds. We don't want a fixed auto dismiss for call notifications so we override w empty implementation
    override func startTimer() {
        // I just meditate
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        callButton.emojiLabel = self.emojiLabel
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        callButton.layer.cornerRadius = self.frame.size.width / 2.0
        callButton.layer.masksToBounds = true
    }
    
    @IBAction func callFriend(sender:JigglyButton) {
        self.onAccept?()
//        self.dismiss()
    }
    
    override class func instanceFromNib() -> CallNotificationView {
        let view = UINib(nibName: "CallNotificationView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CallNotificationView
        return view
    }
    
    override func dismiss() {
        super.dismiss()
    }
        
}
