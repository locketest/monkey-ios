//
//  PresentPopupTransitionAnimator.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/31/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class PresentPopupTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get all variables
        let containerView = transitionContext.containerView
        guard let toViewController = transitionContext.viewController(forKey: .to) as? InstagramPopupViewController else {
            print("Error: Attempting to use PresentPopupTransitionAnimator to present a view that isn't InstagramPopupViewController")
            return
        }
        guard let toView = transitionContext.view(forKey: .to) else {
            print("Error: Attempting to use PresentPopupTransitionAnimator but to view is missing.")
            return
        }
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {
            print("Error: Attempting to use PresentPopupTransitionAnimator from a presentingVC that doesn't exist.")
            return
        }
        // Our animated black view in the background
        let blackView = UIView(frame: containerView.bounds)
        blackView.backgroundColor = .black
        blackView.alpha = 0
        containerView.addSubview(blackView)
        
        // Add the target VC onto the transitioning container view
        containerView.addSubview(toView)
        
        // Layout subviews to get initial positioning
        containerView.layoutSubviews()
        
        toView.frame.origin.y = containerView.frame.size.height
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10.0, options: .curveEaseInOut, animations: {
            toView.frame = transitionContext.finalFrame(for: toViewController)
            blackView.alpha = 0.5
        }) { (completed) in
            toViewController.backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            blackView.removeFromSuperview()
        }
    }
    
}
