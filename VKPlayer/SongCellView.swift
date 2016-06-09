//
//  SongCellView.swift
//  VKPlayer
//
//  Created by Pavlo Denysiuk on 6/2/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

class SongCellView: NSTableCellView {
    @IBOutlet weak var artistTitleField: NSTextField! {
        didSet {
            updateArtistTitle()
        }
    }
    
    @IBOutlet weak var durationField: NSTextField! {
        didSet {
            updateDuration()
        }
    }
    
    var artistTitle = "" {
        didSet {
            updateArtistTitle()
        }
    }
    
    var duration: UInt = 0 {
        didSet {
            updateDuration()
        }
    }
    
    private func updateArtistTitle() {
        if artistTitleField != nil {
            artistTitleField.stringValue = artistTitle
        }
    }
    
    private func updateDuration() {
        if durationField != nil {
            var mins = duration/60
            let hours = mins/60
            if hours != 0 {
                mins = mins % 60
            }
            
            let secs = duration % 60
            
            let value = hours != 0 ? "\(hours):\(mins):\(secs)" : "\(mins):\(secs)"            
            durationField.stringValue = value
        }
    }
}
