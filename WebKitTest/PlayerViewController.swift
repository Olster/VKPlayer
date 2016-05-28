//
//  PlayerViewController.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/18/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, LoginProtocol {
    var token = ""
    var expiresIn = ""
    var userId = ""
    
    var audios = [Audio]()
    let player = AVPlayer()

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
            text = audio.durationString
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
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        // Don't care about removing selection.
        if songTable.numberOfSelectedRows > 0 {
            let selectedAudio = audios[songTable.selectedRow]
            play(selectedAudio)
        }
    }
    
    private func play(audio: Audio) {
        let url = audio.url
        
        let fileManager = NSFileManager.defaultManager()
        let cachesDir = fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
        
        let fileName = cachesDir.absoluteURL.URLByAppendingPathComponent("\(audio.id).\(url.pathExtension!)")
        if fileManager.fileExistsAtPath(fileName.path!) {
            playNewSong(fileName)
        } else {
            loadingIndicator.startAnimation(self)
            let downloadTask = NSURLSession.sharedSession().downloadTaskWithURL(url) { (downloadedUrl, response, err) in
                dispatch_async(dispatch_get_main_queue()) {
                    self.loadingIndicator.stopAnimation(self)
                }
                
                guard downloadedUrl != nil && err == nil else {
                    NSLog("Download task failed for \(url). Error: \(err)")
                    return
                }
                
                do {
                    try fileManager.moveItemAtURL(downloadedUrl!, toURL: fileName)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.playNewSong(fileName)
                    }
                } catch {
                    NSLog("Error moving downloaded audio: \(error)")
                }
            }
            
            downloadTask.resume()
        }
    }
    
    private func playNewSong(fileName: NSURL) {
        let asset = AVAsset(URL: fileName)
        guard asset.playable else {
            NSLog("Asset isn't playable! \(asset)")
            return
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        player.pause()
        player.rate = 0
        player.replaceCurrentItemWithPlayerItem(playerItem)
        player.play()
    }
    
    func loginSucceeded(token: String, expiresIn: String, userID: String) {
        print("Login successful")
        
        self.token = token
        self.expiresIn = expiresIn
        self.userId = userID
        
        loadMusicInfo()
    }
    
    func loginFailed(url: String) {
        NSLog("Error logging in: \(url)")
    }
    
    private func loadMusicInfo() {
        let urlLink = "https://api.vk.com/method/audio.get?owner_id=\(userId)&access_token=\(token)&v=\(AuthenticationParams.API_VERSION)&https=1"
        guard let endpoint = NSURL(string: urlLink) else {
            NSLog("'\(urlLink)' is invalid")
            return
        }
        
        let request = NSMutableURLRequest(URL: endpoint)
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: musicInfoRequestHandler).resume()
    }
    
    private func musicInfoRequestHandler(data: NSData?, response: NSURLResponse?, err: NSError?) {
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
        //print(json)
        
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
            
            tempAudios.append(Audio(id: audioID, owner_id: ownerID, artist: artist, title: title, duration: duration, url: url, lyrics_id: lyricsID, album_id: albumID))
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.audios = tempAudios
            self.loadingIndicator.stopAnimation(self)
            self.songTable.reloadData()
        }
    }
}
