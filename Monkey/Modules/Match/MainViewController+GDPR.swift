//
//  MainViewController+GDPR.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

extension MainViewController {
	
	func checkEmptyName() {
		guard let currentUser = UserManager.shared.currentUser else { return }
		if currentUser.hasName() { return }
		
		let alertController = UIAlertController(title: "⚠️ Name Change ⚠️", message: "yo keep it pg this time", preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.placeholder = "Input"
			NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextDidChanged), name: NSNotification.Name.UITextFieldTextDidChange, object: textField)
		}
		
		let doneAction = UIAlertAction(title: "kk", style: .default, handler: { [unowned alertController] (alertAction) in
			
			guard let textField = alertController.textFields?.first, let text = textField.text else {
				return
			}
			
			currentUser.update(attributes: [.first_name(text)], completion: { [weak self] (error) in
				if let error = error {
					if error.status != "401" && error.status != "403" {
						self?.present(error.toAlert(onOK: { (UIAlertAction) in
							self?.checkEmptyName()
						}, title:"yo keep it pg", text:"try again"), animated: true, completion: nil)
					}
				}
			})
		})
		
		doneAction.isEnabled = false
		alertController.addAction(doneAction)
		self.present(alertController, animated: true, completion: nil)
	}
	
	func alertTextDidChanged(notification: NSNotification) {
		if let alertController = self.presentedViewController as? UIAlertController,
			let textField = alertController.textFields?.first,
			let doneAction = alertController.actions.first
		{
			doneAction.isEnabled = textField.charactersCount > 2
		}
	}
	
	func notifyBananaTip() {
		guard let deep_link = UserManager.shared.currentAuthorization?.deep_link, let text = deep_link.text, deep_link.is_used == true else { return }
		
		if let realm = try? Realm() {
			do {
				try realm.write {
					deep_link.is_used = false
				}
			} catch(let error) {
				print("Error: ", error)
			}
		}
		
		let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "kk", style: .default, handler: nil))
		self.present(alertController, animated: true, completion: nil)
	}
	
	func loadBananas(isNotificationBool: Bool = false) {
		
		MonkeyModel.request(url: Bananas.common_request_path) { (result: JSONAPIResult<[String: Any]>) in
			switch result {
			case .error(let error):
				print(error)
				break
			case .success(let responseJSON):
				if let bananas = Mapper<Bananas>().map(JSON: responseJSON) {
					self.bananas = bananas
				}
				if isNotificationBool {
					self.showBananaDescription(isNotificationBool: true)
				}
			}
		}
	}
	
	func showBananaDescription(isNotificationBool: Bool = false) {
		AnalyticsCenter.log(withEvent: .bananaPopupEnter, andParameter: [
			"source": isNotificationBool ? "push" : "discovery"
			])
		let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.lineSpacing = 9
		paragraph.alignment = .center
		
		let bananas = self.bananas
		let string = "📲Yesterday: 🍌\(bananas.yesterday) \n 🕑 Time added = 🍌\(bananas.add_time) \n 🎉 Friend added = 🍌\(bananas.add_friend) \n\n \(bananas.promotion)"
		
		let attributedString = NSAttributedString(
			string: string,
			attributes: [
				NSParagraphStyleAttributeName: paragraph,
				NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)
			]
		)
		
		alert.setValue(attributedString, forKey: "attributedMessage")
		alert.addAction(UIAlertAction(title: "Cool", style: .cancel, handler: nil))
		
		self.present(alert, animated: true, completion: nil)
	}
}
