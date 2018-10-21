//
//  FlatButton.swift
//  Milkshake
//
//  Created by Dean Liu on 12/9/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class FlatButton: NSButton {
    var fontColor =  NSColor(calibratedRed: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 0.85)
    var textStyle = NSMutableParagraphStyle()
    var textWidth: CGFloat = 0.0
    var textWidthAdjusted: CGFloat = 0.0
    var cursor: NSCursor?
    var fontAttributes: [NSAttributedStringKey: Any] = [:]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        self.focusRingType = NSFocusRingType.none
        (self.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask
    }
    
    override func mouseEntered(with event: NSEvent) {
        self.isHighlighted = true
        let pointHand = NSCursor.pointingHand
        self.addCursorRect(self.bounds, cursor: pointHand)
    }
    
    override func mouseExited(with event: NSEvent) {
        self.isHighlighted = false
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
    
    var customTitle: String = "" {
        willSet {
            
            let fontAttributes = [NSAttributedStringKey.font: self.font!, NSAttributedStringKey.foregroundColor: self.fontColor, NSAttributedStringKey.paragraphStyle: textStyle] as [NSAttributedStringKey : Any]
            self.fontAttributes = fontAttributes
            
            let size: CGSize = newValue.size(withAttributes: fontAttributes)
            self.textWidthAdjusted = size.width < self.frame.size.width ? size.width : self.frame.size.width
            self.textWidth = size.width
            
            var area: NSTrackingArea?
            if textStyle.alignment == NSTextAlignment.center {
                area = NSTrackingArea.init(rect: CGRect(x: self.frame.width/2 - size.width/2, y: 0, width: self.frame.width/2 + size.width/2, height: size.height), options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
            } else {
                area = NSTrackingArea.init(rect: CGRect(x: 0, y: 0, width: self.textWidthAdjusted, height: size.height), options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
            }
            
            self.addTrackingArea(area!)
        }
        didSet { }
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
 
        let fontColor = NSColor(calibratedRed: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 0.85)
        let textRect = NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        let textTextContent = self.customTitle
        
        let fontAttributes = [NSAttributedStringKey.font: self.font!, NSAttributedStringKey.foregroundColor: self.fontColor, NSAttributedStringKey.paragraphStyle: textStyle] as [NSAttributedStringKey : Any]

        let textSize: CGSize = textTextContent.size(withAttributes: fontAttributes)
        var textTextRect: NSRect = NSRect(x: 0, y: -4 + ((textRect.height - textSize.height) / 2), width: textRect.width, height: textSize.height)


        NSGraphicsContext.saveGraphicsState()
        NSRect.clip(textRect)()
        
        if textStyle.alignment != NSTextAlignment.center {
            textTextRect.size.width = textSize.width
        }
        
        self.textWidthAdjusted = textSize.width

        textTextContent.draw(in: textTextRect.offsetBy(dx: 0, dy: 5), withAttributes: fontAttributes)


        NSGraphicsContext.restoreGraphicsState()
        
        if self.isHighlighted {
            let aPath = NSBezierPath()
            if textStyle.alignment == NSTextAlignment.center {
                // print("center", self.frame.width, textSize.width)
                aPath.move(to: CGPoint(x:self.frame.width/2 - textSize.width/2, y:textSize.height+3))
                aPath.line(to: CGPoint(x:self.frame.width/2 + textSize.width/2, y:textSize.height+3))
            } else {
                aPath.move(to: CGPoint(x:0, y:textSize.height+3))
                aPath.line(to: CGPoint(x:textSize.width, y:textSize.height+3))
            }
            
            aPath.lineWidth = 2.0
            //Keep using the method addLineToPoint until you get to the one where about to close the path
            aPath.close()
            fontColor.set()
            aPath.stroke()
            aPath.fill()
        }
    }
    
    
}
