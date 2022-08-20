//
//  SearchTableCellView.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  
//

import Kingfisher

class SearchTableCellView: NSTableCellView {

    @IBOutlet weak var artistTextField: NSTextField!
    @IBOutlet weak var typeTextField: NSTextField!
    @IBOutlet weak var cellImageView: NSImageView!
    @IBOutlet weak var darkView: NSView!
    @IBOutlet weak var largeDarkView: NSView!
    @IBOutlet weak var eBox: NSBox! // explicit
    @IBOutlet weak var rBox: NSBox! // radio
    @IBOutlet weak var pBox: NSBox! // premium
    @IBOutlet weak var latestReleaseField: NSTextField!
    @IBOutlet weak var playButton: MyButtonCursor!

    @IBOutlet weak var artistLink: FlatButton!
    @IBOutlet weak var albumLink: FlatButton!
    
    @IBOutlet weak var thumbsUpButton: PlayerButton!
    @IBOutlet weak var thumbsDownButton: PlayerButton!
    
    @IBOutlet weak var shuffleButton: PlayerButton!
    
    var playingImageView = NSImageView()
    var transparentBlackBox = NSBox()
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    weak var resultVCDelegate: CellSelectedProtocol?
    weak var mainVCDelegate: CellSelectedProtocol?
    
    var item:MusicItem = MusicItem()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let trackingArea = NSTrackingArea(rect: self.frame, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        
        let thumbTrackingArea = NSTrackingArea.init(rect:CGRect(x: self.frame.size.width-50, y: 0, width: self.frame.width, height: self.frame.size.height), options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(thumbTrackingArea)
    }

    func show_play() -> Bool {
        if self.appDelegate.isPremium {
            return (
                self.item.hasInteractive == true &&
                (self.item.type == MusicType.TRACK || self.item.type == MusicType.PLAYLIST || self.item.type == MusicType.ALBUM || self.item.type == MusicType.STATION || self.item.type == MusicType.SF || self.item.type == MusicType.SHUFFLESTATION)
            )
        } else {
            return (
                self.item.hasInteractive == true &&
                    (self.item.cellType == CellType.SEARCH) &&
                    (self.item.type == MusicType.TRACK || self.item.type == MusicType.PLAYLIST || self.item.type == MusicType.ALBUM || self.item.type == MusicType.STATION || self.item.type == MusicType.ARTIST || self.item.type == MusicType.SF || self.item.type == MusicType.SHUFFLESTATION)
            )
        }
    }
    
    func canClick() -> Bool {
        if self.appDelegate.isPremium {
            return (
                self.item.hasInteractive == true &&
                    (self.item.type == MusicType.TRACK || self.item.type == MusicType.PLAYLIST || self.item.type == MusicType.ALBUM || self.item.type == MusicType.STATION || self.item.type == MusicType.SF) || self.item.type == MusicType.ARTIST || self.item.type == MusicType.SHUFFLESTATION)
        } else {
            return (
                self.item.hasInteractive == true &&
                    (self.item.cellType == CellType.SEARCH) &&
                    (self.item.type == MusicType.TRACK || self.item.type == MusicType.PLAYLIST || self.item.type == MusicType.ALBUM || self.item.type == MusicType.STATION || self.item.type == MusicType.ARTIST || self.item.type == MusicType.SF || self.item.type == MusicType.SHUFFLESTATION)
            )
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        let row:NSTableRowView = self.superview as! NSTableRowView
        row.isSelected = true
        if self.show_play() {
            self.playButton.isHidden = false
            self.darkView.isHidden = false
        }
        if event.locationInWindow.x > self.frame.size.width-100 {
            showHideThumbs(alpha: 0.9, duration: 0.7)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        let row:NSTableRowView = self.superview as! NSTableRowView
        row.isSelected = false
        if self.show_play() {
            self.playButton.isHidden = true
            self.darkView.isHidden = self.playingImageView.animates ? false : true // hide if not playing
        }
        showHideThumbs(alpha: 0.0, duration: 0.7)
    }
    
    func showHideThumbs(alpha:CGFloat, duration: Double) {
        if self.item.cellType == CellType.HISTORY && self.item.canFeedback() {
            if alpha > 0 {
                self.largeDarkView.animator().alphaValue = 0.8
                self.largeDarkView.isHidden = false
            } else {
                self.largeDarkView.animator().alphaValue = 0
                self.largeDarkView.isHidden = true
            }
            self.thumbsUpButton.isHidden = false
            self.thumbsDownButton.isHidden = false
            self.thumbsUpButton.animator().alphaValue = alpha
            self.thumbsDownButton.animator().alphaValue = alpha
            NSAnimationContext.runAnimationGroup({(context) -> Void in
                context.duration = duration
            }) {
                // animation done
            }
        }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        willSet { }
        didSet {
            let row:NSTableRowView = self.superview as! NSTableRowView
            if (row.isSelected) {
                self.artistTextField.textColor = NSColor.white
                self.typeTextField.textColor = NSColor.white
                self.latestReleaseField.textColor =  NSColor.white
            } else {
                self.artistTextField.textColor = NSColor.white
                self.typeTextField.textColor = NSColor.init(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
                self.latestReleaseField.textColor = NSColor.init(red: 105/255.0, green: 105/255.0, blue: 105/255.0, alpha: 1)
            }
        }
    }
    
    func setCellWithItem(result: MusicItem) {
        let title = result.name ?? ""
        self.artistTextField.stringValue = title;
    }
    
    func setCellWithSearchResult(result:MusicItem) {
        self.item = result
        
        self.darkView.isHidden = true
        self.darkView.wantsLayer = true
        self.darkView.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.shuffleButton.isHidden = true
        
        let title = result.name ?? ""
        self.artistTextField.stringValue = title;
        let albumArt = result.albumArt ?? ""

        eBox.isHidden = item.explicitness == "EXPLICIT" ? false : true
        
        if albumArt != "" {
            let url = URL(string: albumArt)
            self.cellImageView.kf.setImage(with: url)
        } else {
            self.cellImageView.image = NSImage(named: NSImage.Name(rawValue: "album-500.png"))
        }
        
        if !(item.latestRelease != nil) {
            self.latestReleaseField.isHidden = true
        }
        self.artistLink.isHidden = true
        self.albumLink.isHidden = true
        if (self.item.hasInteractive == true &&
            (self.appDelegate.isPremium == false && self.item.cellType == CellType.ARTIST &&
                (self.item.type == MusicType.TRACK || self.item.type == MusicType.PLAYLIST || self.item.type == MusicType.ALBUM))
            ) {
            self.pBox.isHidden = false
        } else {
            self.pBox.isHidden = true
        }
        
        let type = result.type
        if type == MusicType.TRACK {
            let totalSeconds = result.duration
            let songTime = Util.convertSecsToMinSec(totalSeconds)
            let songTitle = String(format:"%@", songTime)
            self.typeTextField.stringValue = songTitle
            
            if self.item.isArtist == false {
                self.artistLink.isHidden = false
                self.artistLink.customTitle = item.artistName!
                self.artistLink.setNeedsDisplay()
            }
            self.setArtistLinkAndAlbumLink()
            let curPlaying = self.appDelegate.music?.curPlayingItem
            if result.pandoraId == curPlaying?.pandoraId {
                self.setPlaying(isPlaying: true)
            }
        } else if type == MusicType.ALBUM {
            item.token = API.getTokenFromItem(result)
            if let releaseDate = result.releaseDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                let dateFromString = dateFormatter.date(from: releaseDate)
                dateFormatter.dateFormat = "YYYY"
                let year = dateFormatter.string(from: dateFromString!)
                self.typeTextField.stringValue = String(format: "%@", year)
            } else {
                self.typeTextField.stringValue = ""
            }
        } else if type == MusicType.ARTIST {
            self.typeTextField.stringValue = "Artist"
            result.token = API.getTokenFromItem(result)
        } else if type == MusicType.COMPOSER {
            self.typeTextField.stringValue = "Artist"
//            result.token = API.getTokenFromItem(item: result)
        }
        else if type == MusicType.STATION || type == MusicType.SF {
            // show shuffle button is shuffle is enabled
            if self.appDelegate.radio.isShuffle {
                let stationId = self.item.stationId ?? ""
                self.shuffleButton.isHidden = stationId == ""
                self.shuffleButton.isToggle = self.appDelegate.radio.shuffleStations.contains(stationId)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let lastPlayedDateStr = self.item.lastPlayed {
                if let dateFromString = dateFormatter.date(from: lastPlayedDateStr) {
                    let lastListened = Util.convertDateToLastListened(dateFromString)
                    self.typeTextField.stringValue = String(format: "Listened: %@", lastListened)
                }
            }
            else {
                self.typeTextField.stringValue = "Station"
            }
        } else if type == MusicType.PLAYLIST {
            self.typeTextField.stringValue = String(format: "Tracks: %i", self.item.totalTracks)
        }
        
        self.setViewWithMusicItem(item: self.item)
        self.playingImageView.frame = CGRect(x: 18, y: 10, width: 30, height: 30);
        self.playingImageView.animates = false
        self.playingImageView.image = NSImage(named: NSImage.Name(rawValue: "playing.gif"))
        self.playingImageView.canDrawSubviewsIntoLayer = true
        self.playingImageView.isHidden = true
        self.addSubview(self.playingImageView)
        

        self.setPlaying(isPlaying: false)
    }
    
    func setArtistLinkAndAlbumLink() {
        // Position the albumlink next to artistlink
        if self.item.albumId != nil && self.item.albumTitle != nil && self.item.isAlbum == false {
            self.albumLink.frame = CGRect(
                x: 10 + self.artistLink.textWidthAdjusted + self.artistLink.frame.origin.x,
                y: self.albumLink.frame.origin.y,
                width: 200 - self.artistLink.textWidthAdjusted - 10,
                height: self.albumLink.frame.size.height
            );
            self.albumLink.isHidden = false
            self.albumLink.customTitle = self.item.albumTitle!
            self.albumLink.setNeedsDisplay()
        }
        
        if self.artistLink.textWidth + self.albumLink.textWidth + 10 < 198 {
            self.artistLink.frame = CGRect(
                x: self.artistLink.frame.origin.x,
                y: self.artistLink.frame.origin.y,
                width: self.artistLink.textWidth+2,
                height: self.artistLink.frame.size.height
            );
            self.albumLink.frame = CGRect(
                x: self.albumLink.frame.origin.x,
                y: self.albumLink.frame.origin.y,
                width: self.albumLink.textWidth+2,
                height: self.albumLink.frame.size.height
            );

        }
        
        if self.artistLink.textWidth > self.artistLink.frame.size.width {
            let length = Util.charLengthInSize(self.artistLink.customTitle, size: self.artistLink.frame.size, fontAttributes: self.artistLink.fontAttributes)
            self.artistLink.customTitle = String(format: "%@...", String(self.artistLink.customTitle.prefix(length)))
        }
        
        if self.albumLink.textWidth > self.albumLink.frame.width {
            let length = Util.charLengthInSize(self.albumLink.customTitle, size: self.albumLink.frame.size, fontAttributes: self.albumLink.fontAttributes)
            self.albumLink.customTitle = String(format: "%@...", String(self.albumLink.customTitle.prefix(length-3)))
        }
    }
    
    func setPlaying(isPlaying: Bool) {
        self.playingImageView.isHidden = !isPlaying
        self.playingImageView.animates = isPlaying
        self.darkView.isHidden = !isPlaying
        
        if self.item.hasInteractive == false {
            rBox.isHidden = false
            self.darkView.isHidden = false
        } else {
            rBox.isHidden = true
        }
    }
    
    func setPlaying(isPlaying: Bool, isFocus: Bool) {
        self.playingImageView.isHidden = !isFocus
        self.playingImageView.animates = isPlaying
        self.darkView.isHidden = !isFocus

        if item.hasInteractive == false {
            rBox.isHidden = false
            self.darkView.isHidden = false
        } else {
            rBox.isHidden = true
        }
    }
    
    @IBAction func playAction(_ sender: Any) {
        if self.item.type == MusicType.PLAYLIST || self.item.type == MusicType.ALBUM {
            self.mainVCDelegate?.cellPlayPlaylistSelectedProtocol(item: self.item)
        } else {
            if self.show_play() {
                self.mainVCDelegate?.cellSelectedProtocol(cell: self)
            }
        }
    }

    func setEnable(_ isEnabled:Bool) {
        self.thumbsUpButton.isHidden = !isEnabled
        self.thumbsDownButton.isHidden = !isEnabled
    }
    
    func setViewWithMusicItem(item: MusicItem) {
        self.item = item
        self.thumbsUpButton.isHidden = true
        self.thumbsDownButton.isHidden = true
        if item.canFeedback() {
            if item.rating > 0 {
                self.thumbsUpButton.isToggle = true
                self.thumbsDownButton.isToggle = false
            } else if item.rating < 0 {
                self.thumbsUpButton.isToggle = false
                self.thumbsDownButton.isToggle = true
            } else {
                self.thumbsUpButton.isToggle = false
                self.thumbsDownButton.isToggle = false
            }
        } else {
            self.setEnable(false)
        }
        self.largeDarkView.alphaValue = 0
        self.largeDarkView.wantsLayer = true
        self.largeDarkView.layer?.backgroundColor = CGColor.black
    }
    
    // Actions
    @IBAction func loadArtist(_ sender: Any) {
        self.mainVCDelegate?.cellArtistSelectedProtocol(item: self.item)
    }

    @IBAction func loadAlbum(_ sender: Any) {
        self.mainVCDelegate?.cellAlbumSelectedProtocol(item: self.item)
    }
    
    @IBAction func thumbsDown(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let trackToken = self.item.trackToken!
        print(item.rating)
        
        if self.thumbsDownButton.isToggle {
            appDelegate.api.deleteFeedback(trackToken: trackToken, isPositive: false) { responseDict in
                print("UNTHUMBDOWN Feedback response: ")
                print(responseDict)
                appDelegate.history.storeThumbForId(pandoraId: self.item.pandoraId!, rating: 0)
            }
        } else {
            appDelegate.api.addFeedback(trackToken: trackToken, isPositive: false) { responseDict in
                print("THUMBSDOWN Feedback response: ")
                print(responseDict)
                
                appDelegate.history.storeThumbForId(pandoraId: self.item.pandoraId!, rating: -1)
            }
        }
        self.thumbsDownButton.isToggle = !self.thumbsDownButton.isToggle
        self.thumbsUpButton.isToggle = false
    }
    
    @IBAction func thumbsUp(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let trackToken = self.item.trackToken!
        if self.thumbsUpButton.isToggle {
            appDelegate.api.deleteFeedback(trackToken: trackToken, isPositive: false) { responseDict in
                appDelegate.history.storeThumbForId(pandoraId: self.item.pandoraId!, rating: 0)
            }
        } else {
            appDelegate.api.addFeedback(trackToken: trackToken, isPositive: true) { responseDict in
                appDelegate.history.storeThumbForId(pandoraId: self.item.pandoraId!, rating: 1)
            }
        }
        self.thumbsDownButton.isToggle = false
        self.thumbsUpButton.isToggle = !self.thumbsUpButton.isToggle
    }
    
    @IBAction func shuffle(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if self.shuffleButton.isToggle {
            // minimum 1 station must always be enabled for shuffle
            if appDelegate.radio.shuffleStations.count > 1 {
                // Get station to remove from shuffle list
                if let index = appDelegate.radio.shuffleStations.firstIndex(of: self.item.stationId!) {
                    appDelegate.radio.shuffleStations.remove(at: index)
                }
            }
        } else {
            // add station to shuffle
            appDelegate.radio.shuffleStations.append(self.item.stationId!)
        }
        
        appDelegate.api.shuffleStation(stationsIds: appDelegate.radio.shuffleStations) {  responseDict in
            if let stationIds = responseDict["shuffleStationIds"] {
                appDelegate.radio.shuffleStations = stationIds as! [String]
                if appDelegate.radio.shuffleStations.contains(self.item.stationId!) {
                    self.shuffleButton.isToggle = true
                } else {
                    self.shuffleButton.isToggle = false
                }
            }
        }
    }
}
