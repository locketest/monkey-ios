//
//  MainViewController+Reporting.swift
//  Monkey
//
//  Created by Philip Bernstein on 7/9/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire
import Social
import Realm

// extension for CallViewController to handle Reporting
extension CallViewController {
    @IBAction func report(_ sender: BigYellowButton) {

        guard let chatId = self.chatSession?.chat?.chatId else {
            print("Error: No chat id available")
            return
        }

        self.callDelegate?.stopFindingChats(andDisconnect: false, forReason: "reporting")
        let alert = UIAlertController(title: "Are you sure you'd like to report this user?", message: APIController.shared.currentExperiment?.report_warning_text ?? "Your account will be disabled if you falsely report a user.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "🔞  Person is nude", style: .default, handler: {
            (UIAlertAction) in
			self.sendReport(reason: .nudity, chat_id: chatId)
        }))

        alert.addAction(UIAlertAction(title: "👊 Person has drugs or weapon", style: .default, handler: {
            (UIAlertAction) in
			self.sendReport(reason: .drugsOrWeapon, chat_id: chatId)
        }))
        //Previously violence
        alert.addAction(UIAlertAction(title: "😷 Person is mean or bullying", style: .default, handler: {
            (UIAlertAction) in
			self.sendReport(reason: .meanOrBully, chat_id: chatId)
        }))

        alert.addAction(UIAlertAction(title: "👴 Person has fake age/gender", style: .default, handler: {
            (UIAlertAction) in
			self.sendReport(reason: .ageOrGender, chat_id: chatId)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (UIAlertAction) in
           self.callDelegate?.startFindingChats(forReason: "reporting")
        }))
        self.present(alert, animated: true, completion: nil)
    }

	func sendReport(reason: ReportType, chat_id: String) {
        self.callDelegate?.startFindingChats(forReason: "reporting")
        
		guard let authorization = APIController.authorization else {
			return
		}

		if let addedTime = self.chatSession?.hadAddTime, addedTime == false, self.chatSession?.matchMode == .VideoMode {
			//  open pixel effect and cant close anymore
			HWCameraManager.shared().addPixellate()

			if let subscriberView = self.chatSession?.remoteView {
				// add blur after take screen shot
				let eff = UIBlurEffect.init(style: .light)
				let blurV = UIVisualEffectView.init(effect: eff)
				blurV.frame = self.view.bounds
				subscriberView.addSubview(blurV)
			}
		}

		self.chatSession?.isReportedChat = true
		self.chatSession?.sentReport()

		self.statusCornerView.isUserInteractionEnabled = false
		self.policeButton.isEnabled = false
		self.policeButtonWidth.constant = 150
		self.reportedLabel = UILabel()
		self.reportedLabel!.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightMedium)
		self.reportedLabel!.frame = CGRect(x: 57, y: 0, width: 100, height: 57)
		self.reportedLabel!.textColor = .white
		self.reportedLabel!.text = "Reported"
		self.policeButton.addSubview(self.reportedLabel!)
		UIView.animate(withDuration: 0.3, animations: {
			self.policeButton.emojiLabel?.text = "😳"
			self.containerView.layoutIfNeeded()
		}) { (Bool) in

		}

		let url = "\(Environment.baseURL)/api/v1.2/reports"
		let headers: [JSONAPIRequest.RequestOption] = [
			.header("Authorization", authorization),
			.header("Accept", "application/json"),
			]

		let parameters: Parameters = [
			"data": [
				"type": "reports",
				"attributes": [
					"chat_id": chat_id,
					"reason": reason.rawValue,
				]
			]
		]

		JSONAPIRequest.init(url: url, method: .post, parameters: parameters, options: headers)
	}

    func autoScreenShotUpload(source: AutoScreenShotType) {
		guard let authorization = APIController.authorization, let currentUser = APIController.shared.currentUser, currentUser.shouldUploadScreenShot() == true else {
			return
		}

		if  let myGender = APIController.shared.currentUser?.gender,
			let otherGender = self.chatSession?.chat?.gender,
			myGender == "male" && otherGender == "male",
			(arc4random() % 100) > (RemoteConfigManager.shared.moderation_gender_match) {
			return
		}

		RealmUser.lastScreenShotTime = Date().timeIntervalSince1970

		HWCameraManager.shared().snapStream { (imageData) in

			let url = "\(Environment.baseURL)/api/v1.2/reports"
			let headers: [JSONAPIRequest.RequestOption] = [
				.header("Authorization", authorization),
				.header("Accept", "application/json"),
				]

			let parameters: Parameters = [
				"data": [
					"type": "screenshots",
					"attributes": [
						"reason":source.rawValue
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
