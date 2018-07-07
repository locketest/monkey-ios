//
//  InstagramAuthViewController.swift
//  Monkey
//
//  Created by mao PengLin on 2018/5/2.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import DeviceKit

protocol InstagramAuthDelegate: class{
    func authInstagramSuccess(code: String)
    func authInstagramFailure()
}

class InstagramAuthViewController: MonkeyViewController, UIWebViewDelegate {
    var webView: UIWebView!
    var indicator: UIActivityIndicatorView!
    var webURL: URL?
    var authDelegate: InstagramAuthDelegate?

    func isIphoneX() -> Bool {
        return Device() == Device.iPhoneX
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView = UIWebView.init(frame:self.view.bounds)
        self.webView.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleWidth.rawValue) | UInt8(UIViewAutoresizing.flexibleHeight.rawValue)))
        self.webView.delegate = self
        self.webView.isOpaque = false
        if self.isIphoneX(){
            self.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(88,0,0,0)
            self.webView.scrollView.contentInset = UIEdgeInsetsMake(88,0,0,0)
        }else{
            self.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64,0,0,0)
            self.webView.scrollView.contentInset = UIEdgeInsetsMake(64,0,0,0)
        }

        self.view.addSubview(self.webView)
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
        self.indicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        self.indicator.hidesWhenStopped = true
        self.indicator.center = self.view.center
        self.view.addSubview(self.indicator)
        self.webView.backgroundColor = UIColor.white
        self.webView.scrollView.backgroundColor = UIColor.white
        if self.webURL != nil{
            self.webView.loadRequest(URLRequest.init(url: self.webURL!))
        }
        self.title = "Instagram"
        let doneBtn = UIBarButtonItem.init(title: "🐒Complete", style: UIBarButtonItemStyle.done, target: self, action: #selector(authenticationFailure))

        doneBtn.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.init(red: 100.0/255.0, green: 74.0/255.0, blue: 241.0/255.0, alpha: 1.0)], for: UIControlState.normal)
        self.navigationItem.rightBarButtonItem = doneBtn
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.indicator.stopAnimating()
        self.webView.stopLoading()
    }
     func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        if let url = request.url{
            if (url.absoluteString.hasPrefix("monkey://instagram-login?code=")){
                self.authenticationSuccess(code: url.absoluteString.replacingFirstOccurrence(of: "monkey://instagram-login?code=", withString: ""))
            }else if url.absoluteString == "https://www.instagram.com/"{
                if self.webURL != nil {
                    self.webView.loadRequest(URLRequest.init(url:self.webURL!))
                }
            }
        }

        return true
    }
    func authenticationSuccess(code:String){
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.authDelegate?.authInstagramSuccess(code: code)
    }
    func authenticationFailure(){
        self.dismiss(animated: true, completion: nil)
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.authDelegate?.authInstagramFailure()
    }
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.indicator.startAnimating()
    }
     func webViewDidFinishLoad(_ webView: UIWebView) {
        self.indicator.stopAnimating()
    }

}
