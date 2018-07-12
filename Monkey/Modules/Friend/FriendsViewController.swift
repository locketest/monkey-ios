//
//  FriendsViewController.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//
import UIKit

class FriendsViewController: SwipeableViewController, UITableViewDelegate, UITableViewDataSource, FriendsViewModelDelegate {

    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var noFriendsView: UIView!
    @IBOutlet weak var noFriendsLabel: MakeTextViewGreatAgain!
    @IBOutlet weak var noFriendsEmojiLabel: LoadingTextLabel!
    
    let viewModel = FriendsViewModel.sharedFreindsViewModel
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    /// A reference to the presented instagramVC. Currently used to forward longPressGestureRecognizer updates
    weak var instagramViewController: InstagramPopupViewController?
    
    /// The location of the user's finger when instagram popup is presented, used to calculate displacement to pass to instagramVC if they do not lift finger to pan
    var initialLongPressLocation: CGPoint?
    /// The previous location of the user's finger, used to calculate velocity to pass to instagramVC if they do not lift finger to pan
    var previousLongPressLocation: CGPoint?
    
    override func viewDidLoad() {        
        super.viewDidLoad()
		
        self.friendsTableView.delegate = self
        self.friendsTableView.dataSource = self
		self.friendsTableView.rowHeight = 64.0
        
        self.viewModel.delegate = self
        
        self.noFriendsEmojiLabel.setTicks(bait: "😟", animal: "😢")
        
        // Pad bottom of friends tableview so it doesnt line up with edge
        var contentInset = self.friendsTableView.contentInset
        contentInset.bottom = 10.0
        self.friendsTableView.contentInset = contentInset
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        self.view.addGestureRecognizer(longPressGesture)
        self.longPressGestureRecognizer = longPressGesture
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.swipableViewControllerPresentFromLeft = nil
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.friendships.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let openChats = self.viewModel.friendships, openChats.count > indexPath.row else {
            return FriendTableViewCell()
        }
        
        let friendship = openChats[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendshipCell", for: indexPath) as! FriendTableViewCell
        
        cell.configureWithFriendship(friendship)
        
        if let user = friendship.user {
            if user.isMonkeyKing() == false {
                if friendship.user_is_typing == true {
                    cell.descriptionLabel.text = "typing..."
                } else {
                    cell.descriptionLabel?.text = self.viewModel.latestMessageForFriendship(friendship: friendship)
                }
            } else {
                cell.descriptionLabel.text = ""
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let friendship = self.viewModel.friendships?[indexPath.row] else {
            return
        }
        openChat(friendship)
    }
    
    /**
     Request an alert presentation with friendship otions via the delegate after long pressing on a cell.
     */
    internal func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        let locationPoint = longPressGestureRecognizer.location(in: self.friendsTableView)
        
        switch longPressGestureRecognizer.state {
        case .began:
            guard let friendship = self.friendshipForCell(from: longPressGestureRecognizer) else {
                // long press was not on a cell or collection item
                return
            }

            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil
            
            guard let instagramVC = UIStoryboard(name: "Instagram", bundle: nil).instantiateInitialViewController() as? InstagramPopupViewController else {
                return
            }
            instagramVC.friendshipId = friendship.friendship_id
            instagramVC.userId = friendship.user?.user_id
            instagramVC.isMonkeyKingBool = friendship.user?.isMonkeyKing() ?? false
			
			AnalyticsCenter.log(withEvent: .insgramClick, andParameter: [
				"entrance": "friend list",
				])
            
            self.present(instagramVC, animated: true, completion: {
                self.initialLongPressLocation = locationPoint
                self.previousLongPressLocation = locationPoint
            })
            
            self.instagramViewController = instagramVC
 
        case .changed:
            guard let instagramVC = self.instagramViewController else {
                print("Error: can not forward touches to instagramVC since reference is invalid")
                return
            }
            guard let initialLocation = self.initialLongPressLocation else {
                print("Error: can not calculate displacement since no initialLongPressLocation")
                return
            }
            guard let previousLocation = self.previousLongPressLocation else {
                print("Error: can not caluclate velocity since no previousLongPressLocation")
                return
            }
            
            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y
            
            instagramVC.adjustInstagramConstraints(displacement, velocity)
            
            self.previousLongPressLocation = locationPoint
        case .cancelled, .ended:
            guard let instagramVC = self.instagramViewController else {
                print("Error: can not forward touches to instagramVC since reference is invalid (.ended)")
                return
            }
            guard let initialLocation = self.initialLongPressLocation else {
                print("Error: can not calculate displacement since no initialLongPressLocation (.ended)")
                return
            }
            guard let previousLocation = self.previousLongPressLocation else {
                print("Error: can not caluclate velocity since no previousLongPressLocation (.ended)")
                return
            }
            let displacement = locationPoint.y - initialLocation.y
            let velocity = locationPoint.y - previousLocation.y
            
            instagramVC.adjustInstagramConstraints(displacement, velocity, isEnding: true)
            
            self.initialLongPressLocation = nil
            self.previousLongPressLocation = nil
            self.instagramViewController = nil // no longer need a reference to it
        default:
            break
        }
    }
	
	override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		
		if (gestureRecognizer == self.friendsTableView.panGestureRecognizer || otherGestureRecognizer == self.friendsTableView.panGestureRecognizer) {
			return false
		}
		
		return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
	}
    
    func friendshipForCell(from longPressGesture: UILongPressGestureRecognizer) -> RealmFriendship? {
		let friendsLocation = longPressGesture.location(in: self.friendsTableView)
		
		guard let longPressedIndexPath = self.friendsTableView.indexPathForRow(at: friendsLocation) else {
			// Long press is not in table view
			return nil
		}
		return self.viewModel.friendships?[longPressedIndexPath.row]
	}
    
    func openChat(_ friendship: RealmFriendship) {
		
		AnalyticsCenter.log(event: .friendListClick)
		
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle.main)
        let chatViewController = storyboard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        chatViewController.viewModel.friendshipId = friendship.friendship_id
		self.swipableViewControllerPresentFromLeft = chatViewController
		
		let isMonkeyKing = friendship.user?.isMonkeyKing() ?? false
		chatViewController.isMonkeyKingBool = isMonkeyKing
		if isMonkeyKing {
			let isAccountNew = UserManager.shared.loginMethod == .register
			AnalyticsCenter.log(withEvent: .monkeyKingEnter, andParameter: [
				"type": isAccountNew ? "new" : "old",
				])
		}
		
        self.present(chatViewController, animated: true)
    }
    
    func reloadData() {
        // Show no friends view if has friends
        let numberOfFriends = self.viewModel.friendships.count
        if numberOfFriends == 0 {
            self.noFriendsView.isHidden = false
        } else {
            self.noFriendsView.isHidden = true
        }
        
        self.view.setNeedsLayout()
    }
    
    func reloadFriendships() {
        self.reloadData()
        self.friendsTableView.reloadData()
    }
}

