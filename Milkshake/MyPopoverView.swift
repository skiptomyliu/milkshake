//
//  MyPopoverView.swift
//  Milkshake
//
//  Created by Dean Liu on 12/29/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Top right dark navigation menu
//
import Cocoa

class MyPopoverView: NSView {
    
    override func viewDidMoveToWindow() {
        guard let frameView = window?.contentView?.superview else {
            return
        }
        let backgroundView = NSView(frame: frameView.bounds)
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = CGColor.black // colour of your choice
        backgroundView.autoresizingMask = [.width, .height]
        
        frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
    }
    
}
