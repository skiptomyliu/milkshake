//
//  MySlider.swift
//  Milkshake
//
//  Created by Dean Liu on 12/16/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Foreground slider that fades in and out when user hovers

import Cocoa

class MySlider: NSSlider {

    let fadeDuration = 0.20

    override func awakeFromNib() {
        super.awakeFromNib()
        let area = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(area)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled {
            UtilView.fade(view: self, alpha: 1.0, duration: self.fadeDuration)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if self.isEnabled {
            UtilView.fade(view: self, alpha: 0.0, duration: self.fadeDuration)
        }
    }
}
