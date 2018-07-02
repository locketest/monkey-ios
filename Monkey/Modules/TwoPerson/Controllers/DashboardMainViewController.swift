//
//  DashboardMainViewController.swift
//  Monkey
//
//  Created by fank on 2018/6/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  Dashboard主页

import UIKit
import DeviceKit

class DashboardMainViewController: MonkeyViewController {
	
	var timer : Timer?
	
	var currentInt = 1

	let FootView = UIView()
	
	// 是否是通过手势关闭的键盘标识
	var isTapEndEditingBool = false
	
	var backClosure: TwopClosureType?
	
	var someoneCircle : CAShapeLayer!
	
	var invitingAnimLayer : InvitingProgressLayer!
	
	var dataArray : [AnyObject] = [] // 总数据集合
	
	var searchArray : [AnyObject] = [] // search集合
	
	var twopChatFriendArray : [DashboardFriendsListModel] = []
	
	var inviteFriendArray : [DashboardInviteListModel] = []
	
	let InitialTopConstraintTuple = (myTeam: 64, friends: 209)
	
	let SectionTitleArray = ["2P CHAT FRIEND LIST", "INVITE FRIENDS ON MONKEY"]
	
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

        self.initView()
		
		self.initData()
    }
	
	@IBAction func tapGestureClickFunc(_ sender: UITapGestureRecognizer) {
		self.isTapEndEditingBool = true
		self.view.endEditing(true)
	}
	
	@IBAction func twoPersonBtnClickFunc(_ sender: BigYellowButton) {
		self.dismiss(animated: true, completion: nil)
		
		if self.backClosure != nil {
			self.backClosure!()
		}
	}
	
	@IBAction func endEditingBtnClickFunc(_ sender: UIButton) {
		
		if self.isTapEndEditingBool { // 点击空白处关闭键盘时再点end按钮不会触发键盘关闭事件，但是还是需要调整view的位置，Q1
			self.endEditButton.isHidden = true
			self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
			self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
		}
		
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
		
		if sender.text!.isEmpty || Tools.trimSpace(string: sender.text!).count == 0 {
			self.endEditButton.isHidden = false
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
		
		(self.dataArray[0] as! [DashboardFriendsListModel]).forEach { (friendsListModel) in
			if friendsListModel.nameString!.contains(sender.text!) {
				self.twopChatFriendArray.append(friendsListModel)
			}
		}
		
		(self.dataArray[1] as! [DashboardInviteListModel]).forEach { (inviteListModel) in
			if inviteListModel.nameString!.contains(sender.text!) {
				self.inviteFriendArray.append(inviteListModel)
			}
		}
		
		if self.twopChatFriendArray.count > 0 {
			self.searchArray.append(self.twopChatFriendArray as AnyObject)
		}
		
		if self.inviteFriendArray.count > 0 {
			self.searchArray.append(self.inviteFriendArray as AnyObject)
		}
		
		if self.searchArray.count == 0 {
			self.userNotFoundLabel.isHidden = false
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
		
		self.someoneLabel.text = "Someone"
		self.someoneLabel.textColor = UIColor.lightGray
	}
	
	func initInvitingLayerFunc() {
		
		self.invitingAnimLayer = InvitingProgressLayer(layer: self.someoneImageView.layer)
		
		self.invitingAnimLayer.frame = CGRect(x: 0, y: 0, width: self.someoneImageView.width + 5, height: self.someoneImageView.height + 5)
		
		self.invitingAnimLayer.position = CGPoint(x: self.someoneImageView.width / 2, y: self.someoneImageView.height / 2)
	}
	
	func initCircleFunc() {
		
		if let photo = APIController.shared.currentUser?.profile_photo_url { self.meImageView.kf.setImage(with: URL(string: photo)) }
		
		let MeCircleColor = UIColor(red: 217 / 255, green: 210 / 255, blue: 252 / 255, alpha: 1)
		self.meAndSomeoneBgView.layer.addSublayer(Tools.drawCircleFunc(imageView: self.meImageView, lineWidth: 1.3, strokeColor: MeCircleColor, padding: 5))
		
		self.someoneCircle = Tools.drawCircleFunc(imageView: self.someoneImageView, lineWidth: 1.3, strokeColor: MeCircleColor, padding: 5)
		
		self.addSomeoneCircleFunc()
	}
	
	func loadPairAndUserInfoFunc(models:[FriendshipModel]) {
		
		var friendRequestArray : [FriendsRequestModel] = []
		
		var userInfoArray : [UsersInfoModel] = []
		
		var pairListArray : [PairListModel] = []
		
		let friendIdArray = models.map { $0.friendIdString }
		
		let queue = DispatchQueue(label: "dashboard.pair.userInfo", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
		
		queue.async {
			
			JSONAPIRequest(url: "http://192.168.200.88:8080/api/v2/users?ids=\(friendIdArray)", method: .get, options: [
				.header("Authorization", AuthString),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(_): break
					case .success(let jsonAPIDocument):
						
						print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as! [[String: AnyObject]])")
						
						if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
							array.forEach({ (userInfo) in
								userInfoArray.append(UsersInfoModel.usersInfoModel(dict: userInfo))
							})
						}
					}
			}
		}
		
		queue.async {
			
			JSONAPIRequest(url: "http://192.168.200.88:8080/api/v2/2p/friend2p_pair", method: .get, options: [
				.header("Authorization", AuthString),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(_): break
					case .success(let jsonAPIDocument):
						
						print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as! [[String: AnyObject]])")
						
						if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
							array.forEach({ (pairInfo) in
								pairListArray.append(PairListModel.pairListModel(dict: pairInfo))
							})
						}
					}
			}
		}
		
		queue.async {
			
			JSONAPIRequest(url: "http://192.168.200.191:8080/api/v2/2p/friend2p_request", method: .get, options: [
				.header("Authorization", AuthString),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(let error):
						print("*** error : = \(error.message)")
					case .success(let jsonAPIDocument):
						
						print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as! [[String: AnyObject]])")
						
						if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
							array.forEach({ (friendModel) in
								friendRequestArray.append(FriendsRequestModel.friendsRequestModel(dict: friendModel, nameString: nil, pathString: nil))
							})
						}
					}
			}
		}
		
		queue.async(group: nil, qos: .default, flags: .barrier) {
			
			print("*** friendRequestArray = \(friendRequestArray.count)")
			print("*** userInfoArray = \(userInfoArray.count)")
			print("*** pairListArray = \(pairListArray.count)")
			
//			self.dataArray.removeAll()
//			self.searchArray.removeAll()
//			self.inviteFriendArray.removeAll()
//			self.twopChatFriendArray.removeAll()
			
			var onlineArray : [DashboardFriendsListModel] = []
			var lastPairArray : [DashboardFriendsListModel] = []
			var missedArray : [DashboardFriendsListModel] = []
			var otherArray : [DashboardFriendsListModel] = []
			
			let userIdString = APIController.shared.currentUser!.user_id!
			
			// 遍历models，在里面装配两个显示集合
			models.forEach({ (model) in
				
				userInfoArray.forEach({ (userInfo) in
					
					if model.friendIdString == userInfo.idString {
						
						friendRequestArray.forEach({ (friendModel) in
							
							if model.friendIdString == friendModel.friendshipIdString {
								
								if userInfo.unlock2pBool! { // 通过unlock2pBool区分是1p还是2p
									
									let date = Date(timeIntervalSince1970: friendModel.timestampDouble! / 1000)
									
									if userInfo.onlineStatusString == "1" { // 1 online
										onlineArray.append(DashboardFriendsListModel.dashboardFriendsListModel(userInfo: userInfo, friendsRequestModel: friendModel))
									} else if friendModel.statusInt == 1 { // 1 pair接受过
										lastPairArray.append(DashboardFriendsListModel.dashboardFriendsListModel(userInfo: userInfo, friendsRequestModel: friendModel))
									} else if date.timeIntervalSince(Date()) <= 0 { // timestamp过期了就是missed
										missedArray.append(DashboardFriendsListModel.dashboardFriendsListModel(userInfo: userInfo, friendsRequestModel: friendModel, isMissedBool: true))
									} else {
										otherArray.append(DashboardFriendsListModel.dashboardFriendsListModel(userInfo: userInfo, friendsRequestModel: friendModel))
									}
								} else { // 1p，且被邀请id不是自己，就表示自己是主动发起邀请的内容
									if userIdString != friendModel.inviteeIdString {
										self.inviteFriendArray.append(DashboardInviteListModel.dashboardInviteListModel(userInfo: userInfo, friendsRequestModel: friendModel))
									}
								}
							}
						})
					}
				})
			})
			
			// 至此，数据装配完毕，接下来按timestamp排序四个临时集合然后放到twopChatFriendArray里,再将两个集合放到dataArray里
			onlineArray = onlineArray.sorted { $0.timestampDouble! > $1.timestampDouble! }
			lastPairArray = lastPairArray.sorted { $0.timestampDouble! > $1.timestampDouble! }
			missedArray = missedArray.sorted { $0.timestampDouble! > $1.timestampDouble! }
			otherArray = otherArray.sorted { $0.timestampDouble! > $1.timestampDouble! }
			
			self.twopChatFriendArray += onlineArray
			self.twopChatFriendArray += lastPairArray
			self.twopChatFriendArray += missedArray
			self.twopChatFriendArray += otherArray
			
			// 如果没有2p好友，加一个空的模型在数据源里，用以显示第一组的无数据cell
			if self.twopChatFriendArray.isEmpty { self.twopChatFriendArray.append(DashboardFriendsListModel()) }
			
			self.dataArray.append(self.twopChatFriendArray as AnyObject)
			self.dataArray.append(self.inviteFriendArray as AnyObject)
			self.searchArray = self.dataArray
			self.tableView.reloadData()
		}
	}
	
	func loadFriendsListFunc() {
		
		JSONAPIRequest(url: "http://192.168.200.88:8080/api/v2/friendship", method: .get, options: [
			.header("Authorization", AuthString),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as! [[String: AnyObject]])")
					
					let array = jsonAPIDocument.json["data"] as! [[String: AnyObject]]
					
					if array.count > 0 {
						
						var models : [FriendshipModel] = []
						
						array.forEach({ (model) in
							models.append(FriendshipModel.friendshipModel(dict: model))
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
	
	func initData() {
		
//		self.loadFriendsListFunc()
	}
	
	func initView() {
		
		self.initCircleFunc()
		
		self.initInvitingLayerFunc()
		
		self.myTeamTopConstraint.constant = Device() == .iPhoneX ? 40 : 64
		
		self.friendsTopConstraint.constant = Device() == .iPhoneX ? 185 : 209
		
		self.friendsBottomConstraint.constant = Device() == .iPhoneX ? 44 : 80
		
		let cleanButton = self.searchTextField.value(forKey: "_clearButton") as! UIButton
		cleanButton.setImage(UIImage(named: "clearButton")!, for: .normal)
		
		self.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowFunc), name: .UIKeyboardWillShow, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideFunc), name: .UIKeyboardWillHide, object: nil)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
	}
}

/**
 键盘相关
*/
extension DashboardMainViewController {
	
	func keyboardWillShowFunc(notification:NSNotification) {
		
		self.isTapEndEditingBool = false // Q1
		
		self.endEditButton.isHidden = false
		
		if Device() == .iPhoneX { return }
		
		self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
		self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam * 2 - self.InitialTopConstraintTuple.friends)
	}
	
	func keyboardWillHideFunc(notification:NSNotification) {
		
		if !self.isTapEndEditingBool {
			self.endEditButton.isHidden = true
		} else { return } // Q1
		
		if Device() == .iPhoneX { return }
		
		self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
		self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
	}
}

/**
 代理相关
*/
extension DashboardMainViewController : DashboardFriendsListCellDelegate, DashboardInviteListCellDelegate {
	
	// 2P CHAT FRIEND LIST
	func dashboardFriendsListCellBtnClickFunc(model:DashboardFriendsListModel) {
		self.view.endEditing(true)
		
		// inviteeId区分是受邀请(==)，还是主动邀请(!=)
		let isInviteeBool = APIController.shared.currentUser!.user_id == model.inviteeIdString ? true : false
		
		// 如果是主动邀请，有三十秒倒计时
		// 无论点多少个邀请，都是关闭定时器之后再开启定时器，按最后一个的点击算事件30s
		if !isInviteeBool { // 发起pair
			if self.timer != nil {
				self.stopWaittingFunc()
			}
			
			self.startWaittingFunc()
		} else { // 接受邀请
			// 改变页面状态，10秒后返回dashboard初始页
			UIView.animate(withDuration: 0.3, animations: {
				self.friendsTopConstraint.constant = ScreenHeight
				self.myTeamTopConstraint.constant = ScreenHeight / 2 - 100
				self.view.layoutIfNeeded()
			}) { (completed) in
				UIView.animate(withDuration: 0.5, delay: 0.8, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
					// todo，睿，此处用CacheImage替代，到connection页时someone的头像为对方给的头像
					self.someoneImageView.image = UIImage(named: model.pathString!)
					self.someoneLabel.text = model.nameString
					self.myTeamTopConstraint.constant = 0
					self.weAreTeamLabel.alpha = 1
					self.view.layoutIfNeeded()
				}, completion: { (completed) in
					UIView.animate(withDuration: 0.5, delay: 10, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
						self.friendsTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.friends)
						self.myTeamTopConstraint.constant = CGFloat(self.InitialTopConstraintTuple.myTeam)
						self.weAreTeamLabel.alpha = 0
						self.view.layoutIfNeeded()
					}, completion: nil)
				})
			}
		}
		
		JSONAPIRequest(url: "http://192.168.200.88:8080/api/v2/2p/friend2p_pair/\(isInviteeBool ? model.idString! : model.friendshipIdString!)", method: isInviteeBool ? .patch : .post, options: [
			.header("Authorization", AuthString),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as! [[String: AnyObject]])")
					
					// todo，睿，根据isInviteeBool和返回结果处理之后的逻辑
				}
		}
	}
	
	// INVITE FRIENDS ON MONKEY
	func dashboardInviteListCellBtnClickFunc(friendshipIdString: String) {
		print("*** friendshipIdString = \(friendshipIdString)")
		
		JSONAPIRequest(url: "http://192.168.200.88:8080/api/v2/2p/friend2p_request/\(friendshipIdString)", method: .post, options: [
			.header("Authorization", AuthString),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					// 睿，返回的数据没有意义，无需做任何数据操作
					print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as! [[String: AnyObject]])")
				}
		}
	}
}

extension DashboardMainViewController : UITableViewDataSource, UITableViewDelegate {
	
	func numberOfSections(in tableView: UITableView) -> Int {
//		return self.searchArray.count
		return 2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		return self.searchArray[section].count
		return 3
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if indexPath.section == 0 {
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "friendsCell") as! DashboardFriendsListCell
			
			cell.delegate = self
			
			return cell
			
			// 睿，正式时打开
//			if (self.searchArray[0] as! DashboardFriendsListModel).idString != nil {
//				let cell = tableView.dequeueReusableCell(withIdentifier: "friendsCell") as! DashboardFriendsListCell
//
//				cell.delegate = self
//
//				return cell
//			} else {
//				return tableView.dequeueReusableCell(withIdentifier: "noFriendsCell")!
//			}
		} else {
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "inviteCell") as! DashboardInviteListCell
			
			cell.delegate = self
			
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headView = Bundle.main.loadNibNamed("TwoPerson", owner: self, options: nil)![0] as! TwoPersonSectionView
		headView.sectionTitle.setTitle(self.SectionTitleArray[section], for: .normal)
		return headView
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		self.FootView.backgroundColor = UIColor.clear
		return self.FootView
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		// 睿，正式时打开
//		if indexPath.section == 0 && self.searchArray[0].count == 0 {
//			return 110
//		} else {
//			return 62
//		}
		return 62
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 30
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}
}
