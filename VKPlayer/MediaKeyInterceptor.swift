//
//  MediaKeyInterceptor.swift
//  VKPlayer
//
//  Created by Pavlo Denysiuk on 6/20/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

struct MediaKeyNotifications {
    static let MediaKeyPlayPressed = "MediaKeyNotifications.MediaKeyPlayPressed"
    static let MediaKeyForwardPressed = "MediaKeyNotifications.MediaKeyForwardPressed"
    static let MediaKeyRewindPressed = "MediaKeyNotifications.MediaKeyRewindPressed"
}

class MediaKeyInterceptor: NSApplication {
    override func sendEvent(theEvent: NSEvent) {
        if theEvent.type == .SystemDefined && theEvent.subtype.rawValue == 8 {
            let keyCode = Int32((theEvent.data1 & 0xFFFF0000) >> 16)
            let keyFlags = theEvent.data1 & 0x0000FFFF
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
            
            handleMediaKey(keyCode, keyUp: keyState)
            return
        }
        
        super.sendEvent(theEvent)
    }
    
    private func handleMediaKey(key: Int32, keyUp: Bool) {
        switch key {
        case NX_KEYTYPE_PLAY:
            if keyUp {
                NSNotificationCenter.defaultCenter().postNotificationName(MediaKeyNotifications.MediaKeyPlayPressed, object: nil)
            }
            
        case NX_KEYTYPE_FAST:
            if keyUp {
                NSNotificationCenter.defaultCenter().postNotificationName(MediaKeyNotifications.MediaKeyForwardPressed, object: nil)
            }
            
        case NX_KEYTYPE_REWIND:
            if keyUp {
                NSNotificationCenter.defaultCenter().postNotificationName(MediaKeyNotifications.MediaKeyRewindPressed, object: nil)
            }
            
        default:
            break
        }
    }
}
