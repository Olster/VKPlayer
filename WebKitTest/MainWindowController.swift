//
//  MainWindowController.swift
//  WebKitTest
//
//  Created by Pavlo Denysiuk on 5/20/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .Hidden
    }

}
