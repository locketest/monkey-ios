//
//  ResumeMyAccountViewController.swift
//  Monkey
//
//  Created by fank on 2018/5/29.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  撤销删除账号页

import UIKit

class ResumeMyAccountViewController: MonkeyViewController {
    
    var tempAuthorization : String!

    @IBOutlet weak var limitTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
    }

    @IBAction func btnClickFunc(_ sender: BigYellowButton) {
        switch sender.tag {
        case 1:
            self.resumeMyAccountFunc(sender)
        default:
            self.signOutFunc()
        }
    }
    
    func resumeMyAccountFunc(_ sender: BigYellowButton) {
        sender.isLoading = true
        JSONAPIRequest(url: "\(Environment.baseURL)/api/v1.3/accounts/me/resume", method: .post, options: [
            .header("Authorization", self.tempAuthorization),
            ]).addCompletionHandler {[weak self] (response) in
				sender.isLoading = false
                switch response {
                case .error(_):
                    break
                case .success(_):
                    
                    AnalyticsCenter.log(event: .resumeAccount)
                    
                    self?.signOutFunc()
                }
        }
    }
    
    func signOutFunc() {
        let rootVC = self.view.window?.rootViewController
        rootVC?.presentedViewController?.dismiss(animated: false, completion: {
            DispatchQueue.main.async {
                rootVC?.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func initLimitTimeLabelFunc() {
        
        if let timeStamp = APIController.shared.currentUser?.delete_at {
            
            let timeInterval = TimeInterval(timeStamp / 1000)
            let date = Date(timeIntervalSince1970: timeInterval)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            
            self.limitTimeLabel.attributedText = NSAttributedString(string: "Your account will be deleted on\n\(dateFormatter.string(from: date))", attributes: [NSParagraphStyleAttributeName:paragraphStyle])
            
            self.limitTimeLabel.textAlignment = .center
        }
    }
    
    func initView() {
        
        self.initLimitTimeLabelFunc()
        
        self.tempAuthorization = UserManager.authorization
        
        RealmDataController.shared.deleteAllData() { (_) in
			
        }
    }
}
