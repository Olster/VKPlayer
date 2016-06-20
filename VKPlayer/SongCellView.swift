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
            let hours = duration/3600
            let mins = (duration/60) % 60
            let secs = duration % 60
            
            let value = hours != 0 ? String(format: "%02d:%02d:%02d", hours, mins, secs) : String(format: "%d:%02d", mins, secs)
            durationField.stringValue = value
        }
    }
}
