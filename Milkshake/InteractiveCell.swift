//
//  InteractiveCell.swift
//  Milkshake
//
//  Created by Dean Liu on 8/18/22.
//  Copyright © 2022 Dean Liu. All rights reserved.
//

import Cocoa

protocol InteractiveCell: NSTableCellView {
    func canClick() -> Bool
}


