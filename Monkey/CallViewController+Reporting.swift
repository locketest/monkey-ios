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
        var message = "the last call"
        if self.chatSession?.status == .connected {
            if !self.screenshotForReport() {
                print("Failed to take screenshot")
                return
            }
            message = "this user"
        }
        guard let reportImage = self.reportImage else {
            print("Error: No image available")
            return
        }
        guard let chatId = self.reportChatId else {
            print("Error: No chat id available")
            return
        }
        
        guard let imageData = UIImageJPEGRepresentation(reportImage, 0.1) else {
            print("Error: Could not generate image data")
            return
        }
        
        let url = "\(Environment.baseURL)/api/v1.2/reports"
        
        let headers: HTTPHeaders = [
            "Authorization": APIController.authorization!, // Only authorized users can access MainViewController.
            "Accept": "application/json"
        ]
        
        self.callDelegate?.stopFindingChats(andDisconnect: false, forReason: "reporting")
        let alert = UIAlertController(title: "Are you sure you'd like to report \(message)?", message: APIController.shared.currentExperiment?.report_warning_text ?? "Your account will be disabled if you falsely report a user.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "🔞  Person is nude", style: .default, handler: {
            (UIAlertAction) in
            let reason = ReportType.nudity
            let parameters: Parameters = [
                "data": [
                    "type": "reports",
                    "attributes": [
                        "chat_id": chatId,
                        "reason": reason.rawValue,
                    ]
                ]
            ]
            self.sendReport(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, imageData: imageData)
        }))
        alert.addAction(UIAlertAction(title: "👊 Person has drugs or weapon", style: .default, handler: {
            (UIAlertAction) in
            let reason = ReportType.drugsOrWeapon
            let parameters: Parameters = [
                "data": [
                    "type": "reports",
                    "attributes": [
                        "chat_id": chatId,
                        "reason": reason.rawValue,
                    ]
                ]
            ]
            self.sendReport(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, imageData: imageData)
        }))
        //Previously violence
        alert.addAction(UIAlertAction(title: "😷 Person is mean or bullying", style: .default, handler: {
            (UIAlertAction) in
            let reason = ReportType.meanOrBully
            let parameters: Parameters = [
                "data": [
                    "type": "reports",
                    "attributes": [
                        "chat_id": chatId,
                        "reason": reason.rawValue,
                    ]
                ]
            ]
            self.sendReport(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, imageData: imageData)
        }))
        
        alert.addAction(UIAlertAction(title: "👴 Person has fake age/gender", style: .default, handler: {
            (UIAlertAction) in
            let reason = ReportType.ageOrGender
            let parameters: Parameters = [
                "data": [
                    "type": "reports",
                    "attributes": [
                        "chat_id": chatId,
                        "reason": reason.rawValue,
                    ]
                ]
            ]
            self.sendReport(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, imageData: imageData)
        }))
        
        alert.addAction(UIAlertAction(title: "❓ Person did something else", style: .default, handler: {
            (UIAlertAction) in
            let reason = ReportType.other
            let parameters: Parameters = [
                "data": [
                    "type": "reports",
                    "attributes": [
                        "chat_id": chatId,
                        "reason": reason.rawValue,
                    ]
                ]
            ]
            self.sendReport(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, imageData: imageData)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (UIAlertAction) in
           self.callDelegate?.startFindingChats(forReason: "reporting")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
//    func takeScreenshot() {
//        guard Achievements.shared.secretScreenshotAbility == true else {
//            return
//        }
//        guard let subscriberView = self.chatSession?.subscriber?.view else {
//            return
//        }
//        self.policeButton.isHidden = true
//        hideStatusBarForScreenshot = true
//        guard let screenCapture = subscriberView.snapshotView(afterScreenUpdates: true) else {
//            return
//        }
//        self.containerView.addSubview(screenCapture)
//        UIGraphicsBeginImageContextWithOptions(subscriberView.bounds.size, false, UIScreen.main.scale)
//        view.drawHierarchy(in: subscriberView.bounds, afterScreenUpdates: true)
//        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
//            UIGraphicsEndImageContext()
//            screenCapture.removeFromSuperview()
//            return
//        }
//        UIGraphicsEndImageContext()
//        screenCapture.removeFromSuperview()
//
//        self.policeButton.isHidden = false
//        hideStatusBarForScreenshot = false
//        guard let snapchatShareVC = SLComposeViewController(forServiceType: "com.toyopagroup.picaboo.share") else {
//            print("Couldn't open share extension")
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//            return
//        }
//       self.callDelegate?.stopFindingChats(andDisconnect: false, forReason: "snapchat-sharing")
//
//        snapchatShareVC.completionHandler = { (SLComposeViewControllerResult) in
//           self.callDelegate?.startFindingChats(forReason: "snapchat-sharing")
//        }
//        snapchatShareVC.add(image)
//        self.present(snapchatShareVC, animated: true, completion: nil)
//    }
    
    func autoScreenShotUpload(source:AutoScreenShotType) {
        if let ban = APIController.shared.currentUser?.is_banned.value {
            if ban == true {return}
        }
        
        if (Date().timeIntervalSince1970 - CallViewController.lastScreenShotTime) < 30 {
            print("scst- source:\(source.rawValue) fail - time not arrive")
            return
        }
        
        if let gender = APIController.shared.currentUser?.gender {
            if gender == "female"{
                return
            }else if (arc4random() % UInt32(2)) == 1{
                return
            }
        }
        
        if let age = APIController.shared.currentUser?.age.value , (age <= 17 &&
            ((arc4random() % 100) > (RemoteConfigManager.shared.moderation_age_reduce))) {
            return
        }
        
        
        if  let hour = Date.init().component(.hour),
            hour > 8 && hour < 20,
            ( arc4random() % 100) > (RemoteConfigManager.shared.moderation_non_peak) {
            return
        }
        
        
        
        if  let myGender = APIController.shared.currentUser?.gender,
            let otherGender = self.chatSession?.realmCall?.user?.gender,
            myGender == "male" && otherGender == "male",
            (arc4random() % 100) > (RemoteConfigManager.shared.moderation_gender_match) {
            return
        }
        
        print("scst- source:\(source.rawValue)")
        
        if !self.screenShotForSelf() {
            print("Failed to take screenshot")
            return
        }
        guard let reportImage = self.reportImage else {
            print("Error: No image available")
            return
        }
//        guard let chatId = self.reportChatId else {
//            print("Error: No chat id available")
//            return
//        }
        
        guard let imageData = UIImageJPEGRepresentation(reportImage, 0.1) else {
            print("Error: Could not generate image data")
            return
        }
        
        let url = "\(Environment.baseURL)/api/v1.3/screenshot"
        
        let headers: HTTPHeaders = [
            "Authorization": APIController.authorization!, // Only authorized users can access MainViewController.
            "Accept": "application/json"
        ]
        
        let parameters: Parameters = [
            "data": [
                "type": "screenshots",
                "attributes": [
//                    "chat_id": chatId,
                    "reason":source.rawValue
                ]
            ]
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { (response) in
                
                if let error = response.result.error {
                    print("scst- upload error :\(error)")
                    return
                }
                
                if response.response!.statusCode >= 400  {
                    print("scst- upload fail status code : \(response.response!.statusCode)")
                    return
                }
                
                if response.result.isSuccess == false {return}
                
                let data = (response.result.value as! Dictionary<String, Any>)["data"] as! Dictionary<String, Any>
                let attributes = data["attributes"] as! Dictionary<String, Any>
                
                print(response)
                
                //    open func upload(_ data: Data, to url: URLConvertible, method: Alamofire.HTTPMethod = default, headers: HTTPHeaders? = default) -> Alamofire.UploadRequest
                if let uploadURL = attributes["upload_url"] as? String {
                    self.uploadReportImage(imageData, to: uploadURL,needShowAlert: false)
                }
        }
    }
    
    func screenshotForReport() -> Bool {
        guard let subscriberView = self.chatSession?.subscriber?.view else {
            print("Nothing to report")
            return false
        }
        guard let chatId = self.chatSession?.chat?.chatId else {
            print("Chat not available")
            return false
        }
        
        self.reportChatId = chatId
        self.policeButton.isHidden = true
        self.addMinuteButton.isHidden = true
        self.snapchatButton.isHidden = true
        self.statusCornerView.isHidden = true
        self.chatSession?.subscriber?.view?.effectsEnabled = false
        for view in self.containerView.subviews {
            if let label = view as? UILabel {
                if(label.tag == 71074){
                    label.isHidden = true
                }
            }
        }
        self.hideStatusBarForScreenshot = true
        guard let screenCapture = subscriberView.snapshotView(afterScreenUpdates: true) else {
            unhideAfterReportScreenshot()
            return false
        }
        self.containerView.addSubview(screenCapture)
        UIGraphicsBeginImageContextWithOptions(subscriberView.bounds.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: subscriberView.bounds, afterScreenUpdates: true)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            screenCapture.removeFromSuperview()
            return false
        }
        self.reportImage = image
        UIGraphicsEndImageContext()
        screenCapture.removeFromSuperview()
        unhideAfterReportScreenshot()
        
        return true
    }
    
    func screenShotForSelf() -> Bool{
        let capV = MonkeyPublisher.shared.view
        
//        UIGraphicsBeginImageContext(self.view.bounds.size)
//
//        guard let context = UIGraphicsGetCurrentContext() else {
//            print("screen shot get context fail")
//            return false
//        }
//
//        screenCapture.layer.render(in: context)
//        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
//            print("screen shot fail")
//            return false
//        }
        
        self.policeButton.isHidden = true
        let addMinuteBtnCenter = self.addMinuteButton.center
        let snapchatBtnCenter = self.snapchatButton.center
        self.addMinuteButton.center = CGPoint(x:-200,y:-200)
        self.snapchatButton.center = CGPoint(x:-200,y:-200)
        self.clockLabelBackgroundView.isHidden = true
        
        self.isPublisherViewEnlarged = true
        self.publisherContainerViewTopConstraint.constant = 0
        self.publisherContainerViewHeightConstraint.constant = self.view.frame.size.height
        
        self.chatSession?.subscriber?.view?.effectsEnabled = false

        self.hideStatusBarForScreenshot = true
        guard let screenCapture = capV.snapshotView(afterScreenUpdates: true) else {
            unhideAfterReportScreenshot()
            self.addMinuteButton.center = addMinuteBtnCenter
            self.snapchatButton.center = snapchatBtnCenter
            return false
        }
        self.containerView.addSubview(screenCapture)

        UIGraphicsBeginImageContextWithOptions(capV.frame.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: capV.frame, afterScreenUpdates: true)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            screenCapture.removeFromSuperview()
            return false
        }
        
        // FIXME: there is a yellow view below capV will draw in screen shot , fix it
        self.reportImage = image
        self.isPublisherViewEnlarged = false
        screenCapture.removeFromSuperview()
        unhideAfterReportScreenshot()
        self.addMinuteButton.center = addMinuteBtnCenter
        self.snapchatButton.center = snapchatBtnCenter
        self.clockLabelBackgroundView.isHidden = false
        
        return true
    }
    
    func sendReport(_ url: URLConvertible, method: HTTPMethod, parameters: Parameters, encoding: ParameterEncoding, headers: HTTPHeaders, imageData: Data) {
        if let subscriberView = self.chatSession?.subscriber?.view {
            
            // add blur after take screen shot
            let eff = UIBlurEffect.init(style: .light)
            let blurV = UIVisualEffectView.init(effect: eff)
            blurV.frame = self.view.bounds
            subscriberView.addSubview(blurV)
        }
		
		self.chatSession?.isReportedChat = true
        self.chatSession?.sentReport()
		
		if let addedTime = self.chatSession?.hadAddTime, let friendMatch = self.chatSession?.friendMatched, addedTime == false, friendMatch == false {
			//  open pixel effect and cant close anymore
			HWCameraManager.shared().addPixellate()
		}
		
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
            self.callDelegate?.startFindingChats(forReason: "reporting")
        }
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            if let error = response.result.error {
                let alert = UIAlertController(title: "Report Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    (UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: {
                    (UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                    self.sendReport(url, method: method, parameters: parameters, encoding: encoding, headers: headers, imageData: imageData)
                }))
                self.present(alert, animated: true, completion: nil)
                return;
            }
            
            if response.response!.statusCode >= 400  {
                let alert = UIAlertController(title: "Error", message: (response.result.value as! Dictionary<String, Array<Dictionary<String, Any>>>)["errors"]?[0]["title"] as? String, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    (UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: {
                    (UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                    self.sendReport(url, method: method, parameters: parameters, encoding: encoding, headers: headers, imageData: imageData)
                }))
                self.present(alert, animated: true, completion: nil)
                return;
            }
            
            let data = (response.result.value as! Dictionary<String, Any>)["data"] as! Dictionary<String, Any>
            let attributes = data["attributes"] as! Dictionary<String, Any>
            
            //    open func upload(_ data: Data, to url: URLConvertible, method: Alamofire.HTTPMethod = default, headers: HTTPHeaders? = default) -> Alamofire.UploadRequest
            if let uploadURL = attributes["upload_url"] as? String {
                self.uploadReportImage(imageData, to: uploadURL,needShowAlert: true)
            }
        }
    }
    
    func uploadReportImage(_ imageData: Data, to url: URLConvertible,needShowAlert need:Bool) {
        Alamofire.upload(imageData, to: url, method: .put, headers: ["Content-Type": "image/jpeg"])
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success:
                    CallViewController.lastScreenShotTime = Date().timeIntervalSince1970
                    print("scst- Validation Successful - url : \(url)")
                case .failure(let error):
                    if need {
                        let alert = UIAlertController(title: "Fatal Report Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                            (UIAlertAction) in
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: {
                            (UIAlertAction) in
                            alert.dismiss(animated: true, completion: nil)
                            self.uploadReportImage(imageData, to: url,needShowAlert: need)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                    return;
                }
        }
    }
}
