//
//  ViewController.swift
//  VKPlayer
//
//  Created by Pavlo Denysiuk on 5/16/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa
import WebKit

protocol LoginProtocol {
    func loginSucceeded(token: String, expiresIn: String, userID: String)
    func loginFailed(url: String)
}

class LoginViewController: NSViewController, WebFrameLoadDelegate {
    @IBOutlet weak var webView: WebView!
    
    var delegate: LoginProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Don't save history.
        webView.setMaintainsBackForwardList(false)
        webView.frameLoadDelegate = self
        
        if let URL = AuthenticationParams.AuthRequest {
            let req = NSURLRequest(URL: URL)
            webView.mainFrame.loadRequest(req)
        } else {
            NSLog("Malformed login request")
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        // API errors are represented via query.
        if sender.mainFrameURL.hasPrefix(AuthenticationParams.RedirectUri + "?") {
            handleError(sender.mainFrameURL)
        } else if sender.mainFrameURL.hasPrefix(AuthenticationParams.RedirectUri + "#") {
            handleLogin(sender.mainFrameURL)
        }
    }
    
    private func handleError(url: String) {
        delegate?.loginFailed(url)
    }
    
    private func handleLogin(url: String) {
        let urlCpy = url.stringByReplacingOccurrencesOfString(AuthenticationParams.RedirectUri, withString: "")
        
        do {
            let regex = try NSRegularExpression(pattern: "#access_token=([a-zA-Z0-9]+)&expires_in=([0-9]+)&user_id=([0-9]+)", options: .CaseInsensitive)
            if let match = regex.firstMatchInString(urlCpy, options: .Anchored, range: NSMakeRange(0, urlCpy.characters.count)) {
                var range = match.rangeAtIndex(1)
                let token = (urlCpy as NSString).substringWithRange(range)
                
                range = match.rangeAtIndex(2)
                let expiresIn = (urlCpy as NSString).substringWithRange(range)
                
                range = match.rangeAtIndex(3)
                let userId = (urlCpy as NSString).substringWithRange(range)
                
                dismissController(self)
                delegate?.loginSucceeded(token, expiresIn: expiresIn, userID: userId)
            } else {
                NSLog("Unable to parse login string: \(urlCpy)")
            }
        } catch {
            NSLog("Error creating regex for login string: \(error)")
        }
    }
}

