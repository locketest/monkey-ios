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
    
    /// When opening notifications that route you to a specific conversation from cold launch, the code that manages the navigation executes too early, leaving user stuck on FriendsVC. This fixes that
    var callingFromViewDidLoad = false
    
    /// Deep link a conversation from APNS
    var initialConversation: String?
    var initialConversationOptions: [AnyHashable: Any]?
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    /// A reference to the presented instagramVC. Currently used to forward longPressGestureRecognizer updates
    weak var instagramViewController: InstagramPopupViewController?
    
    /// The location of the user's finger when instagram popup is presented, used to calculate displacement to pass to instagramVC if they do not lift finger to pan
    var initialLongPressLocation: CGPoint?
    /// The previous location of the user's finger, used to calculate velocity to pass to instagramVC if they do not lift finger to pan
    var previousLongPressLocation: CGPoint?
    
    override func viewDidLoad() {        
        super.viewDidLoad()
        
        self.panGestureRecognizer.delegate = self
        self.panGestureRecognizer.cancelsTouchesInView = false
        
        self.friendsTableView.delegate = self
        self.friendsTableView.dataSource = self
		self.friendsTableView.rowHeight = 64
        
        self.viewModel.delegate = self
        
        self.noFriendsEmojiLabel.setTicks(bait: "😟", animal: "😢")
        
        // Pad bottom of friends tableview so it doesnt line up with edge
        var contentInset = self.friendsTableView.contentInset
        contentInset.bottom = 10
        self.friendsTableView.contentInset = contentInset
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        self.view.addGestureRecognizer(longPressGesture)
        self.longPressGestureRecognizer = longPressGesture
        
        self.callingFromViewDidLoad = true
        self.reloadData()
        self.callingFromViewDidLoad = false
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // false so that swiping to side during longPress does not try to dismiss friendsVC (to go to mainVC) while instagramVC is presented
        if gestureRecognizer == self.panGestureRecognizer && gestureRecognizer != self.longPressGestureRecognizer  {
            return false
        }
        
        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let mainVC = self.presentingViewController as? MainViewController {
            IncomingCallManager.shared.delegate = mainVC
        }
        
        // Do not allow user to return to chat they just swiped away from
        self.swipableViewControllerToPresentOnLeft = nil
        self.checkDeepLink()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
		
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
                if friendship.user_is_typing.value == true {
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
		
		var isMonkeyKing = friendship.user?.user_id == "2"
		chatViewController.isMonkeyKingBool = isMonkeyKing
		if isMonkeyKing {
			let isAccountNew = APIController.userDef.bool(forKey: APIController.kNewAccountCodeVerify)
			AnalyticsCenter.log(withEvent: .monkeyKingEnter, andParameter: [
				"type": isAccountNew ? "new" : "old",
				])
		}
        
        if let chatId = self.initialConversationOptions?["chat_id"] as? String {
            chatViewController.acceptChat(chatId: chatId)
        }
        self.swipableViewControllerToPresentOnLeft = chatViewController
        self.present(chatViewController, animated: true)
    }
    
    func reloadData() {
        if !self.callingFromViewDidLoad {
            self.checkDeepLink()
        }
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
    
    /// Checks if there is a conversation to push onto the stack, then opens that friendship
    func checkDeepLink() {
        guard let friendshipToPush = self.initialConversation else {
            return
        }
        
        // filter down friendships that match the friendship id
        let chatLinkPredicate = NSPredicate(format: "friendship_id == \"\(friendshipToPush)\"")
        let matchingChats = self.viewModel.friendships?.filter(chatLinkPredicate)
        
        guard let initialFriendship = matchingChats?.first else {
            self.initialConversation = nil
            self.initialConversationOptions = nil
            return
        }
		
        self.openChat(initialFriendship)
        // Ensure that deep link is not acted upon twice, we reset these values to nil
        self.initialConversation = nil
        self.initialConversationOptions = nil
    }
}

