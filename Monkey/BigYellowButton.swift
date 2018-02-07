//
//  BigYellowButton.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/13/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit

@IBDesignable class BigYellowButton: UIButton {
    
    var emojiLabel:EmojiLabel?

    /// Toggles the button opacity and touch down animations.
    override var isEnabled: Bool {
        didSet {
            // Disabled buttons are transparent.
            self.alpha = isEnabled ? 1.0 : 0.5
            if isEnabled && isLoading { // Can't be loading and enabled
                self.isLoading = false
            }
        }
    }
        
    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    private var oldBackgroundColor: UIColor?
    /// Toggles the button opacity and touch down animations.
    @IBInspectable var isLoading: Bool = false {
        didSet {
            if isLoading {
                self.activityIndicatorView.startAnimating()
                self.titleLabel?.removeFromSuperview()
                self.emojiLabel?.isHidden = true
                self.oldBackgroundColor = self.backgroundColor
                self.backgroundColor = .clear
            } else {
                self.activityIndicatorView.stopAnimating()
                self.titleLabel.then { self.addSubview($0) }
                self.emojiLabel?.isHidden = false
                self.backgroundColor = self.oldBackgroundColor
            }
        }
    }
    @IBInspectable var loadingStyleIsWhite = true {
        didSet {
            if loadingStyleIsWhite {
                self.activityIndicatorView.activityIndicatorViewStyle = .white
            } else {
                self.activityIndicatorView.activityIndicatorViewStyle = .gray
            }
        }
    }

    /// When set to true, button will have a corner radius of 6 for a rounded square effect instead of a semi-circle endcap by default
    @IBInspectable var roundedSquare: Bool = false
    @IBInspectable var borderColor : UIColor = .clear {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }

    @IBInspectable var borderWidth : CGFloat = 0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var emojiY: CGFloat = 0.0
    @IBInspectable var emoji: String? {
        didSet {
            if let currentLabel = emojiLabel {
                currentLabel.removeFromSuperview()
            }
			emojiLabel = EmojiLabel()
            if let emojiString = emoji {
                emojiLabel!.text = emojiString
                emojiLabel!.layer.cornerRadius = 6.5
                emojiLabel!.clipsToBounds = true
                emojiLabel!.textAlignment = .center
                emojiLabel?.font = UIFont(name: "Apple Color Emoji", size: 18)
                if self.titleLabel?.text == nil {
                    emojiLabel?.font = UIFont(name: "Apple Color Emoji", size: 32)
                    emojiLabel?.frame = self.bounds
                    emojiLabel?.frame.size = CGSize(width: 57, height: 57)
                    self.addSubview(emojiLabel!)
                } else {
                    emojiLabel!.frame = CGRect(x: -29, y: -3, width: 25, height: 25)
                    self.titleLabel?.addSubview(emojiLabel!)
                    setPadding(12.5)
                }
            }
        }
    }
    
    @IBInspectable var emojiBackgroundColor: UIColor? {
        didSet {
            if let backgroundColor = emojiBackgroundColor {
                emojiLabel!.backgroundColor = backgroundColor
                emojiLabel!.font = UIFont.systemFont(ofSize: 13.0)
                emojiLabel!.frame = CGRect(x: -35, y: -3, width: 25, height: 25)
                emojiLabel!.leftInset = 3.0
                emojiLabel!.rightInset = 0.0
                emojiLabel!.topInset = -0.5
                if self.titleLabel?.textAlignment != .center {
                    setPadding(16)
                }
            }
        }
    }
    func setPadding(_ padding: CGFloat) {
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -emojiLabel!.frame.origin.x + padding, 0, padding);
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        afterInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        afterInit()
    }
    func afterInit() {
        self.showsTouchWhenHighlighted = false
        self.tintColor = .clear
        self.addTarget(self, action: #selector(buttonTouchDown), for: UIControlEvents.touchDown)
        self.addTarget(self, action: #selector(buttonTouchCancel), for: UIControlEvents.touchCancel)
        self.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControlEvents.touchUpInside)
        self.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControlEvents.touchUpOutside)
        self.addTarget(self, action: #selector(buttonTouchDragOutside), for: UIControlEvents.touchDragOutside)
        self.addTarget(self, action: #selector(buttonTouchDragInside), for: UIControlEvents.touchDragInside)
        activityIndicatorView.hidesWhenStopped = true
        self.addSubview(activityIndicatorView)
    }
    func shrinkButton() {
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: UIViewAnimationOptions.allowUserInteraction,
            animations: {
                self.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
            },
            completion: { Void in()  }
        )
        
    }
    func enlargeButton(speed: Double) {
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = CGAffineTransform.identity
        })
    }
    func buttonTouchUpInside(sender: UIButton) {
        self.enlargeButton(speed: 0.2)
    }
    func buttonTouchCancel(sender: UIButton) {
        self.enlargeButton(speed: 0.0)
    }
    func buttonTouchUpOutside(sender: UIButton) {
        self.enlargeButton(speed: 0.3)
    }
    func buttonTouchDragOutside(sender: UIButton) {
        self.enlargeButton(speed: 0.3)
    }
    func buttonTouchDragInside(sender: UIButton) {
        self.shrinkButton()
    }
    func buttonTouchDown(sender: UIButton) {
        self.shrinkButton()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        // Creates semicircle endcap effect
        if roundedSquare == false {
            self.layer.cornerRadius = self.frame.size.height / 2.0
        } else {
            self.layer.cornerRadius = 6
        }
        self.activityIndicatorView.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    }
}
