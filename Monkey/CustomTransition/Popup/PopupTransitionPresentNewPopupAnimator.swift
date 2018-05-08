//
//  PopupTransitionPresentNewPopupAnimator.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/6/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class PopupTransitionPresentNewPopupAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // Delete this, not needed.
        self.transitionContext = transitionContext
        // Get all variables
        let containerView = transitionContext.containerView
        let toViewController = transitionContext.viewController(forKey: .to) as! PopupViewController
        let fromViewController = transitionContext.viewController(forKey: .from)!
        toViewController.beginAppearanceTransition(true, animated: true)
        fromViewController.beginAppearanceTransition(false, animated: true)
        
        // Set up the view heiarchy
        toViewController.loadViewIfNeeded()
        
        // Add the target VC onto the transitioning container view
        containerView.addSubview(toViewController.view)
        
        // Layout subviews to get initial positioning
        containerView.layoutSubviews()
        
        toViewController.view.frame.origin.y = containerView.frame.size.height

        let whiteOverscrollProtectorView = UIView(frame: toViewController.view.frame)
        whiteOverscrollProtectorView.frame.origin.y += toViewController.view.frame.size.height
        whiteOverscrollProtectorView.backgroundColor = .white
        containerView.addSubview(whiteOverscrollProtectorView)
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10.0, options: .curveEaseInOut, animations: {
            whiteOverscrollProtectorView.frame.origin.y = toViewController.view.frame.origin.y
            toViewController.view.frame.origin.y = 0
        }) { (completed) in
            toViewController.endAppearanceTransition()
            fromViewController.endAppearanceTransition()
            self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
        }
    }
}
