//
//  MyWindow.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  
//
//
import Cocoa

class MyWindow: NSWindow {

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // Set to clear so our RoundView class can draw its background
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
    }
    
    override var canBecomeKey: Bool {
        // because the window is borderless, we have to make it active
        return true
    }
    
    override var canBecomeMain: Bool{
        // because the window is borderless, we have to make it active
        return true
    }

}
