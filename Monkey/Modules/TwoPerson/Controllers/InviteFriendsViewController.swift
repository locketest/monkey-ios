//
//  InviteFriendsViewController.swift
//  Monkey
//
//  Created by fank on 2018/6/19.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//	Dashboard邀请好友

import UIKit
import Contacts
import MessageUI
import SwiftyJSON

class InviteFriendsViewController: MonkeyViewController {
	
	var dataArray : [MyContactsModel] = []
	
	var searchArray : [MyContactsModel] = []
	
	@IBOutlet weak var searchTextField: UITextField!
	
	@IBOutlet weak var searchCancelButton: UIButton!
	
	@IBOutlet weak var tableViewTitleLabel: UILabel!
	
	@IBOutlet weak var userNotFoundLabel: UILabel!
	
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		UserDefaults.standard.setValue(false, forKey: IsUploadContactsTag)

        self.initView()
		
		self.initData()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		self.removeKeyboardObserverFunc()
	}
	
	@IBAction func dismissBtnClickFunc(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func endEditingBtnClickFunc(_ sender: UIButton) {
		
		self.searchTextField.text = ""
		self.view.endEditing(true)
		
		self.searchArray.removeAll()
		self.searchArray = self.dataArray
		self.tableView.reloadData()
	}
	
	@IBAction func searchTextFieldEditingChanged(_ sender: UITextField) {
		
		if !sender.text!.isEmpty && Tools.trimSpace(string: sender.text!).count == 0 {
			sender.text = ""
			return
		}
		
		if sender.text!.isEmpty || Tools.trimSpace(string: sender.text!).count == 0 {
			self.searchCancelButton.isHidden = false
			self.tableViewTitleLabel.isHidden = false
			self.userNotFoundLabel.isHidden = true
			self.searchArray = self.dataArray
			self.tableView.reloadData()
		} else {
			if !self.searchCancelButton.isHidden {
				self.searchCancelButton.isHidden = true
			}
			
			if sender.markedTextRange == nil {
				self.handleSearchContactsFunc(sender: sender)
			}
		}
	}
	
	func handleSearchContactsFunc(sender:UITextField) {
		print("*** sender = \(sender.text!)")
		
		self.searchArray.removeAll()
		
		self.dataArray.forEach { (contactModel) in
			if contactModel.nameString!.contains(sender.text!) || contactModel.phoneString!.contains(sender.text!) {
				self.searchArray.append(contactModel)
			}
		}
		
		if self.searchArray.count == 0 {
			self.userNotFoundLabel.isHidden = false
			self.tableViewTitleLabel.isHidden = true
		} else {
			self.userNotFoundLabel.isHidden = true
			self.tableViewTitleLabel.isHidden = false
		}
		
		self.tableView.reloadData()
	}
	
	func keyboardWillShowFunc(notification:NSNotification) {
		self.searchCancelButton.isHidden = false
	}
	
	func keyboardWillHideFunc(notification:NSNotification) {
		self.searchCancelButton.isHidden = true
	}
	
	func handleMyContactsFunc(models:[MyContactsModel]?) {
		
		self.dataArray.removeAll()
		self.searchArray.removeAll()
		
		if let array = models {
			self.dataArray = array
		} else {
			if let array = CodableTools.decodeFunc(type: MyContactsModel.self, decodeKey: MyContactsModelTag) {
				self.dataArray = array
			} else {
				print("error: decode error")
				return
			}
		}
		
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
						
						print("*** jsonAPIDocument = \(jsonAPIDocument.json["data"])")
						
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
	
	func addKeyboardObserverFunc() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowFunc), name: .UIKeyboardWillShow, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideFunc), name: .UIKeyboardWillHide, object: nil)
	}
	
	func removeKeyboardObserverFunc() {
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
	}
	
	func initData() {
		if UserDefaults.standard.bool(forKey: IsUploadContactsTag) {
			self.loadMyContactsFunc()
		} else {  // 上传过联系人后不再上传
			self.handleContactAuthFunc()
		}
	}
	
	func initView() {
		
		self.addKeyboardObserverFunc()
		
		let cleanButton = self.searchTextField.value(forKey: "_clearButton") as! UIButton
		cleanButton.setImage(UIImage(named: "clearButton")!, for: .normal)
		
		self.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleRemoteMsgFunc), name: NSNotification.Name(rawValue: GoToSettingTag), object: nil)
	}
}

/**
 代理相关
*/
extension InviteFriendsViewController : MyContactsCellDelegate, MFMessageComposeViewControllerDelegate {
	
	func sendInviteContactFunc(phoneString: String) {
		
		JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/contactinvitations/\(phoneString)", method: .post, options: [
			.header("Authorization", APIController.authorization),
			]).addCompletionHandler { (response) in
				switch response {
				case .error(_): break
				case .success(let jsonAPIDocument):
					
					print("*** jsonAPIDocument = \(JSON(jsonAPIDocument.json))")
					
					if let nextInviteAtDouble = jsonAPIDocument.json["next_invite_at"] as? Double {
						
						if let array = CodableTools.decodeFunc(type: MyContactsModel.self, decodeKey: MyContactsModelTag) {
							
							array.forEach { (model) in
								if model.phoneString == phoneString {
									model.nextInviteAtDouble = nextInviteAtDouble
								}
							}
							
							// 存array，变更数据源
							if CodableTools.encodeFunc(models: array, forKey: MyContactsModelTag) {
								print("encode success")
							} else {
								print("encode error")
							}
							
							self.dataArray = array
							self.searchArray = self.dataArray
						} else {
							print("error: decode error")
						}
					} else {
						print("error: value is nil")
					}
				}
		}
	}
	
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
	
	// myContacts邀请
	func myContactsCellBtnClickFunc(phoneString: String) {
		print("*** id = \(phoneString)")
		
		guard MFMessageComposeViewController.canSendText() else {
			return
		}
		
		if let currentExperiment = APIController.shared.currentExperiment {
			
			self.sendInviteContactFunc(phoneString: phoneString)
			
			let inviteFriendsViewController = MFMessageComposeViewController()
			inviteFriendsViewController.recipients = [phoneString]
			inviteFriendsViewController.body = currentExperiment.two_p_dashboard_link!
			inviteFriendsViewController.messageComposeDelegate = self
			self.present(inviteFriendsViewController, animated: true)
		}
	}
}

extension InviteFriendsViewController : UITableViewDataSource, UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.searchArray.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell") as! MyContactsCell
		
		cell.myContactsModel = self.searchArray[indexPath.row]
		
		cell.delegate = self
		
		return cell
	}
}

/**
 联系人排序相关
*/
extension InviteFriendsViewController {
	
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
						self.saveContactImageToSandboxFunc(data: model.thumbnailImage!, phoneNumber: model.phoneNumber)
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
			
			print("*** sortedArray = \(sortedArray)")
			
			JSONAPIRequest(url: "\(Environment.baseURL)/api/v2/contacts/", method: .post, parameters: ["data":sortedArray], options: [
				.header("Authorization", APIController.authorization),
				]).addCompletionHandler { (response) in
					switch response {
					case .error(let error):
						print("*** error = \(error.description)") // 睿，上线时删除
					case .success(let jsonAPIDocument):
						print("*** upload contacts jsonAPIDocument = \(jsonAPIDocument.json)") // 睿，上线时删除
						
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
		let stringPinYin = self.handlePolyphoneStringFunc(nameString: str as String, pinyinString: pinyinString).uppercased()
		
		// 截取大写首字母
		let familyNameString = Tools.subStringFunc(string: stringPinYin, start: 1, end: 1)
		
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
extension InviteFriendsViewController {
	
	func handleContactAuthFunc() {
		
		let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
		switch status {
		case .notDetermined:
			CNContactStore().requestAccess(for: CNEntityType.contacts) { (granted, error) in
				if granted {
					self.openContactFunc()
				} else {
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
		// todo，睿， ??
		// dashboard里独立的邀请好友页面暂无未授权页面
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
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
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
