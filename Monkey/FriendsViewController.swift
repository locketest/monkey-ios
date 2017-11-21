//
//  FriendsViewController.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//
import Amplitude_iOS
import UIKit

class FriendsViewController: SwipeableViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, FriendsViewModelDelegate {

    @IBOutlet weak var newFriendsCollectionView: UICollectionView!
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var noFriendsView: UIView!
    @IBOutlet weak var noFriendsLabel: MakeTextViewGreatAgain!
    @IBOutlet weak var noFriendsEmojiLabel: LoadingTextLabel!
    @IBOutlet weak var newFriendsView: MakeUIViewGreatAgain!
    @IBOutlet var openChatsTopConstraint: NSLayoutConstraint!
    
    let viewModel = FriendsViewModel()
    
    /// When opening notifications that route you to a specific conversation from cold launch, the code that manages the navigation executes too early, leaving user stuck on FriendsVC. This fixes that
    var callingFromViewDidLoad = false
    
    /// Deep link a conversation from APNS
    var initialConversation:String?
    var initialConversationOptions:[AnyHashable:Any]?
    
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
        
        self.newFriendsCollectionView.dataSource = self
        self.newFriendsCollectionView.delegate = self
        
        self.friendsTableView.delegate = self
        self.friendsTableView.dataSource = self
        
        self.viewModel.delegate = self
        
        self.newFriendsCollectionView.contentInset = UIEdgeInsetsMake(self.newFriendsCollectionView.contentInset.top, 14, self.newFriendsCollectionView.contentInset.bottom, 14)
        self.newFriendsCollectionView.alwaysBounceHorizontal = true
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkNotifications() {
        
        if self.viewModel.friendships != nil && self.viewModel.friendships?.count != 0 && !Achievements.shared.promptedNotifications {
            let promptNotifications = UIAlertController(title: "🔔 Get notified?", message: "Would you like to get notifications when a friend messages you?", preferredStyle: .alert)
            let notNow = UIAlertAction(title: "Not now", style: .cancel, handler: nil)
            let notifyMe = UIAlertAction(title: "Notify me", style: .default, handler: { (done) in
                
                let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
                // This is an asynchronous method to retrieve a Device Token
                // Callbacks are in AppDelegate.swift
                // Success = didRegisterForRemoteNotificationsWithDeviceToken
                // Fail = didFailToRegisterForRemoteNotificationsWithError
                UIApplication.shared.registerForRemoteNotifications()
                Achievements.shared.promptedNotifications = true
            })
            
            promptNotifications.addAction(notifyMe)
            promptNotifications.addAction(notNow)
            
            self.present(promptNotifications, animated: true)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.openChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let friendship = self.viewModel.openChats?[indexPath.row] else {
            return FriendTableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendshipCell", for: indexPath) as! FriendTableViewCell
        
        cell.configureWithFriendship(friendship)
        if (friendship.user_is_typing.value ?? false) == true {
            cell.descriptionLabel.text = "typing..."
        } else {
            cell.descriptionLabel?.text = self.viewModel.latestMessageForFriendship(friendship: friendship)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let friendship = self.viewModel.openChats?[indexPath.row] else {
            return
        }
        openChat(friendship)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
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
            self.present(instagramVC, animated: true, completion: {
                self.initialLongPressLocation = locationPoint
                self.previousLongPressLocation = locationPoint
            })
            
            self.instagramViewController = instagramVC
            Amplitude.shared.logEvent("Opened Instagram Account", withEventProperties: ["via":"friends"])
 
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
    
    func friendshipForCell(from longPressGesture:UILongPressGestureRecognizer) -> RealmFriendship? {
        let locationInView = longPressGesture.location(in: self.view)
        if locationInView.y < 146.0 { // in new friends
            let newFriendsLocation = longPressGesture.location(in: self.newFriendsCollectionView)
            guard let longPressedIndexPath =  self.newFriendsCollectionView.indexPathForItem(at: newFriendsLocation) else {
                // Long press is not in collection view
                return nil
            }
            return self.viewModel.newFriends?[longPressedIndexPath.row]
        } else {
            let friendsLocation = longPressGesture.location(in: self.friendsTableView)
            
            guard let longPressedIndexPath = self.friendsTableView.indexPathForRow(at: friendsLocation) else {
                // Long press is not in table view
                return nil
            }
            return self.viewModel.openChats?[longPressedIndexPath.row]
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.newFriends.count
    }
    
     func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let friendship = self.viewModel.newFriends?[indexPath.item] else {
            return NewFriendCollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newFriend", for: indexPath) as! NewFriendCollectionViewCell
        
        if friendship.user?.user_id != cell.userId  {
            cell.profileImage.url = friendship.user?.profile_photo_url
        }
        
        cell.userId = friendship.user?.user_id
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let friendship = self.viewModel.newFriends?[indexPath.row] else {
            return
        }
        
        openChat(friendship)
    }
    
    func openChat(_ friendship:RealmFriendship) {
        
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle.main)
        
        let chatViewController = storyboard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        chatViewController.viewModel.friendshipId = friendship.friendship_id
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
        
        // Hide new friends card if no new friends
        let numberOfNewFriends = self.viewModel.newFriends.count
        if numberOfNewFriends == 0 {
            // Hide new friends
            self.newFriendsView.isHidden = true
            self.openChatsTopConstraint?.isActive = false
        } else {
            self.newFriendsView.isHidden = false
            self.openChatsTopConstraint?.isActive = true
        }
        
        self.view.setNeedsLayout()
    }
    
    func reloadOpenChats() {
        self.reloadData()
        self.friendsTableView.reloadData()
    }
    
    func reloadNewFriends() {
        self.reloadData()
        self.newFriendsCollectionView.reloadData()
    }
    
    /// Checks if there is a conversation to push onto the stack, then opens that friendship
    func checkDeepLink() {
        guard let friendshipToPush = self.initialConversation else {
            return
        }
        
        // filter down friendships that match the friendship id
        let chatLinkPredicate = NSPredicate(format: "friendship_id == \"\(friendshipToPush)\"")
        let matchingChats = self.viewModel.friendships?.filter(chatLinkPredicate)
        
        guard let matching = matchingChats else {
            self.initialConversation = nil
            self.initialConversationOptions = nil
            return
        }
        
        if let friendship = matching.first {
            self.openChat(friendship)
        }
        
        // Ensure that deep link is not acted upon twice, we reset these values to nil
        self.initialConversation = nil
        self.initialConversationOptions = nil
    }
}

