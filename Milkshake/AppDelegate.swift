//
//  AppDelegate.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa
import HotKey

extension NSStoryboard {
    
    private class func mainStoryboard() -> NSStoryboard { return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil) }
    
    private class func loginStoryboard() -> NSStoryboard { return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil) }
    
    class func mainViewController() -> MainViewController {
        return self.mainStoryboard().instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "MainViewController")) as! MainViewController
    }
    
    class func windowController() -> NSWindowController {
        return self.mainStoryboard().instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WindowController")) as! NSWindowController
    }
    
    class func loginWindowController() -> NSWindowController {
        return self.mainStoryboard().instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "LoginWindowController")) as! NSWindowController
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, LoginProtocol {

    var api: API
    var music: Music? // pointer to either dj or radio
    var dj: DJ
    var radio: Radio
    var history: History
    var windowController: NSWindowController?
    var loginWindowController: NSWindowController?
    var isArtAnimate: Bool = false
    var isSpectrumAnimate: Bool = true
    var isPremium: Bool = false
    var listenerId: String = ""
    
    var statusItem: NSStatusItem?
    
    @IBOutlet weak var menuKeepWindowFront: NSMenuItem!
    @IBOutlet weak var menuCrossFade: NSMenuItem!
    @IBOutlet weak var menuShuffle: NSMenuItem!
    @IBOutlet weak var menuSpectrum: NSMenuItem!
    @IBOutlet weak var menuPlaylist: NSMenuItem!
    @IBOutlet weak var menuArtists: NSMenuItem!
    @IBOutlet weak var menuHistory: NSMenuItem!
    
    
    private var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                return
            }

            hotKey.keyDownHandler = { [weak self] in
                print(hotKey.keyCombo)
                let keyCode = hotKey.keyCombo.carbonKeyCode
                let modifier = hotKey.keyCombo.carbonModifiers
                let mainVc = self?.windowController?.contentViewController as! MainViewController
                if keyCode == 0x12 && modifier == 0x100 { mainVc.loadNowPlaying(self!) }
                else if keyCode == 0x13 && modifier == 0x100 {
                    mainVc.loadStationResults(self!)
                }
                else if keyCode == 0x14 && modifier == 0x100 && self!.isPremium {
                    mainVc.loadPlaylistResults(self!)
                }
                    // u
                else if keyCode == 0x31 && modifier == 0x1100 { mainVc.showWindow() }
                    // p
                else if keyCode == 0x23 && modifier == 0x1100 {
                    if let music = self?.music {
                        if music.isPlaying() {
                            music.playerPause()
                        } else {
                            music.playerPlay()
                        }
                    }
                }
                    // r
                else if keyCode == 0xF && modifier == 0x1100 {
                    if let music = self?.music {
                        if music.isPlaying() {
                            music.playerRepeat()
                        }
                    }
                }
                    // [
                else if keyCode == 0x1E && modifier == 0x1100 {
                    if let music = self?.music {
                        if music.isPlaying() {
                            music.playNext()
                        }
                    }
                }
                    // ]
                else if keyCode == 0x21 && modifier == 0x1100 {
                    if let music = self?.music {
                        if music.isPlaying() {
                            music.playPrev()
                        }
                    }
                }
                    // -
                else if keyCode == 0x1B && modifier == 0x1100 {
                    if (self?.radio.isPlaying())! {
                        self?.radio.thumbDown()
                    }
                }
                    // +
                else if keyCode == 0x18 && modifier == 0x1100 {
                    if (self?.radio.isPlaying())! {
                        mainVc.nowPlayingViewController.thumbsUp(self!)
                    }
                }
            }
        }
    }
    
    override init() {
        self.api = API()
        self.dj = DJ()
        self.radio = Radio()
        self.history = History()
        super.init()
    }

    @IBOutlet weak var toolbarMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        self.loginWindowController = NSStoryboard.loginWindowController()
        (self.loginWindowController!.contentViewController as! LoginViewController).delegate = self
        self.loginWindowController?.window?.isMovableByWindowBackground = true
        self.loginWindowController!.showWindow(self)
        
        OperationQueue.main.addOperation {
            self.loginWindowController!.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        self.loginWindowController!.window?.makeKey()
        self.loginWindowController!.window?.makeKeyAndOrderFront(nil)
        self.api.X_AuthToken = "BI2rvoepGAXRGYy3Yr9iVFh7fL+FAYfWG4hJpRtIVdB2DZenI/yXST/g=="
        initStatusItem()
//        self.launchMain()
    }
    
    
    
    
    private func initStatusItem() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        statusItem?.title = "Test Item"
        let icon = NSImage(named: NSImage.Name(rawValue: "milkshake_20x20.png"))
        icon?.isTemplate = true
        statusItem?.image = icon
        statusItem?.menu = self.toolbarMenu
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
         NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: keyDown);
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.showWindow()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        if let window = self.windowController?.window {
            if flag {
                window.orderFront(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        } else if let window = self.loginWindowController?.window {
            if flag {
                window.orderFront(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
    
    func keyDown(event: NSEvent!) -> NSEvent {
        if let mvc = NSApplication.shared.mainWindow?.windowController?.contentViewController as? MainViewController {
            // cmd + w
            if Int(event.modifierFlags.rawValue) == 0x100108 && event.keyCode == 0xD {
                mvc.hideWindow()
            } else if event.keyCode == 0x7D || event.keyCode == 0x7E {
                if mvc._curViewController is ResultsViewController {
                    var idx = 0
                    let rc = mvc._curViewController as! ResultsViewController
                    if(rc.searchTableView.selectedRow < 0) {
                        idx = 0;
                    } else {
                        idx = rc.searchTableView.selectedRow ;
                    }
                    rc.searchTableView.selectRowIndexes(NSIndexSet(index: idx) as IndexSet, byExtendingSelection: false)
                    mvc.view.window?.makeFirstResponder(rc.searchTableView)
                }
            } else if event.keyCode == 0x35 {
                mvc.escKeyProtocol()
            } else {
//                mvc.view.window?.makeFirstResponder(mvc.searchField)
            }

        }
        return event
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func launchMain() {
        OperationQueue.main.addOperation {
            self.windowController = NSStoryboard.windowController()
            self.windowController!.showWindow(self)
            self.windowController!.loadWindow()
            self.windowController!.window?.makeKeyAndOrderFront(self)
            self.windowController!.window?.center()
            self.windowController?.window?.isMovableByWindowBackground = true
            self.register(self) // hotkeys
            self.loginWindowController?.close()
        }

//        if let bid = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: bid)
//        }
    }
    
    func handleSuccessLogin(results: Dictionary<String, AnyObject>) {
        print(results)
        let authToken = results["authToken"] as! String
        let config = results["config"] as! [String: AnyObject]
        self.isPremium = (config["branding"] as! String).lowercased() == "pandorapremium"
        self.listenerId = results["listenerId"] as! String
        
        if self.isPremium == false {
            self.menuArtists.isHidden = true
            self.menuPlaylist.isHidden = true
        }
        // Setting
        let defaults = UserDefaults.standard
        defaults.set(authToken, forKey: "authToken")
        self.api.X_AuthToken = authToken
        print ("x auth token....")
        print(self.api.X_AuthToken!)
        self.launchMain()
    }

    func isRadio() -> Bool {
        return self.music == self.radio
    }

    @IBAction func showWindowAction(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.showWindow()
        }
    }
    
    @IBAction func playPause(_ sender: Any) {
        if let music = self.music {
            if music.isPlaying() {
                music.playerPause()
            } else {
                music.playerPlay()
            }
        }
    }
    
    @IBAction func previousSong(_ sender: Any) {
        if let music = self.music {
            music.playPrev()
        }
    }
    
    @IBAction func nextSong(_ sender: Any) {
        if let music = self.music {
            music.playNext()
        }
    }
    
    @IBAction func repeatSong(_ sender: Any) {
        if let music = self.music {
            music.playerRepeat()
        }
    }
    
    @IBAction func thumbDown(_ sender: Any) {
        if let music = self.music {
            if music is Radio {
                (music as! Radio).thumbDown()
            }
        }
    }
    
    @IBAction func thumbUp(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.nowPlayingViewController.thumbsUp(self)
        } else if let music = self.music {
            if music is Radio {
                (music as! Radio).thumbUp()
            }
        }
    }
    
    @IBAction func loadPlaying(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.loadNowPlaying(self)
        }
    }
    
    @IBAction func loadStations(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.loadStationResults(self)
        }
    }
    
    @IBAction func loadPlaylist(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.loadPlaylistResults(self)
        }
    }
    
    @IBAction func loadArtists(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.loadArtistResults(self)
        }
    }
    
    @IBAction func loadHistory(_ sender: Any) {
        if let cvc = self.windowController?.contentViewController {
            let mainVC = cvc as! MainViewController
            mainVC.loadHistoryResults(self)
        }
    }
    
    @IBAction func keepWindowFront(_ sender: Any) {
        if self.menuKeepWindowFront.title == "Keep Window Front" {
            self.menuKeepWindowFront.title = "Disable Window Front"
            self.windowController?.window?.level = NSWindow.Level.statusBar
        } else {
            self.menuKeepWindowFront.title = "Keep Window Front"
            self.windowController?.window?.level = NSWindow.Level.normal
        }
    }
    
    @IBAction func enableSpectrum(_ sender: Any) {
        
        if self.menuSpectrum.title == "Enable Spectrum" {
            self.menuSpectrum.title = "Disable Spectrum"
            self.isSpectrumAnimate = true
            if let cvc = self.windowController?.contentViewController {
                let mainVC = cvc as! MainViewController
                mainVC.nowPlayingViewController.animateSpectrum = true
            }
        } else {
            self.menuSpectrum.title = "Enable Spectrum"
            self.isSpectrumAnimate = false
            if let cvc = self.windowController?.contentViewController {
                let mainVC = cvc as! MainViewController
                mainVC.nowPlayingViewController.animateSpectrum = false
            }
        }
    }
    
    @IBAction func enableCrossFade(_ sender: Any) {
        if self.menuCrossFade.title == "Enable Crossfade" {
            self.menuCrossFade.title = "Disable Crossfade"
            self.dj.crossFade = true
            self.radio.crossFade = true

        } else {
            self.menuCrossFade.title = "Enable Crossfade"
            self.dj.crossFade = false
            self.radio.crossFade = false
        }
    }
    
    @IBAction func enableShuffle(_ sender: Any) {
        if self.menuShuffle.title == "Enable Shuffle" {
            self.menuShuffle.title = "Disable Shuffle"
            self.dj.shuffle = true
            
        } else {
            self.menuShuffle.title = "Enable Shuffle"
            self.dj.shuffle = false
        }
    }

    @IBAction func unregister(_ sender: Any?) {
        hotKey = nil
    }
    
    @IBAction func register(_ sender: Any?) {
        hotKey = HotKey(keyCombo: KeyCombo(key: .minus, modifiers: [.command, .control]))
        hotKey = HotKey(keyCombo: KeyCombo(key: .equal, modifiers: [.command, .control]))
        hotKey = HotKey(keyCombo: KeyCombo(key: .space, modifiers: [.command, .control])) // bring up menu
        hotKey = HotKey(keyCombo: KeyCombo(key: .p, modifiers: [.command, .control])) //play/pause
        hotKey = HotKey(keyCombo: KeyCombo(key: .r, modifiers: [.command, .control])) //repeat
        hotKey = HotKey(keyCombo: KeyCombo(key: .leftBracket, modifiers: [.command, .control])) //next track
        hotKey = HotKey(keyCombo: KeyCombo(key: .rightBracket, modifiers: [.command, .control])) //prev track
//        hotKey = HotKey(keyCombo: KeyCombo(key: .one, modifiers: [.command])) //now playing
//        hotKey = HotKey(keyCombo: KeyCombo(key: .two, modifiers: [.command])) //stations
//        hotKey = HotKey(keyCombo: KeyCombo(key: .three, modifiers: [.command])) //playlist
    }
}

