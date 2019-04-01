//
//  Music.swift
//  Milkshake
//
//  Created by Dean Liu on 12/1/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Base class that DJ.swift and Radio.swift inherit from
//  There are two AVPlayers that cross fade between the two
//  _ptr_player0, and _ptr_player1 swap back and forth to determine
//    which player will do the fading
//
import Cocoa
import AVKit
import AVFoundation
import Accelerate

class Music: NSObject {
    
    // AVPlayer objects that contain the playeritems
    private var player0 = AVPlayer.init()
    private var player1 = AVPlayer.init()
    
    // pointers to player0 or player1.  Used for crossfading
    private var _cur_player:AVPlayer    // Current active playing player
    private var _ptr_player0:AVPlayer   // Used for cross fading.
    private var _ptr_player1:AVPlayer   // Used for cross fading
    private var _crossFadeTask:DispatchWorkItem?
    
    weak var playerVCDelegate: MusicTimeProtocol?
    weak var mainVCDelegate: MusicChangedProtocol?
    weak var menuVCDelegate: MusicChangedProtocol?
    weak var nowVCDelegate: MusicChangedProtocol?
    
    let tapManager = TapManager.init()
    
    var curPlayingItem: MusicItem = MusicItem()
    var timeObserverToken: Any?
    var crossFade = true
    
    var MAXFAILS = 5 // failures before stopping to proceed to next track.  Used for Radio
    var curFail = 0  // current number of failures
    var baseVolume = Float(1.0)
    
    override init() {
        self._cur_player = self.player0
        self._ptr_player0 = self.player0
        self._ptr_player1 = self.player1
        self._ptr_player0.volume = self.baseVolume
        self._ptr_player1.volume = 0.0
        super.init()
    }
    
    func playAudio(item: MusicItem, url: String) {
        // Error handling
        // Only play if there's length
        let asset = AVURLAsset(url: URL(string: url)!)
        let playableKey = "playable"
        // Load the "playable" property
        self.mainVCDelegate?.musicLoadingIndicatorProtocol(isStart: true)
        asset.loadValuesAsynchronously(forKeys: [playableKey]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: playableKey, error: &error)
            let playerItem = AVPlayerItem(asset: asset)
            let length = Float(item.duration)
            print("Music - URL: ", url)
            item.duration = Int(length)
            self.curPlayingItem = item
            DispatchQueue.main.sync {
                self.removeTimeObserver()
            }
            DispatchQueue.main.async {
                self._playAudio(playerItem: playerItem)
            }
            switch status {
            case .loaded:
                let tap = self.tapManager.tap()
                let length = Float(playerItem.asset.duration.value)/Float(playerItem.asset.duration.timescale)
                if length > 0.0  {
                    if let audioTrack = playerItem.asset.tracks(withMediaType: AVMediaType.audio).first {
                        let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
                        inputParams.audioTapProcessor = tap?.takeUnretainedValue()
                        let audioMix = AVMutableAudioMix()
                        audioMix.inputParameters = [inputParams]
                        playerItem.audioMix = audioMix
                    }
                } else {
                    self.curFail += 1
                    if self.curFail < self.MAXFAILS {
                        self.playNext()
                    } else{
                        print("MAX FAILS REACHED")
                    }
                }
                break
            case .failed:
                // Handle error
                self.mainVCDelegate?.musicLoadingIndicatorProtocol(isStart: false)
                break
            case .cancelled:
                self.mainVCDelegate?.musicLoadingIndicatorProtocol(isStart: false)
                break
            // Terminate processing
            default:
                self.mainVCDelegate?.musicLoadingIndicatorProtocol(isStart: false)
                break
            }
        }
        
    }
    
    func setVolume(value: Float) {
        self._cur_player.volume = value
    }
    
    func swapPlayer() {
        // original init setup
        if self._ptr_player0 == self.player1 {
            self._cur_player = self.player0
            self._ptr_player0 = self.player0
            self._ptr_player1 = self.player1
        } else { // swapped setup
            self._cur_player = self.player1
            self._ptr_player1 = self.player0
            self._ptr_player0 = self.player1
        }
    }
    
    func crossFade(player1: AVPlayer, player2: AVPlayer, completion: @escaping () -> Void) {
        if player1.volume > 0 {
            player1.volume = player1.volume - 0.02
            player2.volume = player2.volume + 0.02
            
            self._crossFadeTask = DispatchWorkItem {
                self.crossFade(player1: player1, player2: player2, completion: completion)
            }
            // execute task in .2 seconds
            let delay = self.crossFade ? 0.15 : 0.00001
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: self._crossFadeTask!)
            
        } else {
            player1.pause()
            completion()
        }
    }
    
    func removeTimeObserver() {
        if let obsToken = self.timeObserverToken {
            self._cur_player.removeTimeObserver(obsToken)
            self.timeObserverToken = nil
        }
    }
    
    private func _playAudio(playerItem: AVPlayerItem) {
        self.removeTimeObserver()
        print("player rate", self.player0.rate)
        if self._ptr_player0.rate != 0 {
            self._ptr_player1.replaceCurrentItem(with: playerItem)
            self._ptr_player1.play()
            if let task = self._crossFadeTask {
                task.cancel()
            }
            self.crossFade(player1: self._ptr_player0, player2: self._ptr_player1) {
                print("Done fading....")
            }
            self.swapPlayer()
        } else { // only one item playing, initial launch
            self._ptr_player0.replaceCurrentItem(with: playerItem)
            self._ptr_player0.play()
        }
        
        DispatchQueue.main.async {
            self.mainVCDelegate?.musicLoadingIndicatorProtocol(isStart: false)
        }
        self._addTimeObserver(playerItem: playerItem)
        
        self.nowVCDelegate!.musicPlayedProtocol()
        self.nowVCDelegate!.musicChangedProtocol(item: self.curPlayingItem)
        self.mainVCDelegate!.musicPlayedProtocol()
        self.mainVCDelegate!.musicChangedProtocol(item: self.curPlayingItem)
        self.menuVCDelegate!.musicPlayedProtocol()        
    }
    
    func addTimeObserver() {
        if let playerItem = self._cur_player.currentItem {
            self._addTimeObserver(playerItem: playerItem)
        }
    }
    
    func _addTimeObserver(playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.itemDidFinishPlaying(notification:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        let interval = CMTime(seconds: 0.7,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        self.timeObserverToken =
            self._cur_player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) {
                [weak self] time in
                // update player transport UI
                self?.playerVCDelegate!.updateMusicTimeProtocol(duration: Float(CMTimeGetSeconds((self?._cur_player.currentItem?.currentTime())!)), totalTime: Float(CMTimeGetSeconds((self?._cur_player.currentItem?.duration)!)))
        }
    }
    
    
    func playerPlay() {
        if isPlaying() == false {
            self._cur_player.play()
            self.nowVCDelegate!.musicPlayedProtocol()
            self.mainVCDelegate!.musicPlayedProtocol()
            self.menuVCDelegate!.musicPlayedProtocol()
        }
    }
    
    func playerPause() {
        if isPlaying() {
            self._cur_player.pause()
            self.nowVCDelegate!.musicPausedProtocol()
            self.mainVCDelegate!.musicPausedProtocol()
            self.menuVCDelegate!.musicPausedProtocol()
        }
    }
    
    // Remove current playing item and stop
    func playerStop() {
        if isPlaying() {
            self._cur_player.pause()
            self.removeTimeObserver()
            self._cur_player.replaceCurrentItem(with: nil)
        }
    }

    func playerRepeat() {
        self._cur_player.currentItem?.seek(to: kCMTimeZero, completionHandler: nil)
    }
    
    func scrub(toPercent: Double) {
        let duration = Double(CMTimeGetSeconds((self.player0.currentItem?.duration)!))
        let seconds = Int(toPercent * duration)
        let secondsCMTime = CMTimeMake(Int64(seconds), 1)
        self._cur_player.seek(to: secondsCMTime)
    }
    
    func isPlaying() -> Bool {
        if _cur_player.error == nil && _cur_player.rate != 0 {
            return true
        }
        return false
    }
    
    func musicPreflightChange() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if let music = appDelegate.music {
            self.mainVCDelegate!.musicPreflightChangedProtocol(item: music.curPlayingItem)
        }
        appDelegate.music = self
    }
    
    func nowPlaying() -> String {
        fatalError("This method must be overridden")
    }
    
    func playNext() {
        fatalError("This method must be overridden")
    }
    
    func playPrev() {
        fatalError("This method must be overridden")
    }
    
    @objc func itemDidFinishPlaying(notification: NSNotification) {
        preconditionFailure("This method must be overridden")
    }
}
