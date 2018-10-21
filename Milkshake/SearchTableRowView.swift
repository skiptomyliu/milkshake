//
//  SearchTableRowView.swift
//  Milkshake
//
//  Created by Dean Liu on 11/29/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Highlight row set to faded white instead of Apple's default blue
//

import Cocoa

class SearchTableRowView: NSTableRowView {
    
    // Needed, otherwise highlight will keep increasing
    override var isSelected: Bool {
        willSet { }
        didSet { self.needsDisplay = true }
    }
    
    override func drawBackground(in dirtyRect: NSRect) {
        if (!self.isSelected) {
            NSColor.clear.set()
        } else {
            NSColor.init(red: 1, green: 1, blue: 1, alpha: 0.1).set()
        }
        bounds.fill()
    }
}
