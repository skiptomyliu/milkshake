//
//  MenuViewController.swift
//  Milkshake
//
//  Created by Dean Liu on 12/29/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa


// MARK: - MusicChangedProtocol
extension MenuViewController: MusicChangedProtocol {
    func musicPreflightChangedProtocol(item: MusicItem) {}
    
    func musicChangedProtocol(item: MusicItem) {
        self.tableView.reloadData()
    }
    
    func musicPlayedProtocol() {
        self.isPlaying = true
        self.tableView.reloadData()
    }
    
    func musicPausedProtocol() {
        self.isPlaying = false
        self.tableView.reloadData()
    }
}

// MARK: - NSTableViewDelegate, NSTableViewDataSource
extension MenuViewController: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return ROW_HEIGHT
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return menuItems.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let idx = (notification.object as! NSTableView).selectedRow
        mainVCPopoverDelegate?.menuSelectedProtocol(index: idx)
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let cellId = "rowview"
        if let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? SearchTableRowView {
            return rowView
        } else {
            let rowView = SearchTableRowView.init(frame: NSMakeRect(0, 0, self.view.frame.size.width, 50))
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "rowview")
            return rowView
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MenuTableCellView"), owner: self) as! MenuTableCellView
        cellView.identifier = NSUserInterfaceItemIdentifier(rawValue: "MenuTableCellView");
        
        cellView.titleTextField.stringValue = menuItems[row].0
        cellView.setCell(title:menuItems[row].0, imageName:menuItems[row].1)
        cellView.iconImageView.animates = self.isPlaying
        return cellView
    }
}


class MenuViewController: NSViewController  {
    @IBOutlet weak var tableView: NSTableView!
    weak var mainVCPopoverDelegate: MenuSelectedProtocol?
    
    let ROW_HEIGHT = CGFloat(25)
    var isPlaying = false
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    var menuItems = [("NOW PLAYING", "playing"), ("STATIONS", "radio"), ("PLAYLISTS", "playlisticon"), ("ARTISTS", "guitar")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (appDelegate.isPremium) {
            self.menuItems = [("NOW PLAYING", "playing"), ("STATIONS", "radio"), ("PLAYLISTS", "playlisticon"), ("ARTISTS", "guitar"), ("HISTORY", "history")]
        } else {
            self.menuItems = [("NOW PLAYING", "playing"), ("STATIONS", "radio"), ("HISTORY", "history")]
        }
        self.tableView.selectionHighlightStyle = .none
        let nib = NSNib(nibNamed: NSNib.Name(rawValue: "MenuTableCellView"), bundle: Bundle.main)
        self.tableView.register(nib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MenuTableCellView"))
        
        // gradient
        self.view.wantsLayer = true
        let colorTop =  CGColor.black
        let colorBottom = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorBottom, colorTop]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        self.view.layer?.insertSublayer(gradientLayer, at:1)
    }
}
