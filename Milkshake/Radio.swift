//
//  Radio.swift
//  Milkshake
//
//  Created by Dean Liu on 12/1/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa
import AVKit

class Radio: Music {

    var stationTracks: [MusicItem] = []
    var stationIdx: Int = 0
    var isRadio = false
    var stationId = ""
    
    func playStation(stationId:String, isStationStart:Bool, lastPlayedTrackToken:String?) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.music = self
        
        self.stationId = stationId
        appDelegate.api.getPlaylistFragment(stationId: stationId, isStationStart: isStationStart, lastPlayedTrackToken: lastPlayedTrackToken) { responseDict in
            if responseDict["errorCode"] != nil {
                // If another station listening, force
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                appDelegate.api.playbackResumed(forceActive: true) { responseDict in
                    print("playback resume...");
                    
                    // recall self here?
                    /**/
                    appDelegate.api.getPlaylistFragment(stationId: stationId, isStationStart: isStationStart, lastPlayedTrackToken: lastPlayedTrackToken ) { responseDict in
                        print("AFTER FORCING!!")
                        self.stationTracks = Util.parseStationIntoItems(station: responseDict)
                        self.stationIdx = -1
                        self.playNext()
                    }
                    /**/
                }
            } else {
                self.stationTracks = Util.parseStationIntoItems(station: responseDict)
                self.stationIdx = -1
                self.playNext()
            }
        }
    }
    
    override func playNext() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        // clear existing DJ tracks
        appDelegate.dj.tracks.removeAll()

        // If token has expired, the tracks will have been cleared,
        // this will then trigger a station request for fresh tracks
        if self.stationTracks.count <= 0  {
            self.playStation(stationId: self.stationId, isStationStart: false, lastPlayedTrackToken: nil)
        } else if self.stationIdx+1 > self.stationTracks.count-1 {
            let prevToken = self.stationTracks[self.stationIdx].trackToken!
            self.playStation(stationId: self.stationId, isStationStart: false, lastPlayedTrackToken: prevToken)
        } else {
            self.stationIdx = (self.stationIdx + 1)
            let urlStr = self.stationTracks[self.stationIdx].audioURL!
            let musicItem = self.stationTracks[self.stationIdx]
            self.playAudio(item:musicItem, url: urlStr)
            // We make an additional API call to annotate for additional info we need:
            // artistId, dominant color and albumId
            if let pandoraId = musicItem.pandoraId {
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                appDelegate.api.annotateObjectsSimple(trackIds:[pandoraId]) {
                    (results) in
                    if let trackDict = results[pandoraId] as? Dictionary<String, AnyObject>  {
                        if let icon = trackDict["icon"] {
                            musicItem.dominantColor = icon["dominantColor"] as? String
                        }
                        musicItem.artistId = trackDict["artistId"] as? String
                        musicItem.albumId = trackDict["albumId"] as? String
                    }
                    self.musicPreflightChange()
//                        self.playAudio(item:musicItem, url: urlStr)
                }
            }
        }
    }
    
    override func playPrev() {
        print("Use as repeat?")
    }
    
    func thumbDown() {
        
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        let musicItem = self.stationTracks[self.stationIdx]
        let trackToken = musicItem.trackToken!
        appDelegate!.api.addFeedback(trackToken: trackToken, isPositive: false) { responseDict in
            print("Thumbsdown feedback response: ")
            print(responseDict)
        }
        self.playNext()
    }
    
    func thumbUp() {
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        let musicItem = self.stationTracks[self.stationIdx]
        let trackToken = musicItem.trackToken!
        appDelegate!.api.addFeedback(trackToken: trackToken, isPositive: true) { responseDict in
            print("Thumbsup Feedback response: ")
            print(responseDict)
        }
    }
    
    func unthumbUp() {
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        let musicItem = self.stationTracks[self.stationIdx]
        let trackToken = musicItem.trackToken!
        appDelegate!.api.deleteFeedback(trackToken: trackToken, isPositive: false) { responseDict in
            print("UNTHUMBDOWN Feedback response: ")
            print(responseDict)
            appDelegate!.history.storeThumbForId(pandoraId: musicItem.pandoraId!, rating: 0)
        }
    }
    
     @objc override func itemDidFinishPlaying(notification: NSNotification) {
        // If not crossfade, play next item.  Otherwise this will double call.
        if self.crossFade == false {
            self.playNext()
        }

    }
    
    override func nowPlaying() -> String {
        return self.stationId
    }
}
