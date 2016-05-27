//
//  Audio.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/22/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation
import Cocoa

class AudioInfo {
    var id: UInt
    var owner_id: Int
    var artist: String
    var title: String
    var duration: UInt
    var url: NSURL
    var lyrics_id: UInt?
    var album_id: UInt?
    
    init(id: UInt, owner_id: Int, artist: String, title: String, duration: UInt, url: NSURL, lyrics_id: UInt? = nil, album_id: UInt? = nil) {
        self.id = id
        self.owner_id = owner_id
        self.artist = artist
        self.title = title
        self.duration = duration
        self.url = url
        self.lyrics_id = lyrics_id
        self.album_id = album_id
    }
}

class Audio {
    private var info: AudioInfo
    
    var image: NSImage?
    
    var artist: String {
        get {
            return info.artist
        }
    }
    
    var title: String {
        get {
            return info.title
        }
    }
    
    var duration: String {
        get {
            return "\(info.duration/60):\(info.duration % 60)"
        }
    }
    
    init(info: AudioInfo) {
        self.info = info
    }
}
