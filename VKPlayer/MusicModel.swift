//
//  MusicModel.swift
//  VKPlayer
//
//  Created by Pavlo Denysiuk on 6/3/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation

protocol MusicModelDelegate {
    func loadMusicInfoFailed(error: NSError)
    func loadMusicInfoSucceded()
}

class MusicModel {
    private let userID: String
    private let token: String
    private let expiresIn: String
    
    private var audios = [Audio]()
    private let audiosLock = NSLock()
    
    var delegate: MusicModelDelegate?
    
    private let ERROR_DOMAIN = "MusicModelErrorDomain"
    enum Error: Int {
        case InvalidLink
        case RequestFailed
    }
    
    required init(userID: String, token: String, expiresIn: String) {
        self.userID = userID
        self.token = token
        self.expiresIn = expiresIn
    }
    
    var songCount: Int {
        audiosLock.lock()
        let val = audios.count
        audiosLock.unlock()
        return val
    }
    
    func loadMusicInfo() {
        let urlLink = "https://api.vk.com/method/audio.get?owner_id=\(userID)&access_token=\(token)&v=\(AuthenticationParams.API_VERSION)&https=1"
        guard let endpoint = NSURL(string: urlLink) else {
            let err = NSError(domain: ERROR_DOMAIN, code: Error.InvalidLink.rawValue, userInfo: ["URL": urlLink])
            delegate?.loadMusicInfoFailed(err)
            return
        }
        
        let request = NSMutableURLRequest(URL: endpoint)
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: musicInfoRequestHandler).resume()
    }
    
    private func musicInfoRequestHandler(data: NSData?, response: NSURLResponse?, err: NSError?) {
        if err != nil {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.loadMusicInfoFailed(err!)
            }
            return
        }
        
        if data == nil || response == nil {
            let err = NSError(domain: ERROR_DOMAIN, code: Error.RequestFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: "No response received"])
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.loadMusicInfoFailed(err)
            }
            return
        }
        
        let json = JSON(data: data!)
        guard let audioInfoItems = json["response"]["items"].array else {
            let err = NSError(domain: ERROR_DOMAIN, code: Error.RequestFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: "Received JSON doesn't have audio items: \(json)"])
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.loadMusicInfoFailed(err)
            }
            return
        }
        
        var tempAudios = [Audio]()
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
        
        audiosLock.lock()
        audios = tempAudios
        audiosLock.unlock()
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.loadMusicInfoSucceded()
        }
    }
    
    func audioAt(index: Int) -> Audio {
        audiosLock.lock()
        let audio = audios[index]
        audiosLock.unlock()
        return audio
    }
    
    func providePlayableAt(index: Int, handler: (Audio?, NSURL?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if index >= self.audios.count {
                dispatch_async(dispatch_get_main_queue()) {
                    handler(nil, nil)
                }
                return
            }
            
            self.audiosLock.lock()
            let audio = self.audios[index]
            self.audiosLock.unlock()
            
            let fileManager = NSFileManager.defaultManager()
            let cachesDir = fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
            let bundleID = NSBundle.mainBundle().bundleIdentifier ?? "VKPlayer"
            
            // ~/Library/Caches/<bundle_id>/song.ext
            let fileName = cachesDir.absoluteURL.URLByAppendingPathComponent(bundleID).URLByAppendingPathComponent("\(audio.id).\(audio.url.pathExtension!)")
            if fileManager.fileExistsAtPath(fileName.path!) {
                dispatch_async(dispatch_get_main_queue()) {
                    handler(audio, fileName)
                }
            } else {
                let downloadTask = NSURLSession.sharedSession().downloadTaskWithURL(audio.url) { (downloadedUrl, response, err) in
                    guard downloadedUrl != nil && err == nil else {
                        NSLog("Download task failed for \(audio.url). Error: \(err)")
                        handler(nil, nil)
                        return
                    }
                    
                    do {
                        try fileManager.moveItemAtURL(downloadedUrl!, toURL: fileName)
                        dispatch_async(dispatch_get_main_queue()) {
                            handler(audio, fileName)
                        }
                    } catch {
                        NSLog("Error moving downloaded audio: \(error)")
                    }
                }
                
                downloadTask.resume()
            }
        }
    }
}