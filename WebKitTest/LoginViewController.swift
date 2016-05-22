//
//  ViewController.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/16/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa
import WebKit

class LoginViewController: NSViewController, WebFrameLoadDelegate {
    @IBOutlet weak var webView: WebView!

    var token = ""
    var expiresIn = ""
    var userId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Don't save history.
        webView.setMaintainsBackForwardList(false)
        webView.frameLoadDelegate = self
        
        if let URL = AuthenticationParams.AuthRequest {
            print(URL)
            let req = NSURLRequest(URL: URL)
            webView.mainFrame.loadRequest(req)
        } else {
            NSLog("Malformed login request")
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPlayerSegue" {
            if let destination = segue.destinationController as? PlayerViewController {
                destination.token = token
                destination.expiresIn = expiresIn
                destination.userId = userId
            }
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        //print(sender.mainFrameURL)
        
        // API errors are represented via query.
        if sender.mainFrameURL.hasPrefix(AuthenticationParams.RedirectUri + "?") {
            handleError(sender.mainFrameURL)
        } else if sender.mainFrameURL.hasPrefix(AuthenticationParams.RedirectUri + "#") {
            handleLogin(sender.mainFrameURL)
        }
    }
    
    private func handleError(url: String) {
        NSLog("Error logging in: \(url)")
    }
    
    private func handleLogin(url: String) {
        let urlCpy = url.stringByReplacingOccurrencesOfString(AuthenticationParams.RedirectUri, withString: "")
        
        do {
            let regex = try NSRegularExpression(pattern: "#access_token=([a-zA-Z0-9]+)&expires_in=([0-9]+)&user_id=([0-9]+)", options: .CaseInsensitive)
            if let match = regex.firstMatchInString(urlCpy, options: .Anchored, range: NSMakeRange(0, urlCpy.characters.count)) {
                var range = match.rangeAtIndex(1)
                token = (urlCpy as NSString).substringWithRange(range)
                
                range = match.rangeAtIndex(2)
                expiresIn = (urlCpy as NSString).substringWithRange(range)
                
                range = match.rangeAtIndex(3)
                userId = (urlCpy as NSString).substringWithRange(range)
                
                print("Token: \(token), expires in: \(expiresIn), user ID: \(userId)")
                
                // UI should be performed on main thread.
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("showPlayerSegue", sender: self)
                }
            } else {
                NSLog("Unable to parse login string: \(urlCpy)")
            }
        } catch {
            NSLog("Error creating regex for login string: \(error)")
        }
    }
}

