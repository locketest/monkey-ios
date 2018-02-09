//
//  SwipeableViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/8/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class SwipeableViewController: MonkeyViewController, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .custom
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.modalPresentationStyle = .custom
    }
    
    var swipableViewControllerToPresentOnLeft: SwipeableViewController?
    var swipableViewControllerToPresentOnRight: SwipeableViewController?
    var swipableViewControllerToPresentOnBottom: SwipeableViewController?
    var swipableViewControllerToPresentOnTop: SwipeableViewController?
    
    // Default value is 10 to keep the arrow in the correct position while animating
    var contentHeight:CGFloat {
        return 10
    }
    
    // Logic is different if we are vertically rather than horizontally
    var isPanningHorizontally:Bool {
        return self.panningTowardsSide != .bottom && self.panningTowardsSide != .top
    }
    
    var isSwipingEnabled = true {
        didSet {
            self.panGestureRecognizer.isEnabled = isSwipingEnabled
            if !isSwipingEnabled {
                self.interactor.cancel()
            }
        }
    }
    private(set) var isSwiping = false {
        didSet {
            if oldValue != self.isSwiping {
                self.isSwipingDidChange()
            }
        }
    }
    private weak var currentViewController: SwipeableViewController?
    var panGestureRecognizer: UIPanGestureRecognizer!
    private var interactor = SwipeableInteractiveTransition()
    
    var panningTowardsSide: RelativeDirection? {
        didSet {
            guard oldValue != panningTowardsSide else {
                return // Don't present when the value doesn't change.
            }
            guard let newValue = self.panningTowardsSide else {
                return // Do nothing if panning is dead center.
            }
            
            switch newValue {
            case .left:
                if let newVC = self.currentViewController!.swipableViewControllerToPresentOnRight {
                    guard self.presentedViewController == nil else {
                        return // don't present view controller onto the stack when its already presented
                    }
                    self.present(newVC, animated: true, completion: nil)
                } else if (self.presentingViewController as? SwipeableViewController)?.swipableViewControllerToPresentOnLeft == self {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    return // Overscrolling
                }
            case .right:
                if let newVC = self.currentViewController!.swipableViewControllerToPresentOnLeft {
                    guard self.presentedViewController == nil else {
                        return // don't present view controller onto the stack when its already presented
                    }
                    self.present(newVC, animated: true, completion: nil)
                } else if (self.presentingViewController as? SwipeableViewController)?.swipableViewControllerToPresentOnRight == self {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    return // Overscrolling
                }
            case .bottom:
                if let newVC = self.currentViewController!.swipableViewControllerToPresentOnBottom {
                    guard self.presentedViewController == nil else {
                        return // don't present view controller onto the stack when its already presented
                    }
                    self.present(newVC, animated: true, completion: nil)
                } else if (self.presentingViewController as? SwipeableViewController)?.swipableViewControllerToPresentOnBottom == self {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    return // Overscrolling
                }
            case .top:
                if let newVC = self.currentViewController!.swipableViewControllerToPresentOnTop {
                    guard self.presentedViewController == nil else {
                        return // don't present view controller onto the stack when its already presented
                    }
                    self.present(newVC, animated: true, completion: nil)
                } else if (self.presentingViewController as? SwipeableViewController)?.swipableViewControllerToPresentOnBottom == self {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    return // Overscrolling
                }
                break
            }
        }
    }
    
    
    /**
     Override to receive updates when the value of `isSwiping` changes.
     
     The default implementation does nothing.
     */
    func isSwipingDidChange() {}
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        self.currentViewController = self
        self.transitioningDelegate = self
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(panGestureRecognizer:)))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    internal func handlePanGesture(panGestureRecognizer: UIPanGestureRecognizer) {
        let velocity = panGestureRecognizer.velocity(in: self.view)
        let translation = panGestureRecognizer.translation(in: self.view)
        let panningTowardsSide: RelativeDirection? = {
            if abs(translation.x) < abs(translation.y) {
                if translation.y > 0 {
                    return .top
                }
                else {
                    return .bottom
                }
            } else if translation.x < 0 {
                return .left
            } else if translation.x > 0 {
                return .right
            }
            return nil
        }()
        
        if panningTowardsSide != self.panningTowardsSide && self.panningTowardsSide != nil {
            self.interactor.finish()
            self.interactor.hasStarted = false
        }
        
        
        switch panGestureRecognizer.state {
        case .began:
            self.interactor.hasStarted = true
            self.panningTowardsSide = panningTowardsSide
            self.isSwipingDidChange()
        case .changed:
            
            guard self.interactor.hasStarted == true else {
                return
            }
            
            var progress:CGFloat = 0
            var isOverHalfwayThere = false
            var isSwipeableVelocity:Bool = false
            var isVelocityInFinishingDirection = false
            
            if self.isPanningHorizontally {
                progress = fabs(translation.x) / self.view.frame.width
                isOverHalfwayThere = progress > 0.5
                isSwipeableVelocity = fabs(velocity.x) > 1000
                isVelocityInFinishingDirection = (panningTowardsSide == .left ? velocity.x <= 0 : velocity.x >= 0)
                
            } else {
                if panningTowardsSide == .bottom {
                    if (self.swipableViewControllerToPresentOnBottom != nil) {
                        let controller = self.swipableViewControllerToPresentOnBottom!
                        progress = fabs(translation.y / (self.view.frame.size.height - (self.view.frame.height - controller.contentHeight)))
                    }
                } else if panningTowardsSide == .top {
                    progress = fabs(translation.y) / self.contentHeight
                }
                
                // Fix snapping issue, never send > 100% progress
                progress = min(progress, 1.0)
                
                isOverHalfwayThere = progress > 0.5
                isSwipeableVelocity = fabs(velocity.y) > 1000
                isVelocityInFinishingDirection = (self.isPanningHorizontally) ? (panningTowardsSide == .left ? velocity.x <= 0 : velocity.x >= 0) : (panningTowardsSide == .bottom) ? velocity.y <= 0 : velocity.y >= 0
            }
            
            self.isSwiping = progress > 0
            self.interactor.shouldFinish = (isOverHalfwayThere || isSwipeableVelocity) && isVelocityInFinishingDirection
            self.panningTowardsSide = panningTowardsSide
            self.interactor.update(progress)
        case .cancelled, .ended:
            
            self.isSwiping = false
            self.interactor.hasStarted = false
            self.panningTowardsSide = nil
            
            if self.interactor.shouldFinish && panGestureRecognizer.state == .ended {
                self.interactor.finish()
            } else {
                self.interactor.cancel()
            }
            
            self.interactor.shouldFinish = false
        case .possible:
            print("Error: Swipeable panning gesture is possible.")
        case .failed:
            print("Error: Swipeable panning gesture failed.")
        }
        
        // dismiss if showing rating
        if let messageNotificationView = NotificationManager.shared.showingNotification {
            if messageNotificationView is RatingNotificationView {
                messageNotificationView.dismiss()
            } else {
                UIApplication.shared.keyWindow?.bringSubview(toFront: messageNotificationView)
            }
        }
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
        guard viewControllerToPresent.presentingViewController == nil else {
            print("Error: Attempted to present view controller that was already on the stack: \(viewControllerToPresent)")
            return
        }
        if let swipeableViewController = viewControllerToPresent as? SwipeableViewController {
            swipeableViewController.transitioningDelegate = self
            swipeableViewController.interactor = self.interactor
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		print("Dismissing \(self), presenting view controller: \(String(describing: self.presentingViewController))")
        if flag {
            self.transitioningDelegate = self
            if let swipeableViewController = self.presentingViewController as? SwipeableViewController {
                swipeableViewController.transitioningDelegate = self
                swipeableViewController.interactor = self.interactor
            }
        }
        super.dismiss(animated: flag, completion: completion)
    }
    // MARK: - UIViewControllerTransitioningDelegate
    internal func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is MainViewController {
            return SwipeableTransitionDismissAnimator() // Replace with slide down
        }
        return SwipeableTransitionSlideAnimator()
    }
    
    internal func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SwipeableTransitionSlideAnimator()
    }
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactor.hasStarted ? self.interactor : nil
    }
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactor.hasStarted ? self.interactor : nil
        
    }
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return true
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is SwipeableViewController {
            return SwipeablePresentationController(presentedViewController: presented, presenting: presenting)
        }
        return nil // Default
    }
}
