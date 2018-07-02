//
//  SwipeableTransitionSlideAnimator.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/5/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class SwipeableTransitionSlideAnimator: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
	/* todo:
	add relative direction property, on drag on mainvc confirm transition direction and inferred swiping direction is the same, if not, cancel transition (as opposed to randomly flying vcs)
	
	*/
	var relativeDirection:RelativeDirection?
	weak var transitionContext: UIViewControllerContextTransitioning?
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.2
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		// Delete this, not needed.
		self.transitionContext = transitionContext
		// Get all variables
		let containerView = transitionContext.containerView
		containerView.frame.origin.y = 0.0
		containerView.frame.size.height = UIApplication.shared.keyWindow!.frame.height
		let fromViewController = transitionContext.viewController(forKey: .from) as! SwipeableViewController
		let toViewController = transitionContext.viewController(forKey: .to) as! SwipeableViewController
		let toContainerView = transitionContext.view(forKey: .to)
		let fromContainerView = transitionContext.view(forKey: .from)
		
		let isPresenting = toViewController.presentingViewController == fromViewController
		let isFromMainViewController = fromViewController is MainViewController
		let isToMainViewController = toViewController is MainViewController
		
		(fromViewController as? MainViewController)?.stopFindingChats(andDisconnect: true, forReason: "is-swiping")
		if !isToMainViewController {
			toViewController.beginAppearanceTransition(true, animated: true)
		}
		if !isFromMainViewController {
			fromViewController.beginAppearanceTransition(false, animated: true)
		}
		// Set up the view heiarchy
		if isPresenting {
			containerView.addSubview(fromContainerView ?? fromViewController.view.superview!)
			containerView.addSubview(toContainerView ?? toViewController.view.superview!)
		} else {
			containerView.addSubview(toContainerView ?? toViewController.view.superview!)
			containerView.addSubview(fromContainerView ?? fromViewController.view.superview!)
		}
		let fromView = fromContainerView ?? fromViewController.view!
		let toView = toContainerView ?? toViewController.view!
		var directionalViewOffset: CGFloat = 0.0
		
		if fromViewController.swipableViewControllerToPresentOnLeft == toViewController {
			directionalViewOffset = -containerView.frame.size.width
		} else if !isPresenting && toViewController.swipableViewControllerToPresentOnLeft == fromViewController {
			directionalViewOffset = containerView.frame.size.width
		} else if fromViewController.swipableViewControllerToPresentOnRight == toViewController {
			directionalViewOffset = containerView.frame.size.width
		} else if !isPresenting && toViewController.swipableViewControllerToPresentOnRight == fromViewController {
			directionalViewOffset = -containerView.frame.size.width
		} else if fromViewController.swipableViewControllerToPresentOnBottom == toViewController {
			directionalViewOffset = toViewController.contentHeight
		} else if !isPresenting && toViewController.swipableViewControllerToPresentOnBottom == fromViewController {
			directionalViewOffset = fromViewController.contentHeight
		} else if fromViewController.swipableViewControllerToPresentOnTop == toViewController {
			directionalViewOffset = -toViewController.contentHeight
		} else if !isPresenting && toViewController.swipableViewControllerToPresentOnTop == fromViewController {
			directionalViewOffset = -fromViewController.contentHeight
		} else {
//			fatalError("Error: Unexpected view controller stack.")
//			防止 crash
			directionalViewOffset = containerView.frame.size.width
		}
		print(directionalViewOffset)
		
		if !isToMainViewController && isPresenting {
			if fromViewController.isPanningHorizontally && (toViewController is SettingsViewController) == false && (toViewController is FilterViewController) == false { // left/right (second conditional for tap to bring up settings)
				toView.frame.origin.x = directionalViewOffset
				toViewController.view.frame.origin.y = 0.0
			} else {
				toView.frame.origin.x = 0.0 // ensure we don't animate from bottom right
				toView.frame.origin.y = directionalViewOffset // settings
			}
			toViewController.view.frame.size.height = containerView.frame.height
		}
		
		// set the final offset for the arrow within this transition
		if let controller = fromViewController as? MainViewController, let toController = toViewController as? SettingsViewController {
			controller.bottomArrowPadding.constant = toController.contentHeight + 20.0
		} else if let controller = toViewController as? MainViewController {
			controller.bottomArrowPadding.constant = 30.0
		}
		
		UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
			
			if !isFromMainViewController {
				if (fromViewController.isPanningHorizontally) {
					fromView.frame.origin.x = -directionalViewOffset // left/right
				} else {
					fromView.frame.origin.y = directionalViewOffset // up/down
				}
			}
			
			if !isToMainViewController {
				toView.frame.origin.x = 0.0
				toView.frame.origin.y = 0.0
			}
			// animate alpha of loading view (including the swipe up arrow)
			(fromViewController as? MainViewController)?.elementsShouldHide = true
			(toViewController as? MainViewController)?.elementsShouldHide = false
			
			// call layoutIfNeeded(), animating the arrow's bottom constraint upwards
			if let controller = fromViewController as? MainViewController {
				controller.view.layoutIfNeeded()
			} else if let controller = toViewController as? MainViewController {
				controller.view.layoutIfNeeded()
			}
			
		}) { (completed) in
			transitionContext.completeTransition(!self.transitionContext!.transitionWasCancelled)
			if transitionContext.transitionWasCancelled {
				if let controller = toViewController as? MainViewController, fromViewController is SettingsViewController {
					controller.bottomArrowPadding.constant = fromViewController.contentHeight + 20.0
					controller.view.setNeedsLayout()
				}
				else if let controller = fromViewController as? MainViewController {
					controller.bottomArrowPadding.constant = 30.0
					controller.view.setNeedsLayout()
				}
				
				if fromContainerView == nil {
					UIApplication.shared.keyWindow!.addSubview(fromView.superview!)
				}
				if !isFromMainViewController {
					fromViewController.beginAppearanceTransition(true, animated: true)
				}
				if !isToMainViewController {
					toViewController.beginAppearanceTransition(false, animated: true)
				}
				
			} else {
				TapticFeedback.impact(style: .light)
				
				if let from = fromViewController as? MainViewController {
					from.stopFindingChats(andDisconnect: true, forReason: "is-swiped-away")
					if toViewController == fromViewController.swipableViewControllerToPresentOnRight {
						from.pageViewIndicator.currentPage = 2
					} else if toViewController == fromViewController.swipableViewControllerToPresentOnLeft {
						from.pageViewIndicator.currentPage = 0
					}
				}
				if isToMainViewController {
					let to = (toViewController as! MainViewController)
					to.startFindingChats(forReason: "is-swiped-away")
					to.pageViewIndicator.currentPage = 1
				}
				
				if toContainerView == nil {
					UIApplication.shared.keyWindow!.addSubview(toView.superview!)
				}
			}
			if !isToMainViewController {
				toViewController.endAppearanceTransition()
			}
			if !isFromMainViewController {
				fromViewController.endAppearanceTransition()
			}
			
			(fromViewController as? MainViewController)?.startFindingChats(forReason: "is-swiping")
		}
	}
}

