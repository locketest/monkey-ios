//
//  SwipeableViewController.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import Hero

protocol SwipeableViewControllerTransitionDelegate {
	func swipeableAnimatingFrom(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat)
	func swipeableAnimatingTo(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat)
}

class SwipeableViewController: MonkeyViewController, UIGestureRecognizerDelegate {
	
	// Direction of gesture to dismiss this vc
	var panningDismissSide: RelativeDirection? = nil // how to dismiss
	fileprivate var translationContentSize: CGSize {
		return self.transitionContent.frame.size
	}
	var transitionContent: UIView {
		return self.view
	}
	
	// 从左边出来的
	var swipableViewControllerPresentFromLeft: SwipeableViewController? {
		didSet {
			swipableViewControllerPresentFromLeft?.panningDismissSide = .left
		}
	}
	var swipableViewControllerPresentFromRight: SwipeableViewController? {
		didSet {
			swipableViewControllerPresentFromRight?.panningDismissSide = .right
		}
	}
	var swipableViewControllerPresentFromBottom: SwipeableViewController? {
		didSet {
			swipableViewControllerPresentFromBottom?.panningDismissSide = .bottom
		}
	}
	var swipableViewControllerPresentFromTop: SwipeableViewController? {
		didSet {
			swipableViewControllerPresentFromTop?.panningDismissSide = .top
		}
	}
	
	var isSwipingEnabled = true {
		didSet {
			self.panGestureRecognizer.isEnabled = isSwipingEnabled
		}
	}
	
	var panningTowardsSide: RelativeDirection? = nil {
		didSet {
			// 新的手势方向与老的不同
			guard oldValue != self.panningTowardsSide else {
				return // Don't present when the value doesn't change.
			}
			
			// 当前手势有方向
			guard let newValue = self.panningTowardsSide else {
				return // Do nothing if panning is dead center.
			}
			
//			guard let dismissTowards = panningDismissSide else {
//				return // Do nothing if no dismiss towards
//			}
			
			// new direction
			print(newValue)
			
			// 要么自己消失，要么展示新的 vc
			var presentedVC: SwipeableViewController? = nil
			switch newValue {
			case .left:
				presentedVC = self.swipableViewControllerPresentFromRight
			case .right:
				presentedVC = self.swipableViewControllerPresentFromLeft
			case .bottom:
				presentedVC = self.swipableViewControllerPresentFromTop
			case .top:
				presentedVC = self.swipableViewControllerPresentFromBottom
			}
			
			if let presentedVC = presentedVC {
				self.present(presentedVC, animated: true)
			}else if self.panningDismissSide == newValue {
				// 消失手势
				self.dismiss(animated: true)
			}else {
				// 无有效操作，重置手势方向
				self.panningTowardsSide = nil
			}
		}
	}
	
	private var panGestureRecognizer: UIPanGestureRecognizer!
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		self.hero.isEnabled = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.hero.isEnabled = true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(panGestureRecognizer:)))
		self.panGestureRecognizer.maximumNumberOfTouches = 1
		self.panGestureRecognizer.delegate = self
		self.view.addGestureRecognizer(panGestureRecognizer)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.isSwipingEnabled = true
		Socket.shared.isEnabled = true
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		self.isSwipingEnabled = false
	}
	
	func handlePanGesture(panGestureRecognizer: UIPanGestureRecognizer) {
		
		let translation: CGPoint = panGestureRecognizer.translation(in: self.view)
		let translationX: CGFloat = translation.x
		let translationY: CGFloat = translation.y
		let translationSize = self.translationContentSize
		let viewHeight: CGFloat = translationSize.height
		let viewWidth: CGFloat = translationSize.width
		
		var progress: CGFloat = 0
		if let currentDiretion = self.panningTowardsSide {
			switch currentDiretion {
			case .top:
				progress = -translationY / viewHeight
			case .bottom:
				progress = translationY / viewHeight
			case .left:
				progress = -translationX / viewWidth
			case .right:
				progress = translationX / viewWidth
			}
			progress = max(0, min(1, progress))
		}else {
			let initialDirection: RelativeDirection? = {
				if abs(translationX) < abs(translationY) {
					if translationY > 0.0 {
						return .bottom
					} else {
						return .top
					}
				} else if translationX < 0.0 {
					return .left
				} else if translationX > 0.0 {
					return .right
				}
				return nil
			}()
			self.panningTowardsSide = initialDirection
		}
		
		switch panGestureRecognizer.state {
		case .began:
			break
		case .changed:
			if self.panningTowardsSide != nil {
				Hero.shared.update(progress)
				
				if let toVC = Hero.shared.toViewController as? SwipeableViewController, let fromVC = Hero.shared.fromViewController as? SwipeableViewController {
					toVC.swipeableAnimatingFrom(viewController: fromVC, translation: translation, progress: progress)
					fromVC.swipeableAnimatingTo(viewController: toVC, translation: translation, progress: progress)
				}
			}
			break
		default:
			var targetProgress = progress
			let velocity = panGestureRecognizer.velocity(in: self.view)
			if let currentDiretion = self.panningTowardsSide {
				switch currentDiretion {
				case .top:
					targetProgress = progress + -velocity.y / viewHeight
				case .bottom:
					targetProgress = progress + velocity.y / viewHeight
				case .left:
					targetProgress = progress + -velocity.x / viewWidth
				case .right:
					targetProgress = progress + velocity.x / viewWidth
				}
			}
			let finished: Bool = targetProgress > 0.3
			print(finished)
			
			self.panningTowardsSide = nil
			if finished {
				Hero.shared.finish()
			} else {
				Hero.shared.cancel()
			}
		}
	}
	
	// MARK: - UIGestureRecognizerDelegate
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

extension SwipeableViewController: HeroViewControllerDelegate {
	
}

extension MainViewController {
	func heroWillStartAnimatingFrom(viewController: UIViewController) {
		if viewController is FilterViewController {
			self.colorGradientView.hero.modifiers = [.opacity(0)]
		}else {
			self.contentView.hero.modifiers = [.opacity(0)]
		}
		
		if viewController is SwipeableViewController {
			let toVC = (viewController as! SwipeableViewController)
			let toView: UIView = toVC.view
			
			let viewCenter: CGPoint = self.view.center
			let viewSize: CGSize = self.view.frame.size
			let halfWidth: CGFloat = viewSize.width / 2.0
			let widthPlusHalf: CGFloat = halfWidth * 3.0
			let halfHeight: CGFloat = viewSize.height / 2.0
			let heightPlusHalf: CGFloat = halfHeight * 3.0
			
			switch toVC.panningDismissSide! {
			case .left:
				toView.hero.modifiers = [.position(CGPoint.init(x: -halfWidth, y: viewCenter.y)), .useNoSnapshot]
			case .right:
				toView.hero.modifiers = [.position(CGPoint.init(x: widthPlusHalf, y: viewCenter.y)), .useNoSnapshot]
			case .bottom:
				toView.hero.modifiers = [.position(CGPoint.init(x: viewCenter.x, y: heightPlusHalf)), .useNoSnapshot]
			case .top:
				toView.hero.modifiers = [.position(CGPoint.init(x: viewCenter.x, y: -halfHeight)), .useNoSnapshot]
			}
		}
	}
	
	func heroWillStartAnimatingTo(viewController: UIViewController) {
		if viewController is FilterViewController {
			self.colorGradientView.hero.modifiers = [.opacity(0)]
			self.contentView.hero.modifiers = nil
		}else {
			self.colorGradientView.hero.modifiers = nil
			self.contentView.hero.modifiers = [.opacity(0)]
		}
		
		if viewController is SwipeableViewController {
			let toVC = (viewController as! SwipeableViewController)
			let originCenter: CGPoint = self.view.center
			let originSize: CGSize = self.view.frame.size
			
			if toVC == self.swipableViewControllerPresentFromRight {
				toVC.view.hero.modifiers = [.position(CGPoint.init(x: originCenter.x + originSize.width, y: originCenter.y)), .useNoSnapshot]
			}else if toVC == self.swipableViewControllerPresentFromLeft {
				toVC.view.hero.modifiers = [.position(CGPoint.init(x: originCenter.x - originSize.width, y: originCenter.y)), .useNoSnapshot]
			}else if toVC == self.swipableViewControllerPresentFromTop {
				toVC.view.hero.modifiers = [.position(CGPoint.init(x: originCenter.x, y: originCenter.y - originSize.height)), .useNoSnapshot]
			}else if toVC == self.swipableViewControllerPresentFromBottom {
				toVC.view.hero.modifiers = [.position(CGPoint.init(x: originCenter.x, y: originCenter.y + originSize.height)), .useNoSnapshot]
			}
		}
	}
}

extension MainViewController {
	override func swipeableAnimatingFrom(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat) {
		if viewController is FilterViewController {
			Hero.shared.apply(modifiers: [.opacity(progress)], to: self.colorGradientView)
		}else {
			Hero.shared.apply(modifiers: [.opacity(progress)], to: self.contentView)
		}
	}
	
	override func swipeableAnimatingTo(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat) {
		if viewController is FilterViewController {
			Hero.shared.apply(modifiers: [.opacity(1 - progress)], to: self.colorGradientView)
		}else {
			Hero.shared.apply(modifiers: [.opacity(1 - progress)], to: self.contentView)
		}
	}
}


extension FriendsViewController {
	func heroWillStartAnimatingFrom(viewController: UIViewController) {
		if let fromVC = viewController as? ChatViewController {
			let fromView: UIView = fromVC.view
			let viewCenter: CGPoint = self.view.center
			let viewSize: CGSize = self.view.frame.size
			let halfWidth: CGFloat = viewSize.width / 2.0
			let widthPlusHalf: CGFloat = halfWidth * 3.0
			
			self.view.hero.modifiers = [.position(CGPoint.init(x: widthPlusHalf, y: viewCenter.y)), .useNoSnapshot]
			fromView.hero.modifiers = [.position(CGPoint.init(x: -halfWidth, y: viewCenter.y)), .useNoSnapshot]
		}
	}
	
	func heroWillStartAnimatingTo(viewController: UIViewController) {
		if let toVC = viewController as? ChatViewController {
			let toView: UIView = toVC.view
			let originCenter: CGPoint = self.view.center
			let originSize: CGSize = self.view.frame.size
			let halfWidth: CGFloat = originSize.width / 2.0
			let widthPlusHalf: CGFloat = halfWidth * 3.0
			
			self.view.hero.modifiers = [.position(CGPoint.init(x: widthPlusHalf, y: originCenter.y)), .useNoSnapshot]
			toView.hero.modifiers = [.position(CGPoint.init(x: originCenter.x - originSize.width, y: originCenter.y)), .useNoSnapshot]
		}
	}
}

extension FriendsViewController {
	override func swipeableAnimatingFrom(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat) {
		guard viewController is ChatViewController else {
			super.swipeableAnimatingFrom(viewController: viewController, translation: translation, progress: progress)
			return
		}
		
		let originCenter = self.view.center
		let translationX: CGFloat = translation.x
		
		let viewSize: CGSize = view.frame.size
		let viewWidth: CGFloat = viewSize.width
		let halfWidth: CGFloat = viewWidth / 2.0
		
		Hero.shared.apply(modifiers: [.position(CGPoint.init(x: viewWidth + halfWidth + translationX, y: originCenter.y))], to: self.view)
	}

	override func swipeableAnimatingTo(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat) {
		guard viewController is ChatViewController else {
			super.swipeableAnimatingTo(viewController: viewController, translation: translation, progress: progress)
			return
		}

		let originCenter = self.view.center
		let translationX: CGFloat = translation.x
		
		let viewSize: CGSize = view.frame.size
		let viewWidth: CGFloat = viewSize.width
		let halfWidth: CGFloat = viewWidth / 2.0
		
		Hero.shared.apply(modifiers: [.position(CGPoint.init(x: translationX - halfWidth, y: originCenter.y))], to: self.view)
	}
}

extension SwipeableViewController: SwipeableViewControllerTransitionDelegate {
	func swipeableAnimatingFrom(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat) {
		guard let panningDismissSide = self.panningDismissSide else { return }
		// update views' position
		let originCenter = viewController.view.center
		let translationX: CGFloat = translation.x
		let translationY: CGFloat = translation.y
		
		let viewSize: CGSize = view.frame.size
		let viewHeight: CGFloat = viewSize.height
		let viewWidth: CGFloat = viewSize.width
		let translationSize: CGSize = self.translationContentSize
		let translationWidth: CGFloat = translationSize.width
		let translationHeight: CGFloat = translationSize.height
		let halfWidth: CGFloat = translationWidth / 2.0
		let halfHeight: CGFloat = translationHeight / 2.0
		
		
		switch panningDismissSide {
		case .bottom:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: originCenter.x, y: viewHeight + halfHeight + translationY))], to: self.view)
		case .top:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: originCenter.x, y: translationY - halfHeight))], to: self.view)
		case .right:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: viewWidth + halfWidth + translationX, y: originCenter.y))], to: self.view)
		case .left:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: translationX - halfWidth, y: originCenter.y))], to: self.view)
		}
	}
	
	func swipeableAnimatingTo(viewController: SwipeableViewController, translation: CGPoint, progress: CGFloat) {
		guard let panningDismissSide = self.panningDismissSide else { return }
		
		// update views' position
		let originCenter = view.center
		let translationX: CGFloat = translation.x
		let translationY: CGFloat = translation.y
		
		let viewSize: CGSize = view.frame.size
		let viewWidth: CGFloat = viewSize.width
		let viewHeight: CGFloat = viewSize.height
		let halfWidth: CGFloat = viewWidth / 2.0
		let halfHeight: CGFloat = viewHeight / 2.0
		
		switch panningDismissSide {
		case .top:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: originCenter.x, y: halfHeight + min(translationY, 0.0)))], to: self.view)
		case .bottom:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: originCenter.x, y: max(translationY, 0.0) + halfHeight))], to: self.view)
		case .left:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: halfWidth + min(translationX, 0.0), y: originCenter.y))], to: self.view)
		case .right:
			Hero.shared.apply(modifiers: [.position(CGPoint.init(x: max(translationX, 0.0) + halfWidth, y: originCenter.y))], to: self.view)
		}
	}
}

