//
//  HeaderTableCellView.swift
//  Milkshake
//
//  Created by Dean Liu on 12/28/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class HeaderTableCellView: NSTableCellView {

    @IBOutlet weak var titleTextField: NSTextField!
    
    func setCellWithItem(item:MusicItem) {
        self.titleTextField.stringValue = item.name!
    }
    
}
