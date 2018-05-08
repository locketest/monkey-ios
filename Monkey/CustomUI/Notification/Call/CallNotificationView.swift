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
    @IBOutlet weak var ignoreButton: JigglyButton!
    
    @IBOutlet weak var connectingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var ignoreLabel: EmojiLabel!
    var chatSession:ChatSession?
    var onAccept: (() -> Void)?
    var isMissed:Bool?
    var didShowed:Bool = false
    
    @IBOutlet weak var panGes: UIPanGestureRecognizer!
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
        if self.didShowed {
            return
        }
        self.didShowed = true
        callButton.layer.cornerRadius = self.frame.size.width / 2.0
        callButton.layer.masksToBounds = true
        ignoreButton.layer.cornerRadius = self.frame.size.width / 2.0
        ignoreButton.layer.masksToBounds = true
    }
    
    @IBAction func callFriend(sender:JigglyButton) {
        self.onAccept?()
//        self.dismiss()
        self.ignoreButton.isHidden = true
        self.connectingActivityIndicator.startAnimating()
        self.connectingActivityIndicator.isHidden = false
        self.emojiLabel.isHidden = true
        self.panGes.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now()+30) {
            //  make sure dismiss
            self.dismiss()
        }
    }
    
    @IBAction func ignoreCall(_ sender: JigglyButton) {
        self.dismiss()
        if let chatSession = self.chatSession {
            IncomingCallManager.shared.cancelVideoCall(chatsession: chatSession)
        }
    }
    
    override class func instanceFromNib() -> CallNotificationView {
        let view = UINib(nibName: "CallNotificationView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CallNotificationView
        return view
    }
    
    override func show() {
        let frame = CGRect(x: 0, y: -UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.frame = frame
        
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3, animations: {
            let frame = CGRect(x: 0, y: UIApplication.shared.statusBarFrame.size.height + 1, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            self.frame = frame
        }, completion: { [weak self] (success) in
            self?.onShow?()
            self?.startTimer()
        })
    }
    
    override func dismiss() {
        super.dismiss()
    }
        
}
