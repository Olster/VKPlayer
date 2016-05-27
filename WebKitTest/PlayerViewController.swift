//
//  PlayerViewController.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/18/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

class PlayerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, LoginProtocol {
    var token = ""
    var expiresIn = ""
    var userId = ""
    
    var audios = [Audio]()

    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var songTable: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        loadingIndicator.startAnimation(self)
    }
    
    override func viewDidAppear() {
        performSegueWithIdentifier("loginSegue", sender: self)
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginSegue" {
            if let dest = segue.destinationController as? LoginViewController {
                dest.delegate = self
            }
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return audios.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let audio = audios[row]
        
        var cellID = ""
        var text = ""
        var image: NSImage? = nil
        
        if tableColumn == tableView.tableColumns[0] {
            // Album art
            image = audio.image
            cellID = "artCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            // Artist
            text = audio.artist
            cellID = "artistCellID"
        } else if tableColumn == tableView.tableColumns[2] {
            // Title
            text = audio.title
            cellID = "titleCellID"
        } else if tableColumn == tableView.tableColumns[3] {
            // Duration
            text = audio.duration
            cellID = "durationCellID"
        } else {
            return nil
        }
        
        if let view = tableView.makeViewWithIdentifier(cellID, owner: self) as? NSTableCellView {
            view.textField?.stringValue = text
            view.imageView?.image = image
            return view
        }
        
        return nil
    }
    
    func loginSucceeded(token: String, expiresIn: String, userID: String) {
        print("Login successful")
        
        self.token = token
        self.expiresIn = expiresIn
        self.userId = userID
        
        loadMusicInfo()
        
        loadingIndicator.stopAnimation(self)
        for i in 1...15 {
            let a = AudioInfo(id: UInt(i), owner_id: i, artist: "Artist \(i)", title: "Title \(i)", duration: UInt(i), url: NSURL(string: "\(i)")!)
            let audio = Audio(info: a)
            audio.image = NSApp.applicationIconImage
            audios.append(audio)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.songTable.reloadData()
        }
    }
    
    func loginFailed() {
        
    }
    
    private func loadMusicInfo() {
        let urlLink = "https://api.vk.com/method/audio.get?owner_id=\(userId)&access_token=\(token)&v=\(AuthenticationParams.API_VERSION)&https=1"
        guard let endpoint = NSURL(string: urlLink) else {
            NSLog("'\(urlLink)' is invalid")
            return
        }
        
        let request = NSMutableURLRequest(URL: endpoint)
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: requestHandler).resume()
    }
    
    private func requestHandler(data: NSData?, response: NSURLResponse?, err: NSError?) {
        if err != nil {
            NSLog(err!.description)
            return
        }
        
        if data == nil || response == nil {
            NSLog("No response")
            return
        }
        
        // I could either lock existing audios, or create a temp variable to resolve
        // race condition.
        var tempAudios = [Audio]()
        
        let json = JSON(data: data!)
        print(json)
        
        guard let audioInfoItems = json["response"]["items"].array else {
            NSLog("Received JSON doesn't have audio items: \(json)")
            return
        }
        
        for item in audioInfoItems {
            guard let audioID = item["id"].uInt else {
                NSLog("Item doesn't have an ID: \(item)")
                return
            }
            
            guard let ownerID = item["owner_id"].int else {
                NSLog("Item doesn't have an owner ID: \(item)")
                return
            }
            
            guard let artist = item["artist"].string else {
                NSLog("Item doesn't have an artist")
                return
            }
            
            guard let title = item["title"].string else {
                NSLog("Item doesn't have a title: \(item)")
                return
            }
            
            guard let duration = item["duration"].uInt else {
                NSLog("Item doesn't have a duration: \(item)")
                return
            }
            
            guard let url = item["url"].URL else {
                NSLog("Item doesn't have a url: \(item)")
                return
            }
            
            let lyricsID = item["lyrics_id"].uInt
            let albumID = item["album_id"].uInt
            
            let audioInfo = AudioInfo(id: audioID, owner_id: ownerID, artist: artist, title: title, duration: duration, url: url, lyrics_id: lyricsID, album_id: albumID)
            
            tempAudios.append(Audio(info: audioInfo))
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.audios = tempAudios
            self.loadingIndicator.stopAnimation(self)
            self.songTable.reloadData()
        }
    }
}
