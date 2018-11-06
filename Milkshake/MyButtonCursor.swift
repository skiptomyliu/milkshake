//
//  MyButtonCursor.swift
//  Milkshake
//
//  Created by Dean Liu on 1/30/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//

import Cocoa

class MyButtonCursor: NSButton {
    
    var cursor: NSCursor?
    
    override func awakeFromNib() {
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        let pointHand = NSCursor.pointingHand
        self.addCursorRect(self.bounds, cursor: pointHand)
    }
    
    override func mouseExited(with event: NSEvent) {
        let arrow = NSCursor.arrow
        self.addCursorRect(self.bounds, cursor: arrow)
    }
    
    override func resetCursorRects() {
        if let cursor = self.cursor {
            self.addCursorRect(self.bounds, cursor: cursor)
        } else {
            super.resetCursorRects()
        }
    }
}
