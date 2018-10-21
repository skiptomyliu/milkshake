//
//  PlayerButton.swift
//  Milkshake
//
//  Created by Dean Liu on 12/12/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class PlayerButton: MyButtonCursor {
    var stateImage: NSImage?
    var hoverImage: NSImage?
    var ogImage: NSImage?
    var hoverAlternate: NSImage?
    var ogImageHighlight: NSImage?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.ogImage = self.image
        self.hoverImage = tintedImage(self.ogImage!, tint: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1))
        self.stateImage = tintedImage(self.ogImage!, tint: NSColor(calibratedRed: 1, green: 0.2, blue: 0.7, alpha: 1))

        let area = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(area)

        // Prevent highlight box
        (self.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask
    }
    
    func tintedImage(_ image: NSImage, tint: NSColor) -> NSImage {
        guard let tinted = image.copy() as? NSImage else { return image }
        tinted.lockFocus()
        tint.set()
        
        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        
        __NSRectFillUsingOperation(imageRect, .sourceAtop)
        
        tinted.unlockFocus()
        return tinted
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        if self.isEnabled {
            if isToggle {
                self.image = self.hoverAlternate
            } else {
                self.image = self.hoverImage
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        if self.isEnabled {
            if self.state == NSControl.StateValue.off {
                if isToggle {
                    self.image = self.alternateImage
                } else {
                    self.image = self.ogImage
                }
            } else {
                // mouseDown sets the state to ON causing constant highlight
                // we reset to ogImage if it's not a toggle to prevent constant highlight
                if isToggle {
                    self.image = self.alternateImage
                } else {
                    self.image = self.ogImage
                }
            }
            
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if self.isEnabled {
            self.highlight(false)
        }
    }
    
    var isToggle: Bool = false {
        willSet {
            if let alternateImage = self.alternateImage {
                self.hoverAlternate = tintedImage(alternateImage, tint: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1))
            }
            
            if (newValue == true) {
                self.image = self.alternateImage
            } else{
                self.image = self.ogImage
            }
            
        }
        didSet { }
    }

    
    
}

