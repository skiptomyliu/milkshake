//
//  MusicItem.swift
//  Milkshake
//
//  Created by Dean Liu on 12/5/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  API call results get parsed into MusicItem types
//

import Cocoa

enum MusicType {
    case TRACK
    case STATION
    case ARTIST
    case PLAYLIST
    case ALBUM
    case COMPOSER
    case UNDEFINED
}

enum CellType {
    case SEARCH
    case ARTIST
    case ALBUM
    case PLAYLIST
    case UNDEFINED
}

class MusicItem: NSObject {
    // Related to cell display in ResultsViewController:
    var isHeader: Bool = false
    var isArtist: Bool = false
    var isAlbum: Bool = false
    var cellType: CellType = CellType.SEARCH
    
    var name: String?
    var artistName: String?
    var pandoraId: String?
    var artistId: String?
    var playlistId: String? // our own
    var playlistName: String? // our own
    var dominantColor: String?
    var albumId: String?
    var albumTitle: String?
    var albumSeoToken: String?
    var type: MusicType?
    var explicitness: String?
    var latestRelease: Bool?
    var token: String?
    var lastPlayed: String?
    var allowSkip: String?
    var hasInteractive = true // on demand or not
    
    var shareableUrlPath: String?

    // station
    var userSeed: String?
    var trackToken: String?
    var stationId: String?
    var audioURL: String?
    var musicId: String?
    var dateCreated: String?
    var releaseDate: String?
    var isShuffle: String?
    var isThumbprint: String?
    var artId: String?
    var genre: String?
    var creatorWebname: String?
    var totalPlayTime: String?
    var listenerCount: Int = 0
    var rights: [String]?
    var rating: Int = 0
    
    // playlist
    var totalTracks = 0
    var albumArt: String?
    var duration = -1
    var thorLayers: String?
    var thorLayersRaw: String = "" {
        willSet {
            var rawGrid = newValue
            if rawGrid.range(of:"_;grid(") != nil {
                rawGrid = String(rawGrid.dropFirst(7))
                rawGrid = String(rawGrid.dropLast(1))
                let urlString = rawGrid.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                self.thorLayers = String(format:"https://dyn-images.p-cdn.com/?l=_%3Bgrid(%@)&w=500&h=500", urlString)
                self.albumArt = String(format:"https://dyn-images.p-cdn.com/?l=_%%3Bgrid(%@)&w=500&h=500", urlString)
            } else {
                var urlString = rawGrid.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)!
                urlString = urlString.replacingOccurrences(of: ";", with: "%3b")

                self.albumArt = String(format:"https://dyn-images.p-cdn.com/?l=%@&w=500&h=500", urlString)
            }
            
        }
        didSet { }
        
    }
    
    // Artist Details
    var heroImage: String?
    var heroImageRaw: String = "" {
        willSet {
            self.heroImage = "https://content-images.p-cdn.com/\(newValue)_500W_500H.jpg"
            self.albumArt = "https://content-images.p-cdn.com/\(newValue)_500W_500H.jpg"
        }
        didSet { }
    }
}
