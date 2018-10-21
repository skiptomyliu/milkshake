//
//  MyTableView.swift
//  Milkshake
//
//  Created by Dean Liu on 11/29/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class MyTableView: NSTableView {
    
    weak var mainVCDelegate: CellSelectedProtocol?
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 0x24 { //For ENTER / RETURN key
            let idx = self.selectedRow;
            let cellView = self.view(atColumn: 0, row: idx, makeIfNecessary: true) as! SearchTableCellView
            self.mainVCDelegate?.cellSelectedProtocol(cell: cellView)
        } else if event.keyCode == 0x7D || event.keyCode == 0x7E { // DOWN / UP
            super.keyDown(with: event)
        } else if event.keyCode == 0x35 { //For ESC key
            self.mainVCDelegate?.escKeyProtocol()
        } else {
            self.mainVCDelegate?.searchKeyProtocol(keyChar: event.characters!);
        }
    }
    
}
