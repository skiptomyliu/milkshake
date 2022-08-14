//
//  VolumeSlider.swift
//  Milkshake
//
//  Created by Dean Liu on 8/12/22.
//  Copyright © 2022 Dean Liu. All rights reserved.
//

import Cocoa

class VolumeSliderCell: NSSliderCell {
    
    var backgroundColor: NSColor = NSColor(calibratedRed: 250/255.0, green: 148/255.0, blue: 55/255.0, alpha: 0.55)
        
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var rect = rect
        rect.size.height = CGFloat(5)
        let barRadius = CGFloat(2.5)
        let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
        let finalWidth = CGFloat(value * (self.controlView!.frame.size.width - 8))
        var leftRect = rect
        leftRect.size.width = finalWidth
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        backgroundColor.withAlphaComponent(0.25).setFill()
        bg.fill()
        let active = NSBezierPath(roundedRect: leftRect, xRadius: barRadius, yRadius: barRadius)
        backgroundColor.setFill()
        active.fill()
    }

}
