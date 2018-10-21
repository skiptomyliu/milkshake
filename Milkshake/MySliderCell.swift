//
//  MySliderCell.swift
//  Milkshake
//
//  Created by Dean Liu on 12/16/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class MySliderCell: NSSliderCell {
    
    var activeColor = NSColor.init(red: 252/255.0, green: 149/255.0, blue: 38/255.0, alpha: 1.0)
    var bgColor = NSColor.clear
    
    override func drawKnob() {
        
    }

    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size.height = 4
        
        let barRadius = 2.5
        // Knob position depending on control min/max value and current control value.
        let value = (self.doubleValue - self.minValue)/(self.maxValue - self.minValue)
        
        // Final Left Part Width
        let finalWidth = value * Double((self.controlView?.frame.size.width)! - 6)
        
        // Left Part Rect
        var leftRect = rect
        leftRect.size.width = CGFloat(finalWidth)
        
        // Draw background
        let bg = NSBezierPath.init(roundedRect: rect, xRadius: CGFloat(barRadius), yRadius: CGFloat(barRadius))

        NSColor.clear.setFill()
        bg.fill()

        // Draw active
        let active = NSBezierPath.init(roundedRect: leftRect, xRadius: CGFloat(barRadius), yRadius: CGFloat(barRadius))
        self.activeColor.setFill()
        active.fill()

    }
}
