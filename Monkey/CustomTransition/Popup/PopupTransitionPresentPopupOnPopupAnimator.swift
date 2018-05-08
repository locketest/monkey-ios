//
//  PopupTransitionPresentAnimator.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class PopupTransitionPresentPopupOnPopupAnimator: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
  
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Delete this, not needed.
        self.transitionContext = transitionContext
        
        // Get all variables
        let containerView = transitionContext.containerView
        let fromViewController = transitionContext.viewController(forKey: .from) as! PopupViewController
        let toViewController = transitionContext.viewController(forKey: .to) as! PopupViewController
        toViewController.beginAppearanceTransition(true, animated: true)
        fromViewController.beginAppearanceTransition(false, animated: true)
        // Set up the view heiarchy
        toViewController.loadViewIfNeeded()

        // Add the target VC onto the transitioning container view
        containerView.addSubview(toViewController.view)
   
        // Layout subviews to get initial positioning
        containerView.layoutSubviews()
        
        // hide emoji view snice it overlays
        fromViewController.emojiIconView.isHidden = true

        toViewController.contentsViewLeftConstraint.constant = containerView.frame.size.width
        containerView.layoutIfNeeded()
        
        toViewController.contentsViewLeftConstraint.constant = 0
        fromViewController.contentsViewLeftConstraint.constant = -containerView.frame.size.width
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            fromViewController.view.layoutIfNeeded()
            toViewController.view.layoutIfNeeded()
        }) { (completed) in
            toViewController.endAppearanceTransition()
            fromViewController.endAppearanceTransition()
            self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
            // Show emoji view since it's frame is equal to the emoji view below in the from View Controller
            fromViewController.emojiIconView.isHidden = false
            fromViewController.contentsViewLeftConstraint.constant = 0
        }
    }
}
