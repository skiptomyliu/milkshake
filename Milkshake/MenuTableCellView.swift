//
//  MenuTableCellView.swift
//  Milkshake
//
//  Created by Dean Liu on 12/29/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class MenuTableCellView: NSTableCellView {

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var iconImageView: NSImageView!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUpTrackingArea()
    }
    
    func setUpTrackingArea() {
        let trackingArea = NSTrackingArea(rect: self.frame, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        let row:NSTableRowView = self.superview as! NSTableRowView
        row.isSelected = true
    }
    
    override func mouseExited(with event: NSEvent) {
        let row:NSTableRowView = self.superview as! NSTableRowView
        row.isSelected = false
    }
    
    
    func setCell(title:String, imageName:String) {
        self.titleTextField.stringValue = title
        self.iconImageView.wantsLayer = true
        self.iconImageView.canDrawSubviewsIntoLayer = true
        self.iconImageView.image = NSImage(named: NSImage.Name(rawValue: imageName))
        self.iconImageView.animates = true
    }
    
}
