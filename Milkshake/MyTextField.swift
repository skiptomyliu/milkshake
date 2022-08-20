//
//  MyTextField.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Change cursor color of NSTextField.  Used on search field
//

import Cocoa

class MyTextField: NSTextField {

    override func becomeFirstResponder() -> Bool {
        self.layer?.cornerRadius = 10
        self.layer?.borderColor = NSColor(red:204.0/255.0, green:204.0/255.0, blue:204.0/255.0, alpha:1.0).cgColor

        let responderStatus = super.becomeFirstResponder()

        if let selectionRange = self.currentEditor()?.selectedRange {
            self.currentEditor()?.selectedRange = NSMakeRange(selectionRange.length, 0)
        }

        let fieldEditor = self.window?.fieldEditor(true, for: self) as! NSTextView
        fieldEditor.insertionPointColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)

        return responderStatus
    }
}
