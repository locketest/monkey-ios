//
//  DismissPopupTransitionAnimator.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/31/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class DismissPopupTransitionAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {
    var hasStarted = false
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // Get all variables
        let containerView = transitionContext.containerView
        guard let toViewController = transitionContext.viewController(forKey: .to) else {
            print("Error: Attempting to use DismissPopupTransitionAnimator to dismiss a VC that doesn't exist")
            return
        }
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? InstagramPopupViewController else {
            print("Error: Attempting to use DismissPopupTransitionAnimator from a VC that is not an InstagramPopupViewController")
            return
        }
        
        fromViewController.backgroundView.backgroundColor = UIColor(white: 0, alpha: 0) // make it transparent
        // Our animated black view in the background
        let blackView = UIView(frame: containerView.bounds)
        blackView.backgroundColor = .black
        blackView.alpha = 0.5
        containerView.insertSubview(blackView, at: 0)
        
        // Layout subviews to get initial positioning
        containerView.layoutSubviews()
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            fromViewController.view.frame.origin.y = toViewController.view.frame.size.height
            blackView.alpha = 0
        }) { (completed) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            if transitionContext.transitionWasCancelled {
                fromViewController.backgroundView.backgroundColor = Colors.black(0.5)
            } else {
                fromViewController.responderAfterDismissal?.becomeFirstResponder()
            }
            
            // this order is intentional to allow for keyboard to become active when dismissing instagram popup on chatVC, but not when transition is cancelled
            blackView.removeFromSuperview()
        }
    }
}
