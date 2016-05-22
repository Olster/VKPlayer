//
//  PlayerViewController.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/18/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

class Audio {
    var image: NSImage?
    var artist = ""
    var title = ""
    var duration = ""
    
    init(artist: String, title: String, duration: String, image: NSImage? = nil) {
        self.image = image
        self.artist = artist
        self.title = title
        self.duration = duration
    }
    
    convenience init() {
        self.init(artist: "[Unknown Artist]", title: "[Unknown Title]", duration: "[0:0]", image: nil)
    }
}

class PlayerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var token = ""
    var expiresIn = ""
    var userId = ""
    
    var audios = [Audio]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        for i in 1...15 {
            let a = Audio()
            a.image = NSApp.applicationIconImage
            a.duration = "\(i)"
            audios.append(a)
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
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationController as? LoginViewController {
            
        }
    }
}
