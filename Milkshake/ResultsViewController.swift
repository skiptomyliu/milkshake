//
//  ResultsViewController.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  The main VC that displays every table (Playlist, Stations, Artists, Albums, etc.)
//

import Cocoa

class ResultsViewController: NSViewController {

    @IBOutlet weak var searchTableView: NSTableView!
    weak var mainVCDelegate: CellSelectedProtocol?
    
    var tracks: [MusicItem] = []
    var search_results: [MusicItem] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchTableView.selectionHighlightStyle = .none
        let nib = NSNib(nibNamed: NSNib.Name(rawValue: "SearchTableCellView"), bundle: Bundle.main)
        self.searchTableView.register(nib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SearchTableCellView"))
        
        let headerNib = NSNib(nibNamed: NSNib.Name(rawValue: "HeaderTableCellView"), bundle: Bundle.main)
        self.searchTableView.register(headerNib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderTableCellView"))
        
        let artNib = NSNib(nibNamed: NSNib.Name(rawValue: "ArtTableCellView"), bundle: Bundle.main)
        self.searchTableView.register(artNib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ArtTableCellView"))
        
        self.searchTableView.action = #selector(actionSelectedCell(sender:))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set our custom tableview to override keyboard actions
        (self.searchTableView as! MyTableView).mainVCDelegate = self.mainVCDelegate
    }
    
    @objc func actionSelectedCell(sender: AnyObject) {
        let idx = self.searchTableView.selectedRow
        if let cellView = self.searchTableView.view(atColumn: 0, row: idx, makeIfNecessary: true) as? SearchTableCellView {
            self.mainVCDelegate?.cellSelectedProtocol(cell: cellView)
        }
    }
    
    // move this to util?
    func getAllTracks() -> [MusicItem] {
        if self.tracks.count <= 0 {
            for musicItem in self.search_results {
                if musicItem.type == MusicType.TRACK {
                    self.tracks.append(musicItem)
                }
            }
        }
        return self.tracks
    }
    
    // move this to util?
    func getFirstStation() -> MusicItem? {
        if self.tracks.count <= 0 {
            for musicItem in self.search_results {
                if musicItem.type == MusicType.STATION {
                    return musicItem
                }
            }
        }
        return nil
    }
    
    func setResults(results: [MusicItem]){
        self.search_results = results
        self.searchTableView.reloadData()
        self.searchTableView.scrollRowToVisible(0)
    }
    
    func setResults(_ results: [MusicItem], defaultSelectRow: Bool){
        self.setResults(results: results)
        self.searchTableView.selectRowIndexes(NSIndexSet(index: 0) as IndexSet, byExtendingSelection: false)
    }
    
    func removeAllObjects() {
        self.search_results.removeAll()
        self.searchTableView.reloadData()
    }
}

// MARK: - NSTableViewDelegate, NSTableViewDataSource
extension ResultsViewController: NSTableViewDelegate, NSTableViewDataSource{
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let musicItem = self.search_results[row]
        var height: CGFloat = 50.0
        if musicItem.isHeader && musicItem.heroImage != nil {
            height = 100
        } else if musicItem.isHeader && musicItem.heroImage == nil {
            height = 30
        }
        return height
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.search_results.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let musicItem = self.search_results[row]
        if musicItem.isHeader && musicItem.heroImage == nil {
            let cellView = (tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderTableCellView"), owner: self) as? HeaderTableCellView)!
            cellView.identifier = NSUserInterfaceItemIdentifier(rawValue: "HeaderTableCellView");
            cellView.setCellWithItem(item: musicItem)
            return cellView
        } else if musicItem.isHeader && musicItem.isArtist {
            let cellView = (tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ArtTableCellView"), owner: self) as? ArtTableCellView)!
            cellView.mainVCDelegate = self.mainVCDelegate
            cellView.identifier = NSUserInterfaceItemIdentifier(rawValue: "ArtTableCellView");
            cellView.setCellWithItem(item: musicItem)
            return cellView
        } else {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SearchTableCellView"), owner: self) as! SearchTableCellView
            cellView.identifier = NSUserInterfaceItemIdentifier(rawValue: "SearchTableCellView");
            cellView.setCellWithSearchResult(result: self.search_results[row])
            cellView.mainVCDelegate = self.mainVCDelegate
            return cellView
        }
    }
    
}
