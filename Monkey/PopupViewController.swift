//
//  MonkeyPopupViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

@IBDesignable class PopupViewController: UIViewController, UIViewControllerTransitioningDelegate {
    var contentsView: UIView!
    var contentsViewLeftConstraint: NSLayoutConstraint!
    let emojiIconView = MakeUIViewGreatAgain()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func loadView() {
        super.loadView()
        
        contentsView = self.view // Keep refrence to old view.
        contentsView.translatesAutoresizingMaskIntoConstraints = false
        self.view = UIView(frame: UIScreen.main.bounds)
        
        // Masked view with one subview that contains actual custom view controller contents
        let containerView = UIView()
        contentsView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        // Add the container view (which will have the corners mask) the the view
        self.view.addSubview(containerView)
        containerView.addSubview(contentsView)

        contentsView.backgroundColor = .white
        containerView.clipsToBounds = true

        self.view.backgroundColor = .clear
        
        emojiIconView.translatesAutoresizingMaskIntoConstraints = false // Constraints added manually below
        emojiIconView.cornerRadius = 30 // Circle
        emojiIconView.backgroundColor = .white
        let monkeyIconLabel = UILabel(frame: CGRect(x: 10, y: 1, width: 60, height: 60))
        monkeyIconLabel.translatesAutoresizingMaskIntoConstraints = false // Constraints added manually below
        monkeyIconLabel.numberOfLines = 2
        monkeyIconLabel.text = "🙊"
        monkeyIconLabel.textAlignment = .center
        monkeyIconLabel.font = UIFont(name: "AppleColorEmoji", size: 40)
        emojiIconView.addSubview(monkeyIconLabel)
        
        self.view.addSubview(emojiIconView)
        
        // Position the Contents Container View
        self.view.addConstraints([
            // Top 60px from top of main view
            NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 60.0),
            // Pin left to side of main view
            NSLayoutConstraint(item: containerView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0.0),
            // Equal width to main view
            NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0.0),
            // Pin bottom to bottom of main view
            NSLayoutConstraint(item: containerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            ])
        // Position the Contents View
        contentsViewLeftConstraint = NSLayoutConstraint(item: contentsView, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1.0, constant: 0.0)
        containerView.addConstraints([
            // Pin top to top of container view
            NSLayoutConstraint(item: contentsView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1.0, constant: 0.0),
            // Pin left to side of container view
            contentsViewLeftConstraint,
            // Equal width to container view
            NSLayoutConstraint(item: contentsView, attribute: .width, relatedBy: .equal, toItem: containerView, attribute: .width, multiplier: 1.0, constant: 0.0),
            // Pin bottom to bottom of container view
            NSLayoutConstraint(item: contentsView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            ])

        // Position Emoji Icon View
        self.view.addConstraints([
            // Center X with the Container View
            NSLayoutConstraint(item: emojiIconView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            // Center Y to top of the Container View
            NSLayoutConstraint(item: emojiIconView, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1.0, constant: 0.0),
            // Height 60
            NSLayoutConstraint(item: emojiIconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60.0),
            // Width 60
            NSLayoutConstraint(item: emojiIconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60.0),
            ])
        // Position the Emoji Label within the Emoji Icon View
        emojiIconView.addConstraints([
            // Height 60
            NSLayoutConstraint(item: monkeyIconLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60.0),
            // Width 60
            NSLayoutConstraint(item: monkeyIconLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60.0),
            // Top 4px margin
            NSLayoutConstraint(item: monkeyIconLabel, attribute: .top, relatedBy: .equal, toItem: emojiIconView, attribute: .top, multiplier: 1.0, constant: 0.0),
            // Center X
            NSLayoutConstraint(item: monkeyIconLabel, attribute: .centerX, relatedBy: .equal, toItem: emojiIconView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            ])
        // Round top left and top right corners of the Container View
        let roundedCornersLayer = CAShapeLayer()
        roundedCornersLayer.path = UIBezierPath(roundedRect: contentsView.frame, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath
        containerView.layer.mask = roundedCornersLayer
        
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopupTransitionDismissAnimator()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentingIsPopup = (presenting as? PopupViewController) != nil
        if presentingIsPopup {
            return PopupTransitionPresentPopupOnPopupAnimator()
        } else {
            return PopupTransitionPresentNewPopupAnimator()
        }
    }
}
