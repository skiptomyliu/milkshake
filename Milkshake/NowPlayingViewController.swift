//
//  NowPlayingViewController.swift
//  Milkshake
//
//  Created by Dean Liu on 12/28/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

// MARK: - NSTextFieldDelegate
extension NowPlayingViewController: MusicChangedProtocol {
    // MusicChangedProtocol (driven by Music.swift)
    
    func musicChangedProtocol(item:MusicItem) {
        self.setEnable(true)
        self.setViewWithMusicItem(item: item)
    }
    
    func musicPlayedProtocol() {
        self.playButton.isToggle = true
    }
    
    func musicPausedProtocol() {
        self.playButton.isToggle = false
    }
}


class NowPlayingViewController: NSViewController {
    @IBOutlet weak var darkView: NSView!
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var animImageView: NSImageView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
    @IBOutlet weak var noMusicTextField: NSTextField!
    
    @IBOutlet weak var thumbsDownButton: PlayerButton!
    @IBOutlet weak var thumbsUpButton: PlayerButton!
    @IBOutlet weak var skipButton: PlayerButton!
    @IBOutlet weak var repeatButton: PlayerButton!
    @IBOutlet weak var playButton: PlayerButton!
    @IBOutlet weak var artistLink: FlatButton!
    @IBOutlet weak var albumLink: FlatButton!
    
    @IBOutlet weak var spectrumView: SpectrumAnalyzerView!
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    weak var mainVCDelegate: CellSelectedProtocol?
    var item:MusicItem = MusicItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let area = NSTrackingArea.init(rect:CGRect(x: 0, y: 100, width: self.view.frame.width, height: 100), options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.imageView.addTrackingArea(area)
        self.initState()
        self.setEnable(false)
    }
    
    func setRandomAnim() {
        self.animImageView.alphaValue = 1
        self.imageView.alphaValue = 0
        self.animImageView.wantsLayer = true
        self.animImageView.canDrawSubviewsIntoLayer = true
        let imageName = String(format:"%lu.gif",arc4random_uniform(29));
        self.animImageView.image = NSImage(named: NSImage.Name(rawValue: imageName))
        self.animImageView.animates = true
    }
    
    func initState() {
        self.darkView.alphaValue = 0
        self.darkView.wantsLayer = true
        self.darkView.layer?.backgroundColor = CGColor.black
        self.thumbsUpButton.alphaValue = 0
        self.thumbsDownButton.alphaValue = 0
        self.skipButton.alphaValue = 0
        self.repeatButton.alphaValue = 0
        self.playButton.alphaValue = 0
        self.albumLink.alphaValue = 0
    }
    
    func setEnable(_ isEnabled:Bool) {
        self.noMusicTextField.isHidden = isEnabled
        self.darkView.layer?.isHidden = !isEnabled
        self.thumbsUpButton.isHidden = !isEnabled
        self.thumbsDownButton.isHidden = !isEnabled
        self.skipButton.isHidden = !isEnabled
        self.repeatButton.isHidden = !isEnabled
        self.playButton.isHidden = !isEnabled
        self.albumLink.isHidden = !isEnabled
    }
    
    func showHide(alpha:CGFloat, duration: Double) {
        if alpha > 0 {
            self.darkView.animator().alphaValue = 0.8
        } else {
            self.darkView.animator().alphaValue = 0
        }
        self.thumbsUpButton.animator().alphaValue = alpha
        self.thumbsDownButton.animator().alphaValue = alpha
        self.skipButton.animator().alphaValue = alpha
        self.repeatButton.animator().alphaValue = alpha
        self.playButton.animator().alphaValue = alpha
        self.albumLink.animator().alphaValue = alpha
        NSAnimationContext.runAnimationGroup({(context) -> Void in
            context.duration = duration
        }) {
            // animation done
        }
    }
    override func mouseEntered(with event: NSEvent) {
        showHide(alpha: 0.9, duration: 0.7)
    }
    
    override func mouseExited(with event: NSEvent) {
        showHide(alpha: 0.0, duration: 0.7)
    }
    
    func setViewWithMusicItem(item: MusicItem) {
        self.item = item
        self.titleTextField.stringValue = item.name!
        self.subtitleTextField.stringValue = item.artistName!
        self.albumLink.setNeedsDisplay()
        if let playlistName = item.playlistName {
            self.albumLink.customTitle = playlistName
        }
        else if let albumTitle = item.albumTitle {
            if item.albumId != nil { // use albumSeoToken for stations?
                self.albumLink.customTitle = albumTitle
            } else {
                self.albumLink.customTitle = ""
                self.albumLink.isHidden = true
            }
        }

        self.albumLink.fontColor = NSColor.white
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        self.albumLink.textStyle = textStyle
        self.albumLink.setNeedsDisplay()
        
        self.artistLink.isHidden = false
        self.artistLink.customTitle = item.artistName!
        self.artistLink.fontColor = NSColor.white
        self.artistLink.textStyle = textStyle
        self.artistLink.setNeedsDisplay()
        
        if item.audioURL == nil {
            self.isStation = false
        } else {
            self.isStation = true
            if item.rating > 0 {
                self.thumbsUpButton.isToggle = true
            } else {
                self.thumbsUpButton.isToggle = false
            }
        }
        
        let type = item.type
        if type == MusicType.ALBUM || type == MusicType.TRACK {
            self.subtitleTextField.stringValue = item.artistName!
        }
        
        if appDelegate.isArtAnimate {
            self.setRandomAnim()
        } else {
            self.animImageView.alphaValue = 0
            self.imageView.alphaValue = 1
            if let albumArt = item.albumArt {
                if albumArt != "" {
                    let url = URL(string: albumArt)
                    self.imageView.kf.setImage(with: url, completionHandler: {
                        (image, error, cacheType, imageUrl) in
                        //                    print(image?.size)
                    })
                } else {
                    self.imageView.image = NSImage(named: NSImage.Name(rawValue: "album-500.png"))
                }
            }
        }
        
        // spectrum
        if let color = item.dominantColor {
            self.spectrumView.barFillColor = NSColor(hex: color)
        } else {
            self.spectrumView.barFillColor = NSColor(calibratedRed: 250/255.0, green: 148/255.0, blue: 55/255.0, alpha: 0.55)
        }
    }
    
    var isStation: Bool = false {
        willSet {
            if newValue == true {
                self.thumbsUpButton.isHidden = false
                self.thumbsDownButton.isHidden = false
            } else {
                self.thumbsUpButton.isHidden = true
                self.thumbsDownButton.isHidden = true
                
                if appDelegate.dj.tracks.count <= 1 && appDelegate.radio.stationTracks.count > 0 {
                    self.skipButton.isHidden = false
                }
                else if appDelegate.dj.tracks.count > 1 {
                    self.skipButton.isHidden = false
                } else {
                    self.skipButton.isHidden = true
                }
            }
        }
        didSet { }
    }
    
    var animateSpectrum: Bool = true {
        willSet {
            if (newValue == true) {
                self.spectrumView.isHidden = false
            } else{
                self.spectrumView.isHidden = true
            }
        }
        didSet { }
    }
    
    // Actions
    @IBAction func thumbsDown(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.radio.thumbDown()
    }
    
    @IBAction func thumbsUp(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.radio.thumbUp()
        self.thumbsUpButton.isToggle = !self.thumbsUpButton.isToggle
    }
    
    @IBAction func skipSong(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.music?.playNext()
    }
    
    @IBAction func playPause(_ sender: Any) {
        if let music = appDelegate.music {
            if music.isPlaying() {
                music.playerPause()
            } else {
                music.playerPlay()
            }
        }
    }
    
    @IBAction func repeatSong(_ sender: Any) {
        appDelegate.music?.playerRepeat()
    }
    
    @IBAction func loadArtistAction(_ sender: Any) {
        self.mainVCDelegate?.cellArtistSelectedProtocol(item: item)
    }
    
    @IBAction func loadAlbumAction(_ sender: Any) {
        
        if item.playlistName != nil {
            self.mainVCDelegate?.cellPlaylistSelectedProtocol(item: self.item)
        }
        else if item.albumTitle != nil {
            self.mainVCDelegate?.cellAlbumSelectedProtocol(item: self.item)
        }
        showHide(alpha: 0.0, duration: 0.0)
    }
    
}
