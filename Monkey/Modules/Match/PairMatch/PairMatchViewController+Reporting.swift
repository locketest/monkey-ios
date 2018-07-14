//
//  PairMatchViewController+Reporting.swift
//  Monkey
//
//  Created by 王广威 on 2018/7/13.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire

// extension for CallViewController to handle Reporting
extension PairMatchViewController {
	func report(user: MatchUser) {
		guard let matchModel = self.matchModel else { return }
		
		let chatId = matchModel.match_id
		user.showReport = true
		let alert = UIAlertController(title: "Are you sure you'd like to report this user?", message: APIController.shared.currentExperiment?.report_warning_text ?? "Your account will be disabled if you falsely report a user.", preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "🔞  Person is nude", style: .default, handler: {
			(UIAlertAction) in
			self.sendReport(reason: .nudity, chat_id: chatId, user: user)
		}))
		
		alert.addAction(UIAlertAction(title: "👊 Person has drugs or weapon", style: .default, handler: {
			(UIAlertAction) in
			self.sendReport(reason: .drugsOrWeapon, chat_id: chatId, user: user)
		}))
		//Previously violence
		alert.addAction(UIAlertAction(title: "😷 Person is mean or bullying", style: .default, handler: {
			(UIAlertAction) in
			self.sendReport(reason: .meanOrBully, chat_id: chatId, user: user)
		}))
		
		alert.addAction(UIAlertAction(title: "👴 Person has fake age/gender", style: .default, handler: {
			(UIAlertAction) in
			self.sendReport(reason: .ageOrGender, chat_id: chatId, user: user)
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
	
	func sendReport(reason: ReportType, chat_id: String, user: MatchUser) {
		user.reportReason = reason
		self.matchManager.sendMatchMessage(type: .Report, to: user)
		self.reportMatch(user: user)
		
		let url = "\(Environment.baseURL)/api/\(ApiVersion.V2.rawValue)/reports/\(user.user_id)"
		MonkeyModel.request(url: url, method: .post) { (_) in
			
		}
	}
	
	func reportMatch(user: MatchUser? = nil) {
		if let subscriberView = self.remoteInfo, self.matchModel?.addTimeCount() == 0 {
			//  open pixel effect and cant close anymore
			HWCameraManager.shared().addPixellate()
			// add blur after take screen shot
			let eff = UIBlurEffect.init(style: .light)
			let blurV = UIVisualEffectView.init(effect: eff)
			blurV.frame = subscriberView.bounds
			blurV.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			subscriberView.addSubview(blurV)
			
			if let user = user {
				self.remoteInfo?.reported(user: user)
			}
		}else {
			self.disconnect(reason: .MySkip)
		}
	}
	
	func autoScreenShotUpload(source: AutoScreenShotType) {
		guard let authorization = UserManager.authorization, let currentUser = UserManager.shared.currentUser, currentUser.shouldUploadScreenShot() == true else {
			return
		}
		
		if  let myGender = currentUser.gender,
			myGender == Gender.male.rawValue,
			let otherGender = self.matchModel?.left.gender,
			myGender == otherGender,
			Int.arc4random() % 100 > (RemoteConfigManager.shared.moderation_gender_match) {
			return
		}
		
		RealmUser.lastScreenShotTime = Date().timeIntervalSince1970
		HWCameraManager.shared().snapStream { (imageData) in
			let url = "\(Environment.baseURL)/api/v1.2/reports"
			let headers: [JSONAPIRequest.RequestOption] = [
				.header("Authorization", authorization),
				]
			
			let parameters: Parameters = [
				"data": [
					"type": "screenshots",
					"attributes": [
						"reason": source.rawValue
					]
				]
			]
			
			JSONAPIRequest.init(url: url, method: .post, parameters: parameters, options: headers).addCompletionHandler { (result) in
				switch result {
				case .success(let resultJsonAPIDocument):
					if let jsonData = resultJsonAPIDocument.dataResource, let attributes = jsonData.attributes, let uploadURL = attributes["upload_url"] as? String {
						self.uploadReportImage(imageData, to: uploadURL)
					}
				case .error(_):
					break
				}
			}
		}
	}
	
	func uploadReportImage(_ imageData: Data, to url: URLConvertible) {
		Alamofire.upload(imageData, to: url, method: .put, headers: ["Content-Type": "image/jpeg"])
	}
}
