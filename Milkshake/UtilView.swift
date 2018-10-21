//
//  UtilView.swift
//  Milkshake
//
//  Created by Dean Liu on 12/11/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class UtilView: NSObject {

    class func addShadow(parentView: NSView, fgView:NSView) {
        
        parentView.wantsLayer = true
        parentView.superview?.wantsLayer = true
        
        fgView.wantsLayer = true
        fgView.needsLayout = true
        fgView.needsDisplay = true
        
        fgView.shadow = NSShadow()
        fgView.layer?.shadowOpacity = 0.22
        fgView.layer?.shadowColor = NSColor.black.cgColor
        fgView.layer?.shadowOffset = NSMakeSize(0, 0)
        fgView.layer?.shadowRadius = 5
    }
    
    class func fade(view: NSView, alpha: CGFloat, duration: Double) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = duration
            view.animator().alphaValue = alpha
        }, completionHandler:{
            //
        })
    }


}
