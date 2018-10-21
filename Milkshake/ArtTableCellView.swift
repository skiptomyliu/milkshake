//
//  ArtTableCellView.swift
//  Milkshake
//
//  Created by Dean Liu on 12/28/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Header CellView for Artists.
//  Displays heroImage, listener count, start station and play top songs

import Cocoa

class ArtTableCellView: NSTableCellView {

    @IBOutlet weak var artImageView: NSImageView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
    
    var item:MusicItem = MusicItem()
    weak var mainVCDelegate: CellSelectedProtocol?
    
    func setCellWithItem(item:MusicItem) {
        self.item = item
        self.titleTextField.stringValue = item.name!
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:item.listenerCount))!
        self.subtitleTextField.stringValue = "\(formattedNumber) Listeners"
        
        if let albumArt = item.heroImage {
            if albumArt != "" {
                let url = URL(string: albumArt)
                self.artImageView.kf.setImage(with: url)
            } else {
                self.artImageView.image = NSImage(named: NSImage.Name(rawValue: "album-500.png"))
            }
        }
    }
    
    @IBAction func playTopSongs(_ sender: Any) {
        mainVCDelegate?.cellTopSongsSelectedProtocol()
    }
    
    @IBAction func createStation(_ sender: Any) {
        mainVCDelegate?.cellCreateStationSelectedProtocol(pandoraId: item.pandoraId!)
    }
    
}
