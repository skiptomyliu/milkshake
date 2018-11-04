//
//  ViewController.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa
import QuartzCore
import Alamofire

class MainViewController: NSViewController {
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var resultsView: NSView!
    @IBOutlet weak var playerView: NSView!
    @IBOutlet var roundView: RoundView!
    @IBOutlet weak var searchButton: NSButton!

    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    let kKEYDELAY = 0.35 // pause before searching

    var stationResultsViewController: ResultsViewController = ResultsViewController(nibName: NSNib.Name(rawValue: "ResultsViewController"), bundle: nil)
    var playlistResultsViewController: ResultsViewController = ResultsViewController(nibName: NSNib.Name(rawValue: "ResultsViewController"), bundle: nil)
    var artistResultsViewController: ResultsViewController = ResultsViewController(nibName: NSNib.Name(rawValue: "ResultsViewController"), bundle: nil)
    var historyResultsViewController = ResultsViewController(nibName: NSNib.Name(rawValue: "ResultsViewController"), bundle: nil)
    var playerViewController: PlayerViewController = PlayerViewController(nibName: NSNib.Name(rawValue: "PlayerViewController"), bundle: nil)
    var nowPlayingViewController = NowPlayingViewController(nibName: NSNib.Name(rawValue: "NowPlayingViewController"), bundle: nil)

    
    var menuViewController = MenuViewController(nibName: NSNib.Name(rawValue: "MenuViewController"), bundle: nil)
    var popover = NSPopover()
    
    var vcStack:[NSViewController] = []
    var vcIndex: Int = -1
    var _curViewController: NSViewController?
    var _curSearchController: ResultsViewController?

    var nowPlayingSearchCell: SearchTableCellView?
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    /*
     
     Window Functions
     
     */
    
    func showWindow() {
        self.view.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideWindow() {
        self.searchField.stringValue = "";
        self.view.window?.close()
    }
   
    override func viewDidAppear() {
        self.view.window?.makeKeyAndOrderFront(nil)
        self.view.window?.makeFirstResponder(self.searchField)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.appDelegate.dj.playerVCDelegate = self.playerViewController
        self.appDelegate.radio.playerVCDelegate = self.playerViewController
        self.appDelegate.dj.nowVCDelegate = self.nowPlayingViewController
        self.appDelegate.radio.nowVCDelegate = self.nowPlayingViewController
        self.appDelegate.dj.menuVCDelegate = self.menuViewController
        self.appDelegate.radio.menuVCDelegate = self.menuViewController
        self.appDelegate.dj.mainVCDelegate = self
        self.appDelegate.radio.mainVCDelegate = self
        self.menuViewController.mainVCPopoverDelegate = self
        self.menuViewController.view.needsDisplay = true // load the views,
        self.nowPlayingViewController.mainVCDelegate = self
        self.searchButton.isEnabled = false

        self.playerView.addSubview(self.playerViewController.view)
        UtilView.addShadow(parentView: self.view, fgView: self.playerView)
        self.loadStationResults(self)
        
        self.nowPlayingViewController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        // Auto play on launch
        // self.playFirstStation()
    }
    
    func playFirstStation() {
        self.appDelegate.api.getStations() { (results) in
            let stationResults = Callback.callbackStationsList(results: results)
            self.stationResultsViewController.mainVCDelegate = self
            self.stationResultsViewController.search_results = stationResults
            
            if let station = self.stationResultsViewController.getFirstStation() {
                self.playStation(musicItem: station)
            } else {
                print ("NO STATION")
            }
        }
    }
    
    @objc func search(searchTxt:String) {
        self.appDelegate.api.search(txt: searchTxt , callbackHandler: callbackSearch)
    }

    /*
     
     Begin Callbacks
     
     */
    
    func callbackSearch(results: [String: AnyObject]) {
        let search_results = Util.parseSearchIntoItems(results: results)
        if self.vcStack[self.vcStack.count-1] == self._curSearchController &&
            self._curViewController == self._curSearchController {
            self._curSearchController!.setResults(search_results, defaultSelectRow:true)
            self.sweepNowPlaying()
        } else {
            self._curSearchController = self.pushResults(search_results)
        }
        self.searchButton.isEnabled = true
    }
    
    func callbackAlbum(results: Dictionary<String, AnyObject>) {
        var items: [MusicItem] = []
        let searchResults = Util.parseAlbumIntoTracksv2(results: results)
        
        let latestHeader = MusicItem()
        latestHeader.name = searchResults[0].albumTitle?.uppercased()
        latestHeader.isHeader = true
        items.append(latestHeader)
        items = items + searchResults
        
        _ = self.pushResults(items)
    }
    
    func createStationCallback(results: [String: AnyObject]) {
        let musicItem = Util.parseCreateStation(result: results)
        self.stationResultsViewController.search_results = [] // hack to force refresh
        self.playStation(musicItem: musicItem)
    }
    
    func callbackArtist(results: [String: AnyObject]) {
        let items = Callback.callbackArtist(results: results)
        _ = self.pushResults(items)
        
    }
    
    func callbackStationsList(results: [String: AnyObject]) {
        let stationResults = Callback.callbackStationsList(results: results)
        self.stationResultsViewController.mainVCDelegate = self
        self.stationResultsViewController.setResults(results: stationResults)
        // needed when creating a new station, we sweep to see if playing
        // due to async nature of request callback in api, the request finishes after the vc load
        self.sweepNowPlaying()
    }
    
    func callbackPlaylistList(results: [String: AnyObject]) {
        let playlistResults = Callback.callbackPlaylistList(results: results)
        self.playlistResultsViewController.setResults(results: playlistResults)
    }
    
    func callbackPlaylist(results: [String: AnyObject]) {
        let playlistResults = Util.parsePlaylistIntoItems(playlistResult: results)
        _ = self.pushResults(playlistResults)
    }
    
    func callbackArtistList(results: [String: AnyObject]) {
        var artistResults = Util.parseArtistIntoItems(artistResults: results)
        let artistHeader = MusicItem()
        artistHeader.name = "ARTISTS"
        artistHeader.isHeader = true
        artistResults.insert(artistHeader, at: 0)
        self.artistResultsViewController.setResults(results: artistResults)
    }
    
    func pushResults(_ items: [MusicItem]) -> ResultsViewController{
        let resultsController = ResultsViewController(nibName: NSNib.Name(rawValue: "ResultsViewController"), bundle:nil)
        resultsController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        resultsController.mainVCDelegate = self
        resultsController.setResults(results: items)
        print("pushing", items.count)
        self.pushVC(vc: resultsController)
        return resultsController
    }
    
    func pushVC(vc: NSViewController ) {
        self.vcStack.removeSubrange(self.vcIndex+1..<self.vcStack.count)
        self.vcStack.append(vc)
        self._curViewController?.view.removeFromSuperview()
        self._curViewController = vc
        self.resultsView.addSubview(vc.view)
        self.vcIndex = self.vcStack.count - 1
        self.handleHistoryState()
        self.sweepNowPlaying()
    }
    
    func handleHistoryState() {
        if self.vcIndex <= 0 {
            self.backButton.isHidden = true
        } else {
            self.backButton.isHidden = false
        }
        
        if self.vcIndex >= self.vcStack.count - 1  {
            self.nextButton.isHidden = true
        } else {
            self.nextButton.isHidden = false
        }
    }
    
    func playStation(musicItem:MusicItem) {
        appDelegate.radio.playerPause()
        appDelegate.dj.playerPause()
        appDelegate.windowController?.window?.title = musicItem.name ?? ""
        appDelegate.radio.curPlayingItem = musicItem
        appDelegate.radio.playStation(stationId: musicItem.stationId!, isStationStart: true, lastPlayedTrackToken: "")
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        self.textFieldChanged()
    }
    
    // When there is entered text, we search.  If less than a certain time, we cancel request
    // because user is still typing.  If empty, shrink window
    func textFieldChanged (){
        let searchTxt = self.searchField.stringValue
        if (self.searchField.stringValue.count > 0) {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(search(searchTxt:)), with: searchTxt, afterDelay: kKEYDELAY)
        }
    }
    
    func isCtrlW(e:NSEvent?) -> Bool{
        if let event = e {
            let flags = event.modifierFlags.rawValue
            // https://stackoverflow.com/questions/11682939/add-hotkey-to-nstextfield
            if(event.keyCode == 0xD && flags == 0x100108) {
                return true
            }
        }
        return false
    }
    
    //XXX:  Refactor... there's a better way,
    // Show equalizer gif on current playing MusicItem
    func sweepNowPlaying() {
        if let music = self.appDelegate.music {
            let rc = self._curViewController
            if rc is ResultsViewController && rc != self.historyResultsViewController {
                let rvc = rc as! ResultsViewController
                let rows = rvc.search_results.count
                for i in 0..<rows {
                    if rvc.searchTableView.view(atColumn: 0, row: i, makeIfNecessary: true) is SearchTableCellView {
                        let cell = rvc.searchTableView.view(atColumn: 0, row: i, makeIfNecessary: false) as! SearchTableCellView
                        if (
                            // check song
                            cell.item.pandoraId == music.curPlayingItem.pandoraId) ||
                            // check station
                            (cell.item.stationId == music.curPlayingItem.stationId && cell.item.stationId != nil)  ||
                            // check playlist
                            (cell.item.pandoraId == music.curPlayingItem.playlistId) ||
                            // check album
                            (cell.item.pandoraId == music.curPlayingItem.albumId)
                            {
                            cell.setPlaying(isPlaying: music.isPlaying(), isFocus: true)
                            self.nowPlayingSearchCell = cell
                        } else {
                            cell.setPlaying(isPlaying: false)
                        }
                    }
                }
            }
        }
    }
    
    func loadNowPlaying(_ sender: Any) {
        self.nowPlayingViewController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        self.pushVC(vc: self.nowPlayingViewController)
    }
    
    func loadStationResults(_ sender: Any) {
        self.stationResultsViewController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        self.stationResultsViewController.mainVCDelegate = self
        if self.stationResultsViewController.search_results.count <= 0 {
            self.appDelegate.api.getStations(callbackHandler: callbackStationsList)
        }
        self.pushVC(vc: self.stationResultsViewController)
    }
    
    func loadPlaylistResults(_ sender: Any) {
        self.playlistResultsViewController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        self.playlistResultsViewController.mainVCDelegate = self
        self.pushVC(vc: self.playlistResultsViewController)
        if self.playlistResultsViewController.search_results.count <= 0 {
            self.appDelegate.api.getSortedPlaylists(callbackHandler: callbackPlaylistList)
        }
    }
    
    func loadArtistResults(_ sender: Any) {
        self.artistResultsViewController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        self.artistResultsViewController.mainVCDelegate = self
        self.pushVC(vc: self.artistResultsViewController)
        if self.artistResultsViewController.search_results.count <= 0 {
            self.appDelegate.api.getSortedArtists(callbackHandler: callbackArtistList)
        }
    }
    
    func loadHistoryResults(_ sender: Any) {
        self.historyResultsViewController.view.frame = CGRect(x: 0, y: 0, width: self.resultsView.frame.size.width, height: self.resultsView.frame.size.height)
        self.historyResultsViewController.mainVCDelegate = self
        self.pushVC(vc: self.historyResultsViewController)
        let historyHeader = MusicItem()
        historyHeader.name = "PLAY HISTORY"
        historyHeader.isHeader = true
        if self.historyResultsViewController.search_results.count <= 0 {
            var historyArray = Util.fetchFromHistory()
            historyArray.insert(historyHeader, at: 0)
            self.historyResultsViewController.setResults(results: historyArray)
        }
    }
    
    /*
     
     IBActions
     
     */
    
    @IBAction func backAction(_ sender: Any) {
        let prev = self.vcIndex - 1
        if prev >= 0 {
            let vc = self.vcStack[prev]
            self._curViewController?.view.removeFromSuperview()
            self._curViewController = vc
            
            self.resultsView.addSubview(vc.view)
            self.vcIndex -= 1
        }
        self.handleHistoryState()
        self.sweepNowPlaying()
    }
    
    @IBAction func forwardAction(_ sender: Any) {
        let next = self.vcIndex + 1
        if next < self.vcStack.count {
            let vc = self.vcStack[next]
            self._curViewController?.view.removeFromSuperview()
            self._curViewController = vc
            self.resultsView.addSubview(vc.view)
            self.vcIndex += 1
        }
        self.handleHistoryState()
        self.sweepNowPlaying()
    }
    
    @IBAction func loadSearchResults(_ sender: Any) {
        // Only make firstResponder if button tapped
        // self.view.window?.makeFirstResponder(self._curSearchController?.searchTableView)
    }
    
    @IBAction func showMenu(_ sender: Any) {
        self.popover.contentViewController = self.menuViewController
        self.menuViewController.view.setFrameSize(NSSize(
            width: self.menuViewController.view.frame.size.width,
            height: CGFloat(self.menuViewController.menuItems.count) * self.menuViewController.ROW_HEIGHT + CGFloat(8))
        )
        self.popover.contentSize = menuViewController.view.frame.size
        self.popover.behavior = .transient
        self.popover.animates = false
        self.popover.show(relativeTo: (sender as AnyObject).bounds, of: sender as! NSView, preferredEdge: NSRectEdge.maxY)
    }
}

// MARK: - NSTextFieldDelegate
extension MainViewController: NSTextFieldDelegate {
    // table view data source methods
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == (NSSelectorFromString("noop:") )){
            if self.isCtrlW(e: NSApp.currentEvent) {
                self.hideWindow()
                return true
            }
        }
        // ESC key
        if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
            return true;
        } else if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            // ENTER key
            print("MainVC enter key")
            self._curSearchController?.actionSelectedCell(sender: self)
            //            self._curResultsController?.actionSelectedCell(sender: self)
            return true;
        } else if (commandSelector == #selector(NSResponder.moveDown(_:)) ||
            commandSelector == #selector(NSResponder.moveUp(_:))) {
            // Move / Up Down selection
            var idx = 0;
            let step = (commandSelector == #selector(NSResponder.moveDown(_:))) ? 1 : -1
            if self._curViewController is ResultsViewController {
                let rc = self._curViewController as! ResultsViewController
                if(rc.searchTableView.selectedRow < 0) {
                    idx = 0;
                } else {
                    idx = rc.searchTableView.selectedRow + step;
                }
                rc.searchTableView.selectRowIndexes(NSIndexSet(index: idx) as IndexSet, byExtendingSelection: false)
                self.view.window?.makeFirstResponder(rc.searchTableView)
            }
            return true
        }
        return false
    }
}

// MARK: - CellSelectedProtocol
extension MainViewController: CellSelectedProtocol {
    
    // Called by searchtablecell artist cell / artist link
    func cellArtistSelectedProtocol(item: MusicItem) {
        appDelegate.api.catalogDetails(pandoraId: item.artistId!, callbackHandler: callbackArtist)
    }
    
    func cellAlbumSelectedProtocol(item: MusicItem) {
        appDelegate.api.albumToken(token: item.albumId!, callbackHandler: callbackAlbum)
    }
    
    func cellPlayPlaylistSelectedProtocol(item: MusicItem) {
        
        func setWithAlbumAndPlay(_ items: [MusicItem]) {            
            self.appDelegate.dj.setWithAlbum(items: items)
            appDelegate.radio.playerPause()
            self.appDelegate.dj.playNext()
        }
        
        if item.type == MusicType.ALBUM {
            appDelegate.api.albumToken(token: item.token!) { (response) in
                let searchResults = Util.parseAlbumIntoTracksv2(results: response)
                setWithAlbumAndPlay(searchResults)
            }
        } else {
            appDelegate.api.getTracks(pandoraId: item.playlistId!) { (response) in
                let playlistResults = Util.parsePlaylistIntoItems(playlistResult: response)
                setWithAlbumAndPlay(playlistResults)
            }
        }
    }
    
    func cellPlaylistSelectedProtocol(item: MusicItem) {
        appDelegate.api.getTracks(pandoraId: item.playlistId!, callbackHandler: callbackPlaylist)
    }
    
    func cellSelectedProtocol(cell: SearchTableCellView) {
        let item = cell.item
        let type = item.type
        
        //XXX
        // When played, get current view controller tracks and set album
        if type == MusicType.TRACK && item.hasInteractive {
            // if playing already, pause
            if item.pandoraId == self.appDelegate.music?.nowPlaying() {
                self.nowPlayingViewController.playPause(self)
            } else {
                if let rvc = self._curViewController {
                    if rvc is ResultsViewController && rvc != self.historyResultsViewController {  
                        let tracks = (rvc as! ResultsViewController).getAllTracks()
                        self.appDelegate.dj.setWithAlbum(items: tracks)
                    } else if rvc == self.historyResultsViewController {
                        
                    }
                }
                // If not premium, create a station from track
                if self.appDelegate.isPremium == false && item.cellType == CellType.SEARCH {
                    cell.setPlaying(isPlaying: true, isFocus: true)
                    appDelegate.radio.playerPause()
                    appDelegate.api.createStation(pandoraId:item.pandoraId!, callbackHandler: createStationCallback)
                } else {
                    cell.setPlaying(isPlaying: true, isFocus: true)
                    appDelegate.radio.playerPause()
                    appDelegate.dj.playTrack(musicItem: item)
                }
            }
            sweepNowPlaying()
        }
        else if type == MusicType.ALBUM {
            let token = item.token!
            appDelegate.api.albumToken(token: token, callbackHandler: callbackAlbum)
        }
        else if type == MusicType.COMPOSER {
            self.cellArtistSelectedProtocol(item: item)
        }
        else if type == MusicType.ARTIST {
            if self.appDelegate.isPremium == false {
                cell.setPlaying(isPlaying: true, isFocus: true)
                appDelegate.radio.playerPause()
                appDelegate.api.createStation(pandoraId:item.pandoraId!, callbackHandler: createStationCallback)
            } else {
                appDelegate.api.catalogDetails(pandoraId: item.artistId!, callbackHandler: callbackArtist)
            }
        }
        else if type == MusicType.STATION {
            // if playing already, pause
            if item.stationId == self.appDelegate.music?.nowPlaying() {
                self.nowPlayingViewController.playPause(self)
            } else {
                cell.setPlaying(isPlaying: true, isFocus: true)
                self.playStation(musicItem: item)
            }
        }
        else if type == MusicType.PLAYLIST {
            appDelegate.api.getTracks(pandoraId: item.pandoraId!, callbackHandler: callbackPlaylist)
        }
        self.searchField.stringValue = ""
    }
    
    func cellHighlightedProtocol(item: MusicItem) { }
    
    func cellCreateStationSelectedProtocol(pandoraId: String) {
        print("start station" , pandoraId)
        appDelegate.api.createStation(pandoraId:pandoraId, callbackHandler: createStationCallback)
    }
    
    func cellTopSongsSelectedProtocol() {
        if self._curViewController is ResultsViewController {
            let rvc: ResultsViewController = self._curViewController as! ResultsViewController
            let tracks = rvc.getAllTracks()
            self.appDelegate.dj.setWithAlbum(items: tracks)
            self.appDelegate.music = self.appDelegate.dj
            appDelegate.radio.playerPause()
            appDelegate.dj.playerPause()
            appDelegate.dj.playNext()
        }
    }
    
    func escKeyProtocol() {
        self.backAction(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    func searchKeyProtocol(keyChar: String) {
        self.searchField.stringValue = String(format:"%@%@", self.searchField.stringValue, keyChar);
        self.view.window?.makeFirstResponder(self.searchField)
        self.textFieldChanged()
    }
}

// MARK: - MusicChangedProtocol
extension MainViewController: MusicChangedProtocol {
    
    func musicPlayedProtocol() {
        self.sweepNowPlaying()
    }
    
    func musicPausedProtocol() {
        self.sweepNowPlaying()
    }
    
    // Update now playing view and background
    func musicChangedProtocol(item: MusicItem) {
        if appDelegate.isArtAnimate == false {
            if let albumArt = item.albumArt {
                if albumArt != "" {
                    Alamofire.request(albumArt).responseData { (response) in
                        if response.error == nil {
                            if let data = response.data {
                                self.roundView.backgroundImage = NSImage(data: data)
                                self.roundView.setNeedsDisplay(self.roundView.frame)
                            }
                        }
                    }
                } else {
                    //   self.roundView.addGradient()
                }
            }
        } else {
            self.roundView.backgroundImage = NSImage(named: NSImage.Name(rawValue: "grey.jpg"))
            self.roundView.setNeedsDisplay(self.roundView.frame)
        }

        if appDelegate.isRadio() == false {
            appDelegate.windowController?.window?.title = item.artistName ?? ""
        }
        
        self.nowPlayingViewController.setViewWithMusicItem(item: item)
        
        // Update history vc
        _ = Util.saveToHistory(item: item)
        self.historyResultsViewController.insertMusicItem(item: item, index: 1)
        sweepNowPlaying()
    }
}

// MARK: - MenuSelectedProtocol
extension MainViewController: MenuSelectedProtocol {
    func menuSelectedProtocol(index: Int) {
        self.popover.performClose(self)
        var idx = index
        var freeMapping: [Int: Int] = [0: 0, 1:1, 2:4]
        if appDelegate.isPremium == false {
            idx = freeMapping[index] ?? 0
        }
        
        switch idx {
        case 0:
            self.loadNowPlaying(self)
            break
        case 1:
            self.loadStationResults(self)
            break
        case 2:
            self.loadPlaylistResults(self)
            break
        case 3:
            self.loadArtistResults(self)
            break
        case 4:
            self.loadHistoryResults(self)
            break
        default:
            break
        }
    }
}

