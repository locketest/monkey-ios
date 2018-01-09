//
//  FacebookViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/19/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Alamofire
import FBSDKLoginKit

class FacebookViewController: UIViewController, UIWebViewDelegate {
    let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:41.0) Gecko/20100101 Firefox/41.0"
    var ids = Array<String>()
    let appId = APIController.shared.currentExperiment?.facebook_app_id ?? "533037640057671"
    var token = ""
    var webView = UIWebView()
    var invitesSent = 0
    let manager = FBSDKLoginManager()
    weak var delegate:FacebookViewControllerDelegate?
    let redirectURL = APIController.shared.currentExperiment?.facebook_redirect_url ?? "https://monkey.cool"
    var sentInvites = 0
    
    override func viewDidLoad() {
        self.webView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.webView.isHidden = true
        self.view.addSubview(webView)
        FBSDKSettings.setAppID(appId)
    }
    
    func login(controller: UIViewController) {
        manager.logOut()
       // Achievements.shared.facebookVC = self
        manager.loginBehavior = .browser
        FBSDKSettings.setAppID(appId)
        manager.logIn(withReadPermissions: ["public_profile", "user_friends", "email"], from: controller) {
            (result: FBSDKLoginManagerLoginResult?, error: Error?) in
            self.delegate?.loginCompleted(facebookViewController: self)
            // if login fails (facebook's fault) or there is a token (facebook login worked), track the event.
            if error != nil || result?.token?.tokenString != nil {
                AnaliticsCenter.log(withEvent: .loggedInWithFacebook, andParameter: [
                    "via": "bonus_bananas",
                    "success": error == nil,
                    ])
            }
            if let error = error {
                print("Login error", error)
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            self.updateAchievement()
            
            if let token = result?.token?.tokenString {
                self.token = token
                DispatchQueue.global(qos: .background).async {
                    self.getInvitableFriends()
                }
            }
        }
    }
    
    func getInvitableFriends() {
        let inviteURL = "https://www.facebook.com/dialog/apprequests?display=popup&redirect_uri=\(redirectURL)&access_token=\(token)&app_id=\(appId)&message=yo%20download%20monkey"
        Alamofire
            .request(inviteURL, method: .get, headers: [
                "User-Agent": userAgent
            ] as HTTPHeaders)
            .validate(statusCode: 200...200)
        .responseString { (response) in
            if let data = response.result.value {
                // (?<=first_degree\.php\?)(.*?)(?=")
                // (?<=ids\":\[)(.*?)(?=],\")
                let base64String = "KD88PXByZWxvYWRfZGF0YSI6XHsiaWRzIjpcWykoLio/KSg/PV0sIik="
                guard let stringData = Data.init(base64Encoded: base64String) else {
                    return
                }
                guard let regexString = String(data: stringData, encoding: .utf8) else {
                    return
                }
                
                let queryStringRegex = try! NSRegularExpression(pattern: regexString, options: [])
                let matches = queryStringRegex.matches(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count)) 
                if let match = matches.first {
                    let range = match.rangeAt(1)
                    if let swiftRange = range.range(for: data) {
                        let friendIds = data.substring(with: swiftRange)
                        
                        self.ids = friendIds.components(separatedBy: ",")
                        self.webView.delegate = self
                        self.updateInvitedFriendsCount()
                        self.sendSomeInvites()
                        return
                    }
                }
            }
        }
    }
    
    func sendSomeInvites() {
        guard let idsCSV = self.ids[0..<min(self.ids.count, 50)].joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?.replacingOccurrences(of: "%22", with: "") else {
            return
        }
        
        let urlString = "https://www.facebook.com/dialog/apprequests?display=popup&redirect_uri=\(redirectURL)&access_token=\(token)&app_id=\(appId)&message=yo%20download%20monkey&to=\(idsCSV)"
        print("url: ", urlString)
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        webView.loadRequest(request)
        sentInvites += min(self.ids.count, 50)
        self.ids = Array(self.ids.dropFirst(50))
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // document.getElementsByName("__CANCEL__")[0]
        webView.stringByEvaluatingJavaScript(from: "setTimeout(function() { document.getElementsByName(\"__CONFIRM__\")[0].click() }, 1000)")
        print("Sent \(sentInvites) invites, \(self.ids.count) remaining")
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Load error: \(error)")
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        print("starting facebook load")
    }
    
    func updateInvitedFriendsCount() {
        let inviteCount = self.ids.count
        
        guard let currentUser = APIController.shared.currentUser else {
            return
        }
		AnaliticsCenter.log(withEvent: .invitedFacebookFriends, andParameter: [
			"count": inviteCount
			])

        print("Updating user attribute `facebook_friends_invited` to value \(inviteCount)")
        currentUser.update(attributes: [.facebook_friends_invited(inviteCount)]) { (error:APIError?) in
            guard error == nil else {
                error?.log()
                return
            }
            
            print("User updated `facebook_friends_invited`")
        }
    }
    
    func updateAchievement() {
        Achievements.shared.authorizedFacebookForBonusBananas = true
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let redirectHost = URL(string: redirectURL)?.host
        if request.url?.host == redirectHost {
            if (self.ids.count > 0) {
                self.sendSomeInvites()
                return false
            }
            else {
                self.delegate?.invitesCompleted(facebookViewController: self)
            }
            
            return false
        }
        return true
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
protocol FacebookViewControllerDelegate:class {
    func loginCompleted(facebookViewController: FacebookViewController)
    func invitesCompleted(facebookViewController: FacebookViewController)
}
extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        
        return fromIndex ..< toIndex
    }
}
