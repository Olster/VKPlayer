//
//  Audio.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/22/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation
import Cocoa

class Audio {
    private(set) var id: UInt
    private(set) var owner_id: Int
    private(set) var artist: String
    private(set) var title: String
    private(set) var duration: UInt
    private(set) var url: NSURL
    private(set) var lyrics_id: UInt?
    private(set) var album_id: UInt?
    
    var image: NSImage?
    
    var durationString: String {
        get {
            return "\(duration/60):\(duration % 60)"
        }
    }
    
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
