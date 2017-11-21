//
//  PopupTransitionDismissAnimator.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class PopupTransitionDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // Delete this, not needed.
        self.transitionContext = transitionContext
        
        // Get all variables
        let containerView = transitionContext.containerView
        let fromViewController = transitionContext.viewController(forKey: .from) as! PopupViewController
        let toViewController = transitionContext.viewController(forKey: .to)!
        toViewController.beginAppearanceTransition(true, animated: true)
        fromViewController.beginAppearanceTransition(false, animated: true)
        
        // Set up the view heiarchy
        toViewController.loadViewIfNeeded()
        
        // Add the target VC onto the transitioning container view
        containerView.addSubview(toViewController.view)
        containerView.bringSubview(toFront: fromViewController.view)
        
        // Layout subviews to get initial positioning
        containerView.layoutSubviews()
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            fromViewController.view.frame.origin.y = containerView.frame.size.height
        }) { (completed) in
            toViewController.endAppearanceTransition()
            fromViewController.endAppearanceTransition()
            self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
            UIApplication.shared.keyWindow!.addSubview(toViewController.view)
        }
    }
}
