//
//  DJ.swift
//  Milkshake
//
//  Created by Dean Liu on 11/28/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
import Cocoa
import AVKit

class DJ: Music {

    var tracks: [MusicItem] = []
    var tracksShuffled: [MusicItem] = []
    var tracksOrdered: [MusicItem] = []
    private var tracksStr: [String] = []
    private var tracksIdx = -1
    private var isShuffled = false
    
    var shuffle: Bool = false {
        willSet{
            if self.isShuffled == false && newValue == true {
                self.enableShuffle()
            } else if newValue == false {
                self.tracks = self.tracksOrdered
            }
        }
        didSet { }
    }
    
    // On Demand callbackAudio
    func callbackAudio(result: [String: AnyObject]) {
        if let response = result["response"] as?  [String: AnyObject],
           let musicItem = result["musicItem"] as? MusicItem {
            if let audioUrlStr = response["audioURL"] as? String {
                self.playAudio(item:musicItem, url: audioUrlStr)
            }
        }
    }
    
    func playTrack(musicItem: MusicItem) {
        print ("playing track")
        self.musicPreflightChange()
//        appDelegate.api.getAudioPlaybackInfoPandoraId(pid: musicItem.pandoraId!, sid: musicItem.albumId!, callbackHandler: callbackAudio)
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.api.getAudioPlaybackInfoPandoraId(item: musicItem, callbackHandler: callbackAudio)
        
        if self.tracks.count > 0 && self.tracksIdx < 0 {
            self.tracksIdx = self.tracksStr.index(of: musicItem.pandoraId!) ?? 0 // set current playing index track
        }
//        self.curPlayingItem = musicItem
//        self.playTrack(trackId: musicItem.pandoraId!, albumId: musicItem.albumId!)
    }
    
    func reset() {
        self.tracksIdx = -1
        self.isShuffled = false
        self.tracks.removeAll()
        self.tracksStr.removeAll()
        self.tracksShuffled.removeAll()
        self.tracksOrdered.removeAll()
    }
    
    func setWithAlbum(items: [MusicItem]) {
        self.reset()
        
        for item in items {
            self.tracksStr.append(item.pandoraId!)
            self.tracks.append(item)
        }
    }
    
    func enableShuffle() {
        for track in tracks {
            self.tracksShuffled.append(track)
            self.tracksOrdered.append(track)
            print("enabling shuffle...")
        }
        self.tracksShuffled.shuffle()
        self.tracks = self.tracksShuffled
        self.isShuffled = true
    }
    
    override func playNext() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if self.isShuffled == false && self.shuffle {
            self.enableShuffle()
        }
        if self.tracks.count > 0 {
            // XXX Switching to radio wont save the track
            // nested here because radio.playNext will cause double preflight
//            self.musicPreflightChange()
            self.tracksIdx = (self.tracksIdx + 1) % (self.tracks.count)
            let nextTrack = self.tracks[self.tracksIdx]
            if nextTrack.hasInteractive {
                self.playTrack(musicItem: nextTrack)
            } else if self.tracksIdx != 0 { // we're at the end, prevent infinite loop
                self.playNext()
            }
        } else if appDelegate.radio.stationTracks.count > 0 {
            // If no more tracks and radio is set, play station (for when playing history)
            self.playerStop()
            appDelegate.radio.playNext()
        }
    }
    
    override func playPrev() {
        if self.tracks.count > 0 {
            self.tracksIdx = (self.tracksIdx - 1) % (self.tracks.count)
            self.tracksIdx = self.tracksIdx < 0 ? self.tracks.count-1:self.tracksIdx
            let prevTrack = self.tracks[self.tracksIdx]
            print("DJ play prev", self.tracksIdx)
            if prevTrack.hasInteractive {
                self.playTrack(musicItem: prevTrack)
            } else if self.tracksIdx != self.tracks.count-1 { // we're at the start, prevent infinite loop
                self.playPrev()
            }
        }
    }
    
    @objc override func itemDidFinishPlaying(notification: NSNotification) {
        if self.crossFade == false {
            self.playNext()
        }
    }
    
    override func nowPlaying() -> String {
        return self.curPlayingItem.pandoraId ?? ""
    }
}
