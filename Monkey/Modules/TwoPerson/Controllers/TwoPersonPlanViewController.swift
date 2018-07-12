//
//  TwoPersonPlanViewController.swift
//  Monkey
//
//  Created by fank on 2018/6/13.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	plan A、B 页

import UIKit
import Contacts
import MessageUI
import RealmSwift
import SwiftyJSON

import UIKit

enum TwopChatRequestsStatusEnum : Int {
	case unhandle = 0
	case accept
	case ignore
}

typealias TwopClosureType = () -> Void

typealias UpdateRedDotClosureType = (_ count:Int) -> Void

class TwoPersonPlanViewController: MonkeyViewController {
	
	var layoutTagInt = 0
	
	let FootView = UIView()
	
	var redDotCountInt = 0
	
	let DurationTime = 0.25
	
	// 是否是x关闭的键盘标识，包括键盘上向下箭头关闭
	var isBtnEndEditingBool = false
	
	var backClosure: TwopClosureType?
	
	var updateRedDotClosure: UpdateRedDotClosureType?
	
	var dataArray : [AnyObject] = [] // 总数据集合
	
	var searchArray : [AnyObject] = [] // search集合
	
	var myContactsArray : [MyContactsModel] = []
	
	var friendsRequestArray : [FriendsRequestModel] = []
	
	let SectionTitleArray = ["2P CHAT REQUESTS", "MY CONTACTS"]
	
	var isPlanBIsUnLockedTuple = (isPlanB: false, isUnLocked: false)
	
	@IBOutlet weak var planAMeImageView: UIImageView!
	
	@IBOutlet weak var planASomeImageView: UIImageView!
	
	@IBOutlet weak var planAImagesBgView: UIView! // 三个图片的父背景
	
	@IBOutlet weak var outSearchBgView: UIView! // 外部搜索背景视图
	
	@IBOutlet weak var searchInTableTextField: UITextField!
	
	@IBOutlet weak var searchOutTableTextField: UITextField!
	
	@IBOutlet weak var endEditOutTableButton: UIButton! // 外部搜索后面的红xx
	
	@IBOutlet weak var noAccessInPlanBImageView: UIImageView!
	
	@IBOutlet weak var noAccessContactsBgView: UIView! // 没有联系人权限时显示的视图
	
	@IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var twoPersonButton: BigYellowButton! // 2p按钮
	
	@IBOutlet weak var redDotLabel: UILabel! // 红点数量提示
	
	@IBOutlet weak var unlockNextButton: BigYellowButton!
	
	@IBOutlet weak var userNotFoundLabel: UILabel!
	
	@IBOutlet weak var topTitleLabel: UILabel! // A、B不同状态下文本不一样
	
	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet weak var headView: UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// 睿，临时，记得删除
		UserDefaults.standard.setValue(false, forKey: IsUploadContactsTag)
		
		print("*** = \(APIController.authorization)")
		
		self.initView()
		
		self.initData()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		self.removeKeyboardObserverFunc()
	}
	
	@IBAction func tapGestureClickFunc(_ sender: UITapGestureRecognizer) {
		self.isBtnEndEditingBool = false
		self.view.endEditing(true)
	}
	
	@IBAction func twoPersonBtnClickFunc(_ sender: BigYellowButton) {
		self.dismiss(animated: true, completion: nil)
		
		if self.backClosure != nil {
			self.backClosure!()
		}
	}
	
	@IBAction func endEditingBtnClickFunc(_ sender: UIButton) {
		
		if !self.isBtnEndEditingBool {
			if !self.isPlanBIsUnLockedTuple.isPlanB {
				self.handleHeadViewFunc(isShow: true)
			} else {
				self.endEditOutTableButton.isHidden = true
				self.view.endEditing(true)
			}
		}
		
		self.userNotFoundLabel.isHidden = true
		self.isBtnEndEditingBool = true
		self.searchOutTableTextField.text = ""
		self.view.endEditing(true)
		
		self.searchArray.removeAll()
		self.searchArray = self.dataArray
		self.tableView.reloadData()
	}
	
	/**
	 没给权限时背景页的去设置页事件，noAccessContactsBgView
	*/
	@IBAction func goToSettingBtnClickFunc(_ sender: BigYellowButton) {
		self.openSettingsFunc()
	}
	
	@IBAction func unlockNextBtnClickFunc(_ sender: BigYellowButton) {
		self.pushToDashboardMainVcFunc()
	}
	
	@IBAction func searchTextFieldEditingChanged(_ sender: UITextField) {
		
		if !sender.text!.isEmpty && Tools.trimSpace(string: sender.text!).count == 0 {
			sender.text = ""
			return
		}
		
		if sender.text!.isEmpty || Tools.trimSpace(string: sender.text!).count == 0 {
			self.endEditOutTableButton.isHidden = false
			self.userNotFoundLabel.isHidden = true
			self.searchArray = self.dataArray
			self.tableView.reloadData()
		} else {
			if !self.endEditOutTableButton.isHidden {
				self.endEditOutTableButton.isHidden = true
			}
			
			if sender.markedTextRange == nil {
				self.handleSearchContactsFunc(sender: sender)
			}
		}
	}
	
	func pushToDashboardMainVcFunc() {
		
//		self.dismiss(animated: true, completion: nil)
		
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "DashboardMainViewController") as! DashboardMainViewController
		vc.modalPresentationStyle = .overFullScreen
		self.present(vc, animated: true, completion: nil)
	}
	
	func handleSearchContactsFunc(sender:UITextField) {
		print("*** sender = \(sender.text!)")
		
		self.searchArray.removeAll()
		self.myContactsArray.removeAll()
		self.friendsRequestArray.removeAll()
		
		if self.dataArray.count == 1 {
			self.addSearchContactsFunc(sender: sender, index: 0)
		} else {
			(self.dataArray[0] as! [FriendsRequestModel]).forEach { (friendModel) in
				if friendModel.nameString!.contains(sender.text!) {
					self.friendsRequestArray.append(friendModel)
				}
			}
			
			if self.friendsRequestArray.count > 0 {
				self.searchArray.append(self.friendsRequestArray as AnyObject)
			}
			
			self.addSearchContactsFunc(sender: sender, index: 1)
		}
		
		if self.searchArray.count == 0 {
			self.userNotFoundLabel.isHidden = false
		} else {
			self.userNotFoundLabel.isHidden = true
		}
		
		self.tableView.reloadData()
	}
	
	func addSearchContactsFunc(sender: UITextField, index: Int) {
		(self.dataArray[index] as! [MyContactsModel]).forEach { (contactModel) in
			if contactModel.nameString!.contains(sender.text!) || contactModel.phoneString!.contains(sender.text!) {
				self.myContactsArray.append(contactModel)
			}
		}
		
		if self.myContactsArray.count > 0 {
			self.searchArray.append(self.myContactsArray as AnyObject)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if self.layoutTagInt == 1 {
			
			let SomeOneCircleColor = UIColor(red: 1, green: 252 / 255, blue: 1 / 255, alpha: 1)
			self.planAImagesBgView.layer.addSublayer(Tools.drawCircleFunc(imageView: self.planASomeImageView, lineWidth: 2, strokeColor: SomeOneCircleColor, padding: 5))
		}
		
		self.layoutTagInt += 1
	}
	
	func initCircleFunc() {
		
		let photo = APIController.shared.currentUser?.profile_photo_url
		
		self.planAMeImageView.kf.setImage(with: URL(string: photo == nil ? "" : photo!), placeholder: UIImage(named: ProfileImageDefault)!)
		
		let MeCircleColor = UIColor(red: 217 / 255, green: 210 / 255, blue: 252 / 255, alpha: 1)
		self.planAImagesBgView.layer.addSublayer(Tools.drawCircleFunc(imageView: self.planAMeImageView, lineWidth: 2, strokeColor: MeCircleColor, padding: 5))
	}
	
	func addKeyboardObserverFunc() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowFunc), name: .UIKeyboardWillShow, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideFunc), name: .UIKeyboardWillHide, object: nil)
	}
	
	func removeKeyboardObserverFunc() {
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
	}
	
	func initTextFieldFunc() {
		
		self.addKeyboardObserverFunc()
		
		let cleanButton = self.searchOutTableTextField.value(forKey: "_clearButton") as! UIButton
		cleanButton.setImage(UIImage(named: "clearButton")!, for: .normal)
		
		self.searchInTableTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
		
		self.searchOutTableTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleRemoteMsgFunc), name: NSNotification.Name(rawValue: GoToSettingTag), object: nil)
	}
	
	func loadFriendsRequestFunc() {
		
		print("*** = \(APIController.authorization)")
		
		// 拿到friends list里的friendship_id跟后端返回的friendship_id对比，相等就拿头像和名字，跟模型一起传到model里填充完整模型
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/", method: .get, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(let error):
					print("*** error : = \(error.message)")
				case .success(let jsonAPIDocument):
					
					print("*** 2p jsonAPIDocument = \(jsonAPIDocument.json["data"])")
					
					if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
						
						if array.count > 0 {
							
							var models : [FriendsRequestModel] = []
							
							let friendsViewModel = FriendsViewModel.sharedFreindsViewModel
							
							array.forEach({ (contact) in
								friendsViewModel.friendships?.forEach({ (friendModel) in
									
									let friendModelUserId = friendModel.user?.user_id
									let contactUserId = contact["user_id"]?.stringValue
									let currentUserId = APIController.shared.currentUser!.user_id
									let contactInviteeId = contact["invitee_id"]?.stringValue
									let contactStatus = contact["status"] as? Int
									
									// inviteeId为自己才表示是被邀请的数据，status为0未操作显示
									if friendModelUserId == contactUserId && currentUserId == contactInviteeId {
										if TwopChatRequestsStatusEnum.unhandle.rawValue == contactStatus {
											models.append(FriendsRequestModel.friendsRequestModel(dict: contact, nameString: friendModel.user!.first_name, pathString: friendModel.user!.profile_photo_url))
										}
									}
								})
							})
							
							if models.count > 0 {
								
								self.redDotCountInt = models.count
								
								self.dataArray.removeAll()
								self.searchArray.removeAll()
								self.friendsRequestArray.removeAll()
								
								self.friendsRequestArray = models
								
								self.dataArray.append(self.friendsRequestArray as AnyObject)
								
								if self.myContactsArray.count > 0 {
									self.dataArray.append(self.myContactsArray as AnyObject)
								}
								
								self.searchArray = self.dataArray
								self.tableView.reloadData()
							}
						}
					}
				}
		}
	}
	
	func handleMyContactsFunc(models:[MyContactsModel]?) {
		
		self.dataArray.removeAll()
		self.searchArray.removeAll()
		self.myContactsArray.removeAll()
		
		if let array = models {
			self.myContactsArray = array
		} else {
			if let array = CodableTools.decodeFunc(type: MyContactsModel.self, decodeKey: MyContactsModelTag) {
				self.myContactsArray = array
			} else {
				print("error: decode error")
				return
			}
		}
		
		// 睿，测试用，正式删除
		self.myContactsArray.forEach { (model) in
//			print("*** name = \(model.nameString!), phoneString = \(model.phoneString!), next at = \(model.nextInviteAtDouble!)")
		}
		//
		
		if self.friendsRequestArray.count > 0 {
			self.dataArray.append(self.friendsRequestArray as AnyObject)
		}
		
		self.dataArray.append(self.myContactsArray as AnyObject)
		self.searchArray = self.dataArray
		self.tableView.reloadData()
	}
	
	func loadMyContactsFunc() {
		
		let contacts = CodableTools.decodeFunc(type: MyContactsModel.self, decodeKey: MyContactsModelTag)

		if contacts == nil { // 说明没有请求过联系人，去请求联系人
			
			JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/contacts/", method: .get, options: [
				.header("Authorization", APIController.authorization),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(_): break
					case .success(let jsonAPIDocument):
						
//						print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"] as? [[String: AnyObject]])")
						
						if let array = jsonAPIDocument.json["data"] as? [[String: AnyObject]] {
							
							if array.count > 0 {
								
								var models : [MyContactsModel] = []
								
								array.forEach({ (contact) in
									models.append(MyContactsModel.myContactsModel(dict: contact))
								})
								
								if CodableTools.encodeFunc(models: models, forKey: MyContactsModelTag) {
									self.handleMyContactsFunc(models: models)
								} else {
									print("error: encode error")
								}
							}
						}
					}
			}
		} else {
			self.handleMyContactsFunc(models: nil)
		}
	}
	
	func handlePlanABViewFunc(){
		
		if self.isPlanBIsUnLockedTuple.isPlanB {
			
			self.hiddenHeadViewFunc()
			
			self.endEditOutTableButton.isHidden = true
			
			if self.isPlanBIsUnLockedTuple.isUnLocked {
				self.topTitleLabel.text = "🎉 UNLOCKED 🎉"
				self.topTitleLabel.font = UIFont.boldSystemFont(ofSize: 28)
			} else {
				// todo，睿，此处次数从用户配置信息中拿出
				let contact_invite_remain_times = APIController.shared.currentUser!.cached_contact_invite_remain_times
				self.topTitleLabel.attributedText = NSMutableAttributedString.attributeStringWithText(textOne: "Invite", textTwo: " \(contact_invite_remain_times) ", textThree:"friends to unlock 2P Chat", colorOne: UIColor.white, colorTwo: UIColor.yellow, fontOne: SystemFont17, fontTwo: BoldSystemFont20)
			}
		}
	}
	
	func initInviteFriendsNotificationFunc() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationMsgFunc), name: NSNotification.Name(rawValue: InviteFriendsNotificationTag), object: nil)
	}
	
	func initUnlockNextBtnFunc() {
		self.unlockNextButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
		self.unlockNextButton.layer.shadowOpacity = 0.7
		self.unlockNextButton.layer.shadowRadius = 28
	}
	
	func initData() {
		
		if UserDefaults.standard.bool(forKey: IsUploadContactsTag) {

			self.loadFriendsRequestFunc()

			self.loadMyContactsFunc()
			
		} else { // 上传过联系人后不再上传
			self.handleContactAuthFunc()
		}
	}
	
	func initView() {
		
		self.initCircleFunc()
		
		self.initTextFieldFunc()
		
		self.handlePlanABViewFunc()
		
		self.initUnlockNextBtnFunc()
		
		self.initInviteFriendsNotificationFunc()
		
		MessageCenter.shared.addMessageObserver(observer: self)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
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
extension TwoPersonPlanViewController {
	
	func handleNotificationMsgFunc(notification:NSNotification) {
		
		let array = notification.object as! Array<Any>
		
		let twopSocketModel = array.first as! TwopSocketModel
		print("*** = \(twopSocketModel.msgIdString!)")
		
		let isBackgrounded = array.last as! Bool
		print("*** = \(isBackgrounded)")
		
		self.initData() // 收到friends request刷新列表并更新main的红点值
	}
}

/**
 socket消息相关
*/
extension TwoPersonPlanViewController : MessageObserver {
	
	// 收到planA主动发起的联系人邀请后，联系人下载安装后unlock2p消息，关闭plan页，进入dashboard页，刷新me接口信息
	func didReceiveTwopDefault(message: [String : Any]) {
		print("*** message = \(message)")
		
		let twopSocketModel = TwopSocketModel.twopSocketModel(dict: message as [String : AnyObject])
		
		print("*** twopSocketModel = \(twopSocketModel.msgIdString?.description), model = \(twopSocketModel.extDictModel?.friendIdInt)")
		
		switch twopSocketModel.msgTypeInt {
		case SocketDefaultMsgTypeEnum.unlock2p.rawValue: // unlock2p
			self.dismiss(animated: true, completion: nil)
			
			self.pushToDashboardMainVcFunc()
			
			let currentUser = UserManager.shared.currentUser
			currentUser?.reload(completion: { (error) in
			})
		case SocketDefaultMsgTypeEnum.friendInvite.rawValue: // friendInvite
			
			// 好友邀请不发socket消息，只发notification消息，故如下可以删除
			self.initData() // 收到friends request刷新列表并更新main的红点值
			
			if self.updateRedDotClosure != nil {
				self.redDotCountInt += 1
				self.updateRedDotClosure!(self.redDotCountInt)
			}
		default:
			break
		}
	}
}

/**
 键盘相关
*/
extension TwoPersonPlanViewController {
	
	func hiddenHeadViewFunc() {
		
		self.tableViewTopConstraint.constant = 68
		
		UIView.animate(withDuration: DurationTime) {
			self.planAImagesBgView.isHidden = true
			self.outSearchBgView.isHidden = false
		}
		
		self.headView.isHidden = true
		self.headView.height = 0
	}
	
	// 此处的headView指的是tableview上的headview
	func handleHeadViewFunc(isShow:Bool) {
		if isShow {
			
			self.tableViewTopConstraint.constant = 110
			
			UIView.animate(withDuration: DurationTime) {
				self.planAImagesBgView.isHidden = false
				self.outSearchBgView.isHidden = true
			}
			
			self.headView.isHidden = false
			self.headView.height = 61
		} else {
			
			self.hiddenHeadViewFunc()
			
			self.searchOutTableTextField.becomeFirstResponder()
		}
		
		self.tableView.reloadData()
	}
	
	func keyboardWillShowFunc(notification:NSNotification) {
		
		self.isBtnEndEditingBool = false
		
		if !self.isPlanBIsUnLockedTuple.isPlanB {
			self.handleHeadViewFunc(isShow: false)
		} else {
			self.endEditOutTableButton.isHidden = false
		}
	}
	
	func keyboardWillHideFunc(notification:NSNotification) {
		
		if !self.isBtnEndEditingBool {
			return
		}
		
		if !self.isPlanBIsUnLockedTuple.isPlanB {
			self.handleHeadViewFunc(isShow: true)
		} else {
			self.endEditOutTableButton.isHidden = true
			self.view.endEditing(true)
		}
	}
}

/**
 tableview相关
*/
extension TwoPersonPlanViewController : UITableViewDataSource, UITableViewDelegate {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return self.searchArray.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.searchArray[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// 不考虑不存在联系人情况，如果联系人不存在，friends request列表数据更不可能存在
		if self.searchArray.count > 1 {
			if indexPath.section == 0 {
				return self.handleCellForRowFunc(tableView: tableView, indexPath: indexPath, isContactCell: false)
			} else {
				return self.handleCellForRowFunc(tableView: tableView, indexPath: indexPath, isContactCell: true)
			}
		} else {
			return self.handleCellForRowFunc(tableView: tableView, indexPath: indexPath, isContactCell: true)
		}
	}
	
	func handleCellForRowFunc(tableView:UITableView, indexPath:IndexPath, isContactCell:Bool) -> UITableViewCell {
		
		if isContactCell {
			let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell") as! MyContactsCell
			
			cell.myContactsModel = (self.searchArray[indexPath.section] as! [MyContactsModel])[indexPath.row]
			
			cell.delegate = self
			
			return cell
			
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "friendsCell") as! FriendsRequestCell
			
			cell.friendsRequestModel = (self.searchArray[indexPath.section] as! [FriendsRequestModel])[indexPath.row]
			
			cell.delegate = self
			
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headView = Bundle.main.loadNibNamed("TwoPerson", owner: self, options: nil)![0] as! TwoPersonSectionView
		headView.sectionTitle.setTitle(self.searchArray.count == 1 ? self.SectionTitleArray[1] : self.SectionTitleArray[section], for: .normal)
		return headView
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		self.FootView.backgroundColor = UIColor.clear
		return self.FootView
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 62
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 25
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}
}

/**
 代理相关
*/
extension TwoPersonPlanViewController : FriendsRequestCellDelegate, MyContactsCellDelegate, MFMessageComposeViewControllerDelegate {
	
	func sendInviteContactFunc(phoneString: String) {
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/contactinvitations/\(phoneString)", method: .post, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument = \(jsonAPIDocument.json)")
					
					if let remainTimes = jsonAPIDocument.json["remain_times"] as? Int, let unlock2p = jsonAPIDocument.json["unlock2p"] as? Bool, let nextInviteAt = jsonAPIDocument.json["next_invite_at"] as? Double {
						
						self.updateContactModelNextInvitedAtFunc(phoneString: phoneString, nextInviteAtDouble: nextInviteAt)
						
						// 根据unlock2p状态控制next按钮显示隐藏、改变剩余多少次的数字
						if unlock2p {
							self.unlockNextButton.isHidden = false
							self.topTitleLabel.text = "🎉 UNLOCKED 🎉"
							self.topTitleLabel.font = UIFont.boldSystemFont(ofSize: 28)
						} else {
							
							if self.isPlanBIsUnLockedTuple.isPlanB {
								self.topTitleLabel.attributedText = NSMutableAttributedString.attributeStringWithText(textOne: "Invite", textTwo: " \(remainTimes) ", textThree:"Friends to try your first 2P mode!", colorOne: UIColor.white, colorTwo: UIColor.yellow, fontOne: SystemFont17, fontTwo: BoldSystemFont20)
							}
							
							if let realm = try? Realm() {
								do {
									try realm.write {
										UserManager.shared.currentUser!.cached_contact_invite_remain_times = remainTimes
									}
								} catch(let error) {
									print("Error: ", error)
								}
							}
						}
					} else {
						print("error: value is nil")
					}
				}
		}
	}
	
	// 发送短信回调，跟android保持一致，不监听发送状态
	func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith
		result: MessageComposeResult) {
		if result == .sent {
			print("*** sent")
		} else {
			print("*** unsend")
		}
		
		self.addKeyboardObserverFunc()
		
		controller.dismiss(animated: true, completion: nil)
	}
	
	// 睿，测试用，上线删除
	func getDateFunc(double:Double) -> Date {
		return Date(timeIntervalSince1970: double / 1000)
	}
	
	func updateContactModelNextInvitedAtFunc(phoneString: String, nextInviteAtDouble:Double) {
		
		if let array = CodableTools.decodeFunc(type: MyContactsModel.self, decodeKey: MyContactsModelTag) {
			
			array.forEach { (model) in
				if model.phoneString == phoneString {
					print("before = \(self.getDateFunc(double: model.nextInviteAtDouble!))")
					model.nextInviteAtDouble = nextInviteAtDouble
					print("after = \(self.getDateFunc(double: model.nextInviteAtDouble!))")
				}
			}
			
			// 存array，变更数据源
			if CodableTools.encodeFunc(models: array, forKey: MyContactsModelTag) {
				print("encode success")
			} else {
				print("encode error")
			}
			
			self.myContactsArray = array
			
			self.searchArray.removeLast()
			self.dataArray.removeLast()
			
			self.searchArray.append(self.myContactsArray as AnyObject)
			self.dataArray.append(self.myContactsArray as AnyObject)
		} else {
			print("error: decode error")
		}
	}
	
	// myContacts邀请
	func myContactsCellBtnClickFunc(phoneString: String) {
		print("*** phoneString = \(phoneString)")
		
		guard MFMessageComposeViewController.canSendText() else {
			return
		}
		
		if let currentExperiment = APIController.shared.currentExperiment {
			
			self.sendInviteContactFunc(phoneString: phoneString)
			
			let inviteFriendsViewController = MFMessageComposeViewController()
			inviteFriendsViewController.recipients = [phoneString]
			inviteFriendsViewController.body = currentExperiment.two_p_unlock_link ?? "error: msg is nil"
			inviteFriendsViewController.messageComposeDelegate = self
			self.present(inviteFriendsViewController, animated: true)
		}
	}
	
	// friendRequest拒绝、同意
	func friendsRequestCellBtnClickFunc(model: FriendsRequestModel, isCancel: Bool) {
		
		print("*** isCancel = \(isCancel), userId = \(model.userIdInt!)")
		
		let pathString = isCancel ? "ignore/\(model.userIdInt!)" : "accept/\(model.userIdInt!)"
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/2pinvitations/\(pathString)", method: .post, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(let error):
					print("*** error = \(error.description)") // 睿，上线时删除
				case .success(let jsonAPIDocument):
					
					print("*** friendRequest拒绝、同意 jsonAPIDocument = \(jsonAPIDocument.json)") // 睿，上线时删除
					print("*** friendRequest拒绝、同意 pathString = \(pathString)")
					
					if self.updateRedDotClosure != nil {
						self.redDotCountInt -= 1
						self.updateRedDotClosure!(self.redDotCountInt)
					}
					
					self.friendsRequestArray.remove(model)
					
					self.dataArray.removeAll()
					self.searchArray.removeAll()
					
					if self.friendsRequestArray.count > 0 {
						self.dataArray.append(self.friendsRequestArray as AnyObject)
					}
					
					self.dataArray.append(self.myContactsArray as AnyObject)
					self.searchArray = self.dataArray
					self.tableView.reloadData()
				}
		}
	}
}

/**
 联系人排序相关
*/
extension TwoPersonPlanViewController {
	
	/**
	 联系人排序
	*/
	func sortContactsFunc(contactsArray:[ContactModel]) {
		
//		print("*** contactsArray = \(contactsArray)")
		
		DispatchQueue(label: "contacts.sort").async {
			
			var contactsDict = [String:[ContactModel]]()
			
			contactsArray.forEach({ (model) in
				
				// 获取姓名的大写首字母
				let firstLetterString = self.getFirstLetterFromStringFunc(string: model.familyName == "" ? model.firstName : model.familyName)
				
				if contactsDict[firstLetterString] != nil {
					contactsDict[firstLetterString]?.append(model)
				} else {
					var arrGroupNames = [ContactModel]()
					arrGroupNames.append(model)
					contactsDict[firstLetterString] = arrGroupNames
				}
			})
			
			// 将addressBookDict字典中的所有Key值进行排序: A~Z
			var nameKeys = Array(contactsDict.keys).sorted()
			
			// 将 "#" 排列在 A~Z 的后面
			if nameKeys.first == "#" {
				nameKeys.insert(nameKeys.first!, at: nameKeys.count)
				nameKeys.remove(at: 0);
			}
			
			var sortedArray : [Any] = []
			
			nameKeys.forEach({ (key) in
				contactsDict[key]?.forEach({ (model) in
					
					// 拿出有头像的手机号，把头像存到沙盒，用手机号当key，直接拿手机号取
					if model.thumbnailImage != nil {
						self.saveContactImageToSandboxFunc(data: model.thumbnailImage!, phoneNumber: self.handlePhoneNumberFormatFunc(phoneString: model.phoneNumber!))
					}
					
					if let jsonAny = self.toJSONStringFunc(model: model) {
						sortedArray.append(jsonAny)
					}
				})
			})
			
//			print("*** sortedArray = \(JSON(sortedArray))")
			
			self.sendUploadContactsRequestFunc(sortedArray: sortedArray)
		}
	}
	
	func sendUploadContactsRequestFunc(sortedArray:[Any]) {
		
		if sortedArray.count > 0 {
			
//			print("*** sortedArray = \(sortedArray)")
			
			JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/contacts/", method: .post, parameters: ["data":sortedArray], options: [
				.header("Authorization", APIController.authorization),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(let error):
						print("*** error = \(error.description)") // 睿，上线时删除
					case .success(let jsonAPIDocument):
//						print("*** upload contacts jsonAPIDocument = \(jsonAPIDocument.json)") // 睿，上线时删除
						
						UserDefaults.standard.setValue(true, forKey: IsUploadContactsTag)
						
						self.initData()
					}
			}
		}
	}
	
	func handlePhoneNumberFormatFunc(phoneString:String) -> String {
		return phoneString.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
	}
	
	func toJSONStringFunc(model:ContactModel) -> Any? {
		
		let phoneString = self.handlePhoneNumberFormatFunc(phoneString: model.phoneNumber!)
		
		let string = "{\"name\":\"\(model.firstName!) \(model.familyName!)\", \"phone_number\":\"\(phoneString)\"}"
		
		if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) {
			if let jsonAny = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) {
				return jsonAny
			}
		}
		
		return nil
	}
	
	func saveContactImageToSandboxFunc(data:Data, phoneNumber:String) {
		
		if FileManager.default.fileExists(atPath: ContactsImageRootPath) {
			self.writeContactImageToFileFunc(data: data, phoneNumber: phoneNumber)
		} else {
			try? FileManager.default.createDirectory(atPath: ContactsImageRootPath, withIntermediateDirectories: true, attributes: nil)
			
			if FileManager.default.fileExists(atPath: ContactsImageRootPath) {
				self.writeContactImageToFileFunc(data: data, phoneNumber: phoneNumber)
			} else {
				print("error: createDirectory exception")
			}
		}
	}
	
	func writeContactImageToFileFunc(data:Data, phoneNumber:String) {
		
		let result = FileManager.default.createFile(atPath: ContactsImageRootPath + "/" + phoneNumber, contents: data, attributes: nil)
		
		if !result { print("error: write contact image exception") }
		
		print("*** result = \(result), phone = \(phoneNumber), data = \(data)")
	}
	
	/**
	 获取联系人姓名首字母，传入汉字字符串，返回大写拼音字母
	*/
	func getFirstLetterFromStringFunc(string:String) -> String {
		
		// 一定要用可变字符串，不能直接用string，不然运行时遇到非字母会报错
		let str = NSMutableString(string: string)
		
		// 将中文转换成带声调的拼音
		CFStringTransform(str as CFMutableString, nil, kCFStringTransformToLatin, false)
		
		// 去掉声调
		let pinyinString = str.folding(options: String.CompareOptions.diacriticInsensitive, locale: Locale.current)
		
		// 处理多音字并将拼音首字母换成大写
		let uppercasedPinyinString = self.handlePolyphoneStringFunc(nameString: str as String, pinyinString: pinyinString).uppercased()
		
		// 截取大写首字母
		let familyNameString = Tools.subStringFunc(string: uppercasedPinyinString, start: 1, end: 1)
		
		if familyNameString.containsEmojiFunc() { return "*" }
		
		// 判断姓名首位是否为大写字母
		let regexA = "^[A-Z]$"
		
		let predA = NSPredicate(format: "SELF MATCHES %@", regexA)
		
		return predA.evaluate(with: familyNameString) ? familyNameString : "#"
	}
	
	/**
	 多音字处理
	*/
	func handlePolyphoneStringFunc(nameString:String, pinyinString:String) -> String {
		
		if nameString.hasPrefix("长") { return "chang" }
		
		if nameString.hasPrefix("沈") { return "shen" }
		
		if nameString.hasPrefix("厦") { return "xia" }
		
		if nameString.hasPrefix("地") { return "di" }
		
		if nameString.hasPrefix("重") { return "chong" }
		
		return pinyinString
	}
}

/**
 授权相关
*/
extension TwoPersonPlanViewController {
	
	func handleContactAuthFunc() {
		
		let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
		switch status {
		case .notDetermined:
			CNContactStore().requestAccess(for: CNEntityType.contacts) { (granted, error) in
				if granted {
					print("*** 同意")
					self.openContactFunc()
				} else {
					print("*** 拒绝")
					self.alertAuthViewFunc()
				}
			}
		case .denied, .restricted:
			self.alertAuthViewFunc()
		case .authorized:
			self.openContactFunc()
		}
	}
	
	/**
	 检查当前是否打开了权限，用于普通状态检测和从设置页面返回后的权限状态检测
	*/
	func isOpenAuthFromSettingFunc() -> Bool {
		
		let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
		
		return status == .authorized ? true : false
	}
	
	/**
	 跳转到设置页后点左上角返回
	*/
	func handleRemoteMsgFunc() {
		
		UserDefaults.standard.set(false, forKey: GoToSettingTag)
		
		if self.isOpenAuthFromSettingFunc() {
			self.openContactFunc()
			
			self.tableView.isHidden = false
			self.noAccessContactsBgView.isHidden = true
		} else {
			self.tableView.isHidden = true
			self.noAccessContactsBgView.isHidden = false
			self.view.bringSubview(toFront: self.noAccessContactsBgView)
			
			if !self.isPlanBIsUnLockedTuple.isPlanB {
				self.noAccessInPlanBImageView.isHidden = true
			}
		}
	}
	
	/**
	 获取到权限后的操作
	*/
	func openContactFunc() {
		print("*** 获取到权限后的操作")
		
		let store = CNContactStore()
		
		var contactsArray : [ContactModel] = []
		
		let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactThumbnailImageDataKey]
		
		let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
		
		try? store.enumerateContacts(with: request) { (contact, stop) in
			ContactModel.contactModelToArray(contact: contact).forEach({ (model) in
				
				var tagInt = 0
				
				contactsArray.forEach({ (contactModel) in
					if contactModel.phoneNumber == model.phoneNumber {
						tagInt = 1
					}
				})
				
				if tagInt == 0 { contactsArray.append(model) }
			})
		}
		
//		print("*** contactsArray = \(contactsArray)")
		
		self.sortContactsFunc(contactsArray: contactsArray)
	}
	
	/**
	 拒绝授权后跳转到setting页，跳转到当前项目的设置页面
	*/
	func openSettingsFunc() {
		
		UserDefaults.standard.set(true, forKey: GoToSettingTag)
		
		if #available(iOS 10.0, *) {
			UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { (state) in
				print("*** state = \(state)")
			})
		} else {
			UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
		}
	}
	
	/**
	 二次弹出授权窗口然后去setting页设置权限
	*/
	func alertAuthViewFunc() {
		
		let alertController = UIAlertController(title: nil, message: "Allow contacts to make more friends!", preferredStyle: .alert)
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
			self.noAccessContactsBgView.isHidden = false
			self.view.bringSubview(toFront: self.noAccessContactsBgView)
		}))
		
		alertController.addAction(UIAlertAction(title: "Sure", style: .default, handler: { (defaultAlert) in
			self.openSettingsFunc()
		}))
		
		self.alertKeyAndVisibleFunc(alert: alertController)
	}
	
	func alertKeyAndVisibleFunc(alert:UIAlertController) {
		let alertWindow = UIWindow(frame: UIScreen.main.bounds)
		alertWindow.rootViewController = UIViewController()
		alertWindow.windowLevel = UIWindowLevelAlert
		alertWindow.makeKeyAndVisible()
		alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
	}
}
