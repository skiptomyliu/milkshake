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

enum MusicType: Int {
    case TRACK
    case STATION
    case ARTIST
    case PLAYLIST
    case ALBUM
    case COMPOSER
    case UNDEFINED
}

enum CellType: Int {
    case SEARCH
    case ARTIST
    case ALBUM
    case PLAYLIST
    case HISTORY
    case UNDEFINED
}

class MusicItem: NSObject, NSCoding {
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
    var duration: Int = -1
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
    
    required override init() {
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(artistName, forKey: "artistName")
        aCoder.encode(pandoraId, forKey: "pandoraId")
        aCoder.encode(artistId, forKey: "artistId")
        aCoder.encode(playlistId, forKey: "playlistId")
        aCoder.encode(playlistName, forKey: "playlistName")
        aCoder.encode(dominantColor, forKey: "dominantColor")
        aCoder.encode(albumId, forKey: "albumId")
        aCoder.encode(albumTitle, forKey: "albumTitle")
        aCoder.encode(albumSeoToken, forKey: "albumSeoToken")
        aCoder.encode(self.type?.rawValue, forKey: "type")
        aCoder.encode(explicitness, forKey: "explicitness")
        aCoder.encode(token, forKey: "token")
        aCoder.encode(lastPlayed, forKey: "lastPlayed")
        aCoder.encode(allowSkip, forKey: "allowSkip")
        aCoder.encode(hasInteractive, forKey: "hasInteractive")
        aCoder.encode(albumArt, forKey: "albumArt")
        aCoder.encode(duration, forKey: "duration")
        aCoder.encode(trackToken, forKey: "trackToken")
        aCoder.encode(stationId, forKey: "stationId")
    }

    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as? String
        self.artistName = aDecoder.decodeObject(forKey: "artistName") as? String
        self.pandoraId = aDecoder.decodeObject(forKey: "pandoraId") as? String
        self.artistId = aDecoder.decodeObject(forKey: "artistId") as? String
        self.playlistId = aDecoder.decodeObject(forKey: "playlistId") as? String
        self.playlistName = aDecoder.decodeObject(forKey: "playlistName") as? String
        self.dominantColor = aDecoder.decodeObject(forKey: "dominantColor") as? String
        self.albumId = aDecoder.decodeObject(forKey: "albumId") as? String
        self.albumTitle = aDecoder.decodeObject(forKey: "albumTitle") as? String
        self.albumSeoToken = aDecoder.decodeObject(forKey: "albumSeoToken") as? String
        let typeInt = aDecoder.decodeObject(forKey: "type") as? Int ?? 0
        self.type = MusicType(rawValue: typeInt)
        self.explicitness = aDecoder.decodeObject(forKey: "explicitness") as? String
        self.token = aDecoder.decodeObject(forKey: "token") as? String
        self.lastPlayed = aDecoder.decodeObject(forKey: "lastPlayed") as? String
        self.allowSkip = aDecoder.decodeObject(forKey: "allowSkip") as? String
        self.hasInteractive = aDecoder.decodeBool(forKey: "hasInteractive")
        self.albumArt = aDecoder.decodeObject(forKey: "albumArt") as? String
        self.duration = aDecoder.decodeInteger(forKey: "duration")
        self.trackToken = aDecoder.decodeObject(forKey: "trackToken") as? String
        self.stationId = aDecoder.decodeObject(forKey: "stationId") as? String
    }
}
