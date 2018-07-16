//
//  DashboardMainViewController.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  Dashboard主页

import UIKit
import SwiftyJSON
import Hero

enum SortWeight : Double {
	case online = 1000
	case paired = 100
	case missed = 10
	case others = 1
}

enum SocketDefaultMsgTypeEnum : Int {
	case unlock2p = 0
	case newFriend
	case friendInvite
	case friendPair
	case acceptFriendPair
	case operateFriendInvite // 忽略、邀请操作，通知对方更新可再次邀请状态
	case friendOnlineStatus
}

@objc protocol DashboardMainViewControllerDelegate : NSObjectProtocol {
	@objc optional func twopPreConnectingFunc()
	@objc optional func twopStartConnectingFunc(pairRequestAcceptModel:PairRequestAcceptModel)
	@objc optional func twopTimeoutConnectingFunc()
}

class DashboardMainViewController: MonkeyViewController {
	
	var timer : Timer?
	
	var pairTimer : Timer?
	
	var currentInt = 1
	
	var layoutTagInt = 0

	let FootView = UIView()
	
	var pairTimerTuple = (init:10, current:10)
	
	var requestFinishCountInt = 0
	
	// 是否是通过手势关闭的键盘标识
	var isTapEndEditingBool = false
	
	var someoneCircle : CAShapeLayer!
	
	var tempCell: DashboardFriendsListCell?
	
	var tempModel : DashboardFriendsListModel?
	
	var invitingAnimLayer : InvitingProgressLayer!
	
	var dataArray : [AnyObject] = [] // 总数据集合
	
	var searchArray : [AnyObject] = [] // search集合
	
	var delegate : DashboardMainViewControllerDelegate?
	
	var pairRequestAcceptModel : PairRequestAcceptModel?
	
	var twopChatFriendArray : [DashboardFriendsListModel] = []
	
	var inviteFriendArray : [DashboardInviteListModel] = []
	
	let InitialTopConstraintTuple = (myTeam: 64, friends: 209)
	
	let SectionTitleArray = ["2P CHAT FRIEND LIST", "INVITE FRIENDS TO UNLOCK 2P CHAT"]
	
	@IBOutlet weak var friendsBottomConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var friendsTopConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var myTeamTopConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var twoPersonButton: BigYellowButton! // 2p按钮
	
	@IBOutlet weak var redDotLabel: UILabel! // 红点数量提示
	
	@IBOutlet weak var noAccessContactsBgView: UIView!
	
	@IBOutlet weak var searchTextField: UITextField!
	
	@IBOutlet weak var meAndSomeoneBgView: UIView!
	
	@IBOutlet weak var someoneImageView: UIImageView!
	
	@IBOutlet weak var userNotFoundLabel: UILabel!
	
	@IBOutlet weak var meImageView: UIImageView!
	
	@IBOutlet weak var weAreTeamLabel: UILabel!
	
	@IBOutlet weak var endEditButton: UIButton!
	
	@IBOutlet weak var someoneLabel: UILabel!
	
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		print("*** authorization = \(APIController.authorization), id = \(APIController.shared.currentUser?.user_id)")

        self.initView()
		
		self.initData()
    }
	
	@IBAction func tapGestureClickFunc(_ sender: UITapGestureRecognizer) {
		self.isTapEndEditingBool = true
		self.view.endEditing(true)
	}
	
	@IBAction func endEditingBtnClickFunc(_ sender: UIButton) {
		
		if self.isTapEndEditingBool { // 点击空白处关闭键盘时再点end按钮不会触发键盘关闭事件，但是还是需要调整view的位置，Q1
			self.endEditButton.isHidden = true
			self.showStatusBarFunc(isHidden: false)
			self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
			self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
		}
		
		self.userNotFoundLabel.isHidden = true
		self.isTapEndEditingBool = false
		self.searchTextField.text = ""
		self.view.endEditing(true)
		
		self.searchArray.removeAll()
		self.searchArray = self.dataArray
		self.tableView.reloadData()
	}
	
	@IBAction func inviteBtnClickFunc(_ sender: BigYellowButton) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "InviteFriendsViewController") as! InviteFriendsViewController
		self.present(vc, animated: true, completion: nil)
	}
	
	@IBAction func searchTextFieldEditingChanged(_ sender: UITextField) {
		
		if !sender.text!.isEmpty && Tools.trimSpace(string: sender.text!).count == 0 {
			sender.text = ""
			return
		}
		
		if sender.text!.isEmpty || Tools.trimSpace(string: sender.text!).count == 0 {
			self.endEditButton.isHidden = false
			self.userNotFoundLabel.isHidden = true
			self.searchArray = self.dataArray
			self.tableView.reloadData()
		} else {
			if !self.endEditButton.isHidden {
				self.endEditButton.isHidden = true
			}
			
			if sender.markedTextRange == nil {
				self.handleSearchContactsFunc(sender: sender)
			}
		}
	}
	
	func handleSearchContactsFunc(sender:UITextField) {
		print("*** sender = \(sender.text!)")
		
		self.searchArray.removeAll()
		self.twopChatFriendArray.removeAll()
		self.inviteFriendArray.removeAll()
		
		if self.dataArray.isEmpty { return }
		
		(self.dataArray[0] as! [DashboardFriendsListModel]).forEach { (friendsListModel) in
			if friendsListModel.nameString != nil {
				if friendsListModel.nameString!.contains(sender.text!) {
					self.twopChatFriendArray.append(friendsListModel)
				}
			}
		}
		
		if self.dataArray.count == 2 {
			(self.dataArray[1] as! [DashboardInviteListModel]).forEach { (inviteListModel) in
				if inviteListModel.nameString!.contains(sender.text!) {
					self.inviteFriendArray.append(inviteListModel)
				}
			}
		}
		
		let userIdInt = self.twopChatFriendArray.first?.userIdInt
		
		if self.twopChatFriendArray.count > 0 && userIdInt != nil {
			self.searchArray.append(self.twopChatFriendArray as AnyObject)
		}
		
		if self.inviteFriendArray.count > 0 {
			self.searchArray.append(self.inviteFriendArray as AnyObject)
		}
		
		if self.searchArray.count == 0 {
			self.userNotFoundLabel.isHidden = false
		} else {
			self.userNotFoundLabel.isHidden = true
		}
		
		self.tableView.reloadData()
	}
	
	func changeImageFunc() {

		self.someoneImageView.image = UIImage(named: "monkeyAnimation\(currentInt)")
		
		if self.currentInt >= 3 {
			self.currentInt = 1
		} else {
			self.currentInt += 1
		}
	}
	
	func stopTimerFunc() {
		self.someoneImageView.image = UIImage(named: "monkeyDef")
		self.timer?.invalidate()
		self.timer = nil
	}
	
	func addTimerFunc() {
		self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(changeImageFunc), userInfo: nil, repeats: true)
		RunLoop.current.add(self.timer!, forMode: .commonModes)
	}
	
	func stopPairTimerFunc() {
		self.pairTimerTuple.current = self.pairTimerTuple.init
		self.pairTimer?.invalidate()
		self.pairTimer = nil
	}
	
	func addPairTimerFunc() {
		self.pairTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(pairConnectingFunc), userInfo: nil, repeats: true)
		RunLoop.current.add(self.pairTimer!, forMode: .commonModes)
	}
	
	func addSomeoneCircleFunc() {
		self.meAndSomeoneBgView.layer.addSublayer(self.someoneCircle)
	}
	
	func removeSomeoneCircleFunc() {
		self.someoneCircle.removeFromSuperlayer()
	}
	
	func startWaittingFunc() {
		self.addTimerFunc()
		self.removeSomeoneCircleFunc()
		self.invitingAnimLayer.startAniamtion()
		
		self.someoneLabel.text = "Waitting"
		self.someoneLabel.textColor = UIColor.yellow
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 30) {
			self.stopWaittingFunc()
		}
	}
	
	func stopWaittingFunc() {
		self.stopTimerFunc()
		self.addSomeoneCircleFunc()
		self.invitingAnimLayer.stopAnimation()
		
		self.someoneLabel.text = "2P Chat Buddy"
		self.someoneLabel.textColor = UIColor.lightGray
	}
	
	func initInvitingLayerFunc() {
		
		self.invitingAnimLayer = InvitingProgressLayer(layer: self.someoneImageView.layer)
		
		self.invitingAnimLayer.frame = CGRect(x: 0, y: 0, width: self.someoneImageView.width + 5, height: self.someoneImageView.height + 5)
		
		self.invitingAnimLayer.position = CGPoint(x: self.someoneImageView.width / 2, y: self.someoneImageView.height / 2)
	}
	
	func showStatusBarFunc(isHidden:Bool) {
		
		UIApplication.shared.isStatusBarHidden = isHidden
		
		if isHidden {
			self.mainViewController?.beginTwopSearchProcess()
		} else {
			self.mainViewController?.endTwopSearchProcess()
		}
	}
	
	func initCircleFunc() {
		
		if let currentUser = APIController.shared.currentUser {
			self.meImageView.kf.setImage(with: URL(string: currentUser.profile_photo_url ?? ""), placeholder: UIImage(named: currentUser.defaultAvatar)!)
		}
	}
	
	func handleRequestFinishedFunc(userInfoArray:[UsersInfoModel], pairListArray:[PairListModel], friendRequestArray:[FriendsRequestModel]) {
		
		if self.requestFinishCountInt != 3 { return }
		
//		print("*** friendRequestArray = \(friendRequestArray.count)")
//		print("*** userInfoArray = \(userInfoArray.count)")
//		print("*** pairListArray = \(pairListArray.count)")
		
		var pairListArrayMap : [String:PairListModel] = [:]
		
		var friendsRequestModelMap : [String:FriendsRequestModel] = [:]
		
		_ = pairListArray.compactMap {
			pairListArrayMap[$0.userIdInt!.description] = $0
		}
		
		_ = friendRequestArray.compactMap {
			friendsRequestModelMap[$0.userIdInt!.description] = $0
		}
		
		let userIdString = UserManager.shared.currentUser!.user_id
		
		userInfoArray.forEach({ (userInfo) in
			
			if let unlock2pBool = userInfo.unlock2pBool {
				
				if unlock2pBool {
					
					var pairListModel : PairListModel?
					
					if let pairModel = pairListArrayMap[userInfo.userIdInt!.description] {
						// pair里的userId或者inviteeIdInt等于userInfo的userId说明就是相互pair的数据
						if userInfo.userIdInt == pairModel.userIdInt || userInfo.userIdInt == pairModel.inviteeIdInt {
							pairListModel = pairModel
						}
					}
					
					self.twopChatFriendArray.append(DashboardFriendsListModel.dashboardFriendsListModel(userInfo: userInfo, pairListModel: pairListModel))
					
				} else {
					
					var friendsRequestModel : FriendsRequestModel?
					
					if let friendModel = friendsRequestModelMap[userInfo.userIdInt!.description] {
						// 2p好友列表里的userId等于当前用户的id就说明是用户主动发起的邀请
						if userIdString == friendModel.userIdInt?.description {
							friendsRequestModel = friendModel
						}
					}
					
					self.inviteFriendArray.append(DashboardInviteListModel.dashboardInviteListModel(userInfo: userInfo, friendsRequestModel: friendsRequestModel))
				}
			}
		})
		
		self.twopChatFriendArray = self.twopChatFriendArray.sorted { $0.weightDouble > $1.weightDouble }
		
		self.twopChatFriendArray.forEach { (model) in
//			print("*** model = \(model.userIdInt!)")
		}
		
		// 如果没有2p好友，加一个空的模型在数据源里，用以显示第一组的无数据cell
		if self.twopChatFriendArray.isEmpty { self.twopChatFriendArray.append(DashboardFriendsListModel()) }

		self.dataArray.append(self.twopChatFriendArray as AnyObject)
		
		if self.inviteFriendArray.count > 0 { self.dataArray.append(self.inviteFriendArray as AnyObject) }
		
		if !(self.twopChatFriendArray[0].userIdInt == nil && self.inviteFriendArray.count == 0) {
			self.searchArray = self.dataArray
		}
		
		self.tableView.reloadData()
	}
	
	func loadPairAndUserInfoFunc(models:[FriendshipModel]) {
		
		print("*** = \(APIController.authorization!)")
		
		var friendRequestArray : [FriendsRequestModel] = []
		
		var userInfoArray : [UsersInfoModel] = []
		
		var pairListArray : [PairListModel] = []
		
		let friendIdString = models.map { $0.friendIdString! }.joined(separator: ",")
		
		// 拿到所有好友的userInfo
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/users?ids=\(friendIdString)", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument userInfo = \(JSON(jsonAPIDocument.json["data"] as! [[String: AnyObject]]))")
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						array.forEach({ (userInfo) in
							userInfoArray.append(UsersInfoModel.usersInfoModel(dict: userInfo))
						})
						
						self.requestFinishCountInt += 1
						self.handleRequestFinishedFunc(userInfoArray: userInfoArray, pairListArray: pairListArray, friendRequestArray: friendRequestArray)
					}
				}
		}
		
		// 配对列表
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2ppairs/", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument 2ppairs = \(JSON(jsonAPIDocument.json["data"] as! [[String: AnyObject]]))")
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						array.forEach({ (pairInfo) in
							pairListArray.append(PairListModel.pairListModel(dict: pairInfo))
						})
						
						self.requestFinishCountInt += 1
						self.handleRequestFinishedFunc(userInfoArray: userInfoArray, pairListArray: pairListArray, friendRequestArray: friendRequestArray)
					}
				}
		}
		
		// plan AB 里2p好友列表
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument 2pinvitations = \(JSON(jsonAPIDocument.json["data"] as! [[String: AnyObject]]))")
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						array.forEach({ (friendModel) in
							friendRequestArray.append(FriendsRequestModel.friendsRequestModel(dict: friendModel, nameString: nil, pathString: nil))
						})
						
						self.requestFinishCountInt += 1
						self.handleRequestFinishedFunc(userInfoArray: userInfoArray, pairListArray: pairListArray, friendRequestArray: friendRequestArray)
					}
				}
		}
	}
	
	func loadFriendsListFunc() {
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/friendships/", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** json friendships = \(jsonAPIDocument.json)")
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						
						if array.count > 0 {
							
							var models : [FriendshipModel] = []
							
							array.forEach({ (model) in
								
								if let userIdInt = model["friend_id"] as? Int, userIdInt != 2 { // 去除MonkeyKing
									models.append(FriendshipModel.friendshipModel(dict: model))
								}
							})
							
							guard models.count > 0 else {
								self.tableView.isHidden = true
								self.noAccessContactsBgView.isHidden = false
								return
							}
							
							self.loadPairAndUserInfoFunc(models: models)
						}
					}
				}
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if self.layoutTagInt == 1 {
			
			let MeCircleColor = UIColor(red: 217 / 255, green: 210 / 255, blue: 252 / 255, alpha: 1)
			self.meAndSomeoneBgView.layer.addSublayer(Tools.drawCircleFunc(imageView: self.meImageView, lineWidth: 1.3, strokeColor: MeCircleColor, padding: 5))
			
			self.someoneCircle = Tools.drawCircleFunc(imageView: self.someoneImageView, lineWidth: 1.3, strokeColor: MeCircleColor, padding: 5)
			
			self.addSomeoneCircleFunc()
		}
		
		self.layoutTagInt += 1
	}
	
	func initData() {
		
		self.loadFriendsListFunc()
	}
	
	func initView() {
		
		self.view.hero.modifiers = [.fade]
		
		self.initCircleFunc()
		
		self.initInvitingLayerFunc()
		
		MessageCenter.shared.addMessageObserver(observer: self)
		
		let cleanButton = self.searchTextField.value(forKey: "_clearButton") as! UIButton
		cleanButton.setImage(UIImage(named: "clearButton")!, for: .normal)
		
		self.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
		
		NotificationCenter.default.addObserver(self, selector: #selector(initCircleFunc), name: NSNotification.Name(rawValue: ProfileImageUpdateTag), object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(acceptPairNotificationFunc), name: NSNotification.Name(rawValue: AcceptPairNotificationTag), object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(friendsPairNotificationFunc), name: NSNotification.Name(rawValue: FriendPairNotificationTag), object: nil)
		
		self.weAreTeamLabel.text = "Monkey Squad assembled,\nstarting 2P Chat"
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowFunc), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideFunc), name: .UIKeyboardWillHide, object: nil)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		self.showStatusBarFunc(isHidden: false)
		
		self.stopTimerFunc()
		
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
	}
	
	deinit {
//		MessageCenter.shared.delMessageObserver(observer: self)
	}
}

/**
 notification相关
*/
extension DashboardMainViewController {
	
	func friendsPairNotificationFunc(notification:NSNotification) {
		
		let array = notification.object as! Array<Any>
		
		let twopSocketModel = array.first as! TwopSocketModel
		
		if self.handleTwoChannelMsgSendFunc(msgIdString: twopSocketModel.msgIdString) {
			self.handleFriendPairSocketMsgFunc(twopSocketModel: twopSocketModel)
		}
	}
	
	func acceptPairNotificationFunc(notification:NSNotification) {
		
		let array = notification.object as! Array<Any>
		
		let twopSocketModel = array.first as! TwopSocketModel
		print("*** = \(twopSocketModel.msgIdString!)")
		
		if self.handleTwoChannelMsgSendFunc(msgIdString: twopSocketModel.msgIdString) {
			if let friendIdInt = twopSocketModel.extDictModel?.friendIdInt {
				self.startConnectingFunc(friendIdInt: friendIdInt, twopSocketModel: twopSocketModel)
			}
		}
	}
}

/**
 socket消息相关
*/
extension DashboardMainViewController : MessageObserver {
	
	func didReceiveTwopDefault(message: [String : Any]) {
		
		print("*** message = \(JSON(message))")
		
		let twopSocketModel = TwopSocketModel.twopSocketModel(dict: message as [String : AnyObject])
		
		switch twopSocketModel.msgTypeInt {
		case SocketDefaultMsgTypeEnum.friendOnlineStatus.rawValue:
			self.updateOnlineStatusFunc(friendInt: twopSocketModel.senderIdInt!, onlineBool: twopSocketModel.extDictModel!.onlineBool!)
		case SocketDefaultMsgTypeEnum.friendPair.rawValue: // friendPair
			if self.handleTwoChannelMsgSendFunc(msgIdString: twopSocketModel.msgIdString) {
				self.handleFriendPairSocketMsgFunc(twopSocketModel: twopSocketModel)
			}
		case  SocketDefaultMsgTypeEnum.acceptFriendPair.rawValue: // acceptFriendPair
			if self.handleTwoChannelMsgSendFunc(msgIdString: twopSocketModel.msgIdString) {
				if let friendIdInt = twopSocketModel.extDictModel?.friendIdInt {
					self.startConnectingFunc(friendIdInt: friendIdInt, twopSocketModel: twopSocketModel)
				}
			}
		default:
			break
		}
	}
	
	func updateOnlineStatusFunc(friendInt: Int, onlineBool: Bool) {
		
		for (index, value) in self.twopChatFriendArray.enumerated() {
			
			if value.userIdInt == friendInt {
				
				value.onlineStatusBool = onlineBool
				
				let temp = value
				
				self.twopChatFriendArray.remove(at: index)
				self.twopChatFriendArray.insert(temp, at: 0)
			}
		}
		
		if self.twopChatFriendArray.count > 0 {
			
		}

		
		if self.dataArray.count > 0 {
			self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
		}
	}
	
	func handleFriendPairSocketMsgFunc(twopSocketModel:TwopSocketModel) {
		
		for dashboardFriendsListModel in self.twopChatFriendArray {
			print("*** = \(twopSocketModel.extDictModel?.friendIdInt), = \(dashboardFriendsListModel.userIdInt)")
			if twopSocketModel.extDictModel?.friendIdInt == dashboardFriendsListModel.userIdInt {
				
				dashboardFriendsListModel.nextInviteAtDouble = twopSocketModel.extDictModel?.expireTimeDouble
				dashboardFriendsListModel.inviteeIdInt = Int(APIController.shared.currentUser!.user_id!)
				
				self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
			}
		}
	}
	
	// 判断集合里有没有该消息id，有就说明socket已经处理过
	func handleTwoChannelMsgSendFunc(msgIdString:String?) -> Bool {
		
		if msgIdString == nil { return false }
		
		let userDefault = UserDefaults.standard
		
		let array = userDefault.array(forKey: MessageIdArrayTag)
		
		if array == nil {
			userDefault.setValue([msgIdString], forKey: MessageIdArrayTag)
		} else {
			var msgIdArray = array as! [String]
			
			if !msgIdArray.contains(msgIdString!) {
				msgIdArray.append(msgIdString!)
				userDefault.setValue(msgIdArray, forKey: MessageIdArrayTag)
			} else {
				return false
			}
		}
		
		return true
	}
}

/**
 键盘相关
*/
extension DashboardMainViewController {
	
	func keyboardWillShowFunc(notification:NSNotification) {
		
		self.isTapEndEditingBool = false // Q1
		
		self.endEditButton.isHidden = false
		
		if Environment.isIphoneX { return }
		
		self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
		self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam * 2 - self.InitialTopConstraintTuple.friends)
		
		self.showStatusBarFunc(isHidden: true)
	}
	
	func keyboardWillHideFunc(notification:NSNotification) {
		
		if !self.isTapEndEditingBool {
			self.endEditButton.isHidden = true
		} else { return } // Q1
		
		if Environment.isIphoneX { return }
		
		self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
		self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
		
		self.showStatusBarFunc(isHidden: false)
	}
}

/**
 代理相关
*/
extension DashboardMainViewController : DashboardFriendsListCellDelegate, DashboardInviteListCellDelegate {
	
	func pairConnectingFunc() {
		
		if self.pairTimerTuple.current > 0 {
			self.pairTimerTuple.current -= 1
		}
		
		if self.pairTimerTuple.current == 0 {
			
			self.connectingTimeoutFunc()
			
			if let delegate = self.delegate {
				delegate.twopTimeoutConnectingFunc!()
			}
		}
	}
	
	func startConnectingFunc(friendIdInt:Int, twopSocketModel:TwopSocketModel) {
		
		self.pairRequestAcceptModel?.channelKeyString = twopSocketModel.extDictModel?.channelKeyString
		self.pairRequestAcceptModel?.channelNameString = twopSocketModel.extDictModel?.channelNameString
		
		self.handleConnectinStatusFunc()
		self.tempCell?.stopTimerFunc()
		self.stopWaittingFunc()
		
		self.addPairTimerFunc()
		
		if let delegate = self.delegate, let model = self.pairRequestAcceptModel {
			delegate.twopStartConnectingFunc!(pairRequestAcceptModel: model)
		}
	}
	
	func connectingTimeoutFunc() {
		
		self.stopPairTimerFunc()
		
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
			
			self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
			self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
			self.weAreTeamLabel.alpha = 0
			self.view.layoutIfNeeded()
			
		}, completion: { (completed) in
			self.someoneImageView.image = UIImage(named: "monkeyDef")
			self.someoneLabel.text = "2P Chat Buddy"
			
			let inviteeIdInt = APIController.shared.currentUser!.user_id == self.tempModel?.userIdInt?.description ? self.tempModel?.inviteeIdInt : self.tempModel?.userIdInt
			self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].inviteeIdInt = inviteeIdInt
			
			// 接受成功后改变status状态，0未操作
			self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].isMissedBool = false
			self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].statusInt = self.pairRequestAcceptModel?.statusInt
			self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].nextInviteAtDouble = self.pairRequestAcceptModel?.nextInviteAtDouble
			
			self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
		})
	}
	
	func connectingSuccessFunc() {
		
		self.stopPairTimerFunc()
		
		self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
		self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
		self.weAreTeamLabel.alpha = 0
		self.view.layoutIfNeeded()
		
		self.someoneImageView.image = UIImage(named: "monkeyDef")
		self.someoneLabel.text = "2P Chat Buddy"
		
		let inviteeIdInt = APIController.shared.currentUser!.user_id == self.tempModel?.userIdInt?.description ? self.tempModel?.inviteeIdInt : self.tempModel?.userIdInt
		self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].inviteeIdInt = inviteeIdInt
		
		// 接受成功后改变status状态，0未操作
		self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].isMissedBool = false
		self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].statusInt = self.pairRequestAcceptModel?.statusInt
		self.twopChatFriendArray[self.twopChatFriendArray.index(of: self.tempModel!)!].nextInviteAtDouble = self.pairRequestAcceptModel?.nextInviteAtDouble
		
		self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
	}
	
	func closeFunc() {
		
	}
	
	func handleConnectinStatusFunc() {
		
		if let delegate = self.delegate {
			delegate.twopPreConnectingFunc!()
		}
		
		// 改变页面状态，10秒后返回dashboard初始页
		UIView.animate(withDuration: 0.3, animations: {
			self.friendsTopConstraint.constant = ScreenHeight
			self.myTeamTopConstraint.constant = ScreenHeight / 2 - 100
			self.view.layoutIfNeeded()
		}) { (completed) in
			UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
				self.someoneImageView.kf.setImage(with: URL(string: self.tempModel!.pathString ?? ""), placeholder: UIImage(named: Tools.getGenderDefaultImageFunc(genderString: self.tempModel!.genderString ?? ""))!)
				self.someoneLabel.text = self.tempModel?.nameString
				self.myTeamTopConstraint.constant = 20
				self.weAreTeamLabel.alpha = 1
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
	
	// 2P CHAT FRIEND LIST
	func dashboardFriendsListCellBtnClickFunc(model: DashboardFriendsListModel, cell: DashboardFriendsListCell, isPair: Bool) {
		self.view.endEditing(true)
		
		self.tempCell = cell
		self.tempModel = model
		
		// 如果是主动邀请，有三十秒倒计时
		// 无论点多少个邀请，都是关闭定时器之后再开启定时器，按最后一个的点击算事件30s
		if isPair { // 发起pair
			if self.timer != nil {
				self.stopWaittingFunc()
			}
			
			self.startWaittingFunc()
		} else { // 接受邀请
			self.handleConnectinStatusFunc()
			self.addPairTimerFunc()
			cell.stopJigglingFunc()
		}
		
		let pathString = isPair ? "request/\(model.userIdInt!)" : "accept/\(model.userIdInt!)"
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2ppairs/\(pathString)", method: .post, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** json after click = \(JSON(jsonAPIDocument.json)), pathString = \(pathString)")
					
					// todo，睿，根据isInviteeBool和返回结果处理之后的逻辑
					self.pairRequestAcceptModel = PairRequestAcceptModel.pairRequestAcceptModel(dict: jsonAPIDocument.json as [String: AnyObject])
					
					// 设置friendsId，如果inviteeIdInt不是自己就是inviteeIdInt，否则就是userId
					let inviteeIdInt = self.pairRequestAcceptModel?.inviteeIdInt?.description == UserManager.UserID ? self.pairRequestAcceptModel?.userIdInt : self.pairRequestAcceptModel?.inviteeIdInt
					
					print("*** inviteeIdInt = \(String(describing: self.pairRequestAcceptModel?.inviteeIdInt)), my userId = \(String(describing: UserManager.UserID)), pair userId = \(String(describing: self.pairRequestAcceptModel?.userIdInt)), inviteeIdInt = \(String(describing: inviteeIdInt))")
					
					self.pairRequestAcceptModel?.friendIdInt = inviteeIdInt
					
					if !isPair {
						if let delegate = self.delegate, let model = self.pairRequestAcceptModel {
							delegate.twopStartConnectingFunc!(pairRequestAcceptModel: model)
						}
					}
				}
		}
	}
	
	// INVITE FRIENDS ON MONKEY
	func dashboardInviteListCellBtnClickFunc(userIdInt:Int) {
		
		print("*** friendshipIdString = \(userIdInt)")
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/request/\(userIdInt)", method: .post, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					let json = JSON(jsonAPIDocument.json)
					print("*** json = \(json)")
					
					self.inviteFriendArray.forEach({ (inviteModel) in
						if userIdInt == inviteModel.userIdInt {
							inviteModel.nextInviteAtDouble = json["next_invite_at"].double
						}
					})
					
					// todo，睿，如果是搜索状态下进行此操作，需要去dataArray里找到该元素更改该元素，不然关闭搜索状态后按钮的状态会被重置
					self.searchArray.removeLast()
					self.searchArray.append(self.inviteFriendArray as AnyObject)
				}
		}
	}
}

extension DashboardMainViewController : UITableViewDataSource, UITableViewDelegate {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return self.searchArray.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.searchArray[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if indexPath.section == 0 {
			
			let friendsListModelArray = self.searchArray[indexPath.section] as? [DashboardFriendsListModel]
			
			if friendsListModelArray != nil { // 转换成功，说明第一个元素是friendsList
				
				let userIdInt = friendsListModelArray?.first?.userIdInt
				
				if userIdInt != nil { // 有值，说明是正常list
					return self.handleCellForRowFunc(tableView: tableView, indexPath: indexPath, isFriendsListCell: true)
				} else { // 没值，显示空值的cell
					return tableView.dequeueReusableCell(withIdentifier: "noFriendsCell")!
				}
			} else { // 转换失败，说明第一个元素是inviteList
				return self.handleCellForRowFunc(tableView: tableView, indexPath: indexPath, isFriendsListCell: false)
			}
		} else {
			return self.handleCellForRowFunc(tableView: tableView, indexPath: indexPath, isFriendsListCell: false)
		}
	}
	
	func handleCellForRowFunc(tableView:UITableView, indexPath:IndexPath, isFriendsListCell:Bool) -> UITableViewCell {
		
		if isFriendsListCell {
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "friendsCell") as! DashboardFriendsListCell
			
			cell.dashboardFriendsListModel = (self.searchArray[indexPath.section] as! [DashboardFriendsListModel])[indexPath.row]
			
			cell.delegate = self
			
			return cell
			
		} else {
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "inviteCell") as! DashboardInviteListCell
			
			cell.dashboardInviteListModel = (self.searchArray[indexPath.section] as! [DashboardInviteListModel])[indexPath.row]
			
			cell.delegate = self
			
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		
		let headView = Bundle.main.loadNibNamed("TwoPerson", owner: self, options: nil)![0] as! TwoPersonSectionView
		
		if self.searchArray.count == 2 {
			headView.sectionTitle.setTitle(self.SectionTitleArray[section], for: .normal)
		} else {
			let friendsListModelArray = self.searchArray[section] as? [DashboardFriendsListModel]
			if friendsListModelArray != nil {
				headView.sectionTitle.setTitle(self.SectionTitleArray[0], for: .normal)
			} else {
				headView.sectionTitle.setTitle(self.SectionTitleArray[1], for: .normal)
			}
		}
		
		return headView
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		self.FootView.backgroundColor = UIColor.clear
		return self.FootView
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		
		let friendsListModelArray = self.searchArray[indexPath.section] as? [DashboardFriendsListModel]
		
		let userIdInt = friendsListModelArray?.first?.userIdInt
		
		// 空值cell显示条件：只可能在第一组、searchArray里必须包含friendsListArray、该friendsListArray是个空对象，里面属性都没值
		if indexPath.section == 0 && friendsListModelArray != nil && userIdInt == nil {
			return 125
		} else {
			return 62
		}
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 30
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}
}
