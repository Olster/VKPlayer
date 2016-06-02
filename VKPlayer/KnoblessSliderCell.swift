//
//  KnoblessSliderCell.swift
//  VKPlayer
//
//  Created by Pavlo Denysiuk on 6/2/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

class KnoblessSliderCell: NSSliderCell {
    @IBInspectable
    var barRadius = CGFloat(2.5)
    
    @IBInspectable
    var barColor = NSColor.whiteColor()
    
    override func drawKnob(knobRect: NSRect) {
        // Don't draw the knob.
    }
    
    override func drawBarInside(aRect: NSRect, flipped: Bool) {
        let knobVal = CGFloat((self.doubleValue - self.minValue)/(self.maxValue - self.minValue))
        let coloredWidth: CGFloat = knobVal * aRect.width
        
        var coloredRect = aRect
        coloredRect.size.width = coloredWidth
        
        let path = NSBezierPath(roundedRect: coloredRect, xRadius: barRadius, yRadius: barRadius)
        barColor.setFill()
        path.fill()
    }
}
