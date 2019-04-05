//
//  Util.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

class Util: NSObject {
    
    // Converts string (TR, ST, AR, etc.) to MusicType
    class func strToMusicType(_ type: String?) -> MusicType {
        var musicType = MusicType.UNDEFINED
        if let type = type {
            switch type.uppercased() {
            case "TR":
                musicType = MusicType.TRACK
                break
            case "ST":
                musicType = MusicType.STATION
                break
            case "AR":
                musicType = MusicType.ARTIST
                break
            case "PL":
                musicType = MusicType.PLAYLIST
                break
            case "AL":
                musicType = MusicType.ALBUM
                break
            case "CO":
                musicType = MusicType.COMPOSER
                break
            case "SF":
                musicType = MusicType.SF
                break
            default:
                musicType = MusicType.UNDEFINED
            }
        }
        return musicType
    }
    
    
    // Parse API search results
    class func parseSearchIntoItems(results: [String: AnyObject]) -> [MusicItem] {
        var items: [MusicItem] = []
//        print(results)
        if let resultsOrder = results["results"] as? [String] {
            for key in resultsOrder {
                var row = results["annotations"]![key]! as! [String: AnyObject]
                let iconDict = row["icon"] as? [String: String]
                let icon = iconDict?["thorId"] ?? ""
                
                let musicItem = MusicItem()
                if icon != "" {
                    musicItem.albumArt = "https://content-images.p-cdn.com/"+(icon)
                }
                
                musicItem.name = row["name"] as? String
                musicItem.albumTitle = row["name"] as? String
                musicItem.token = row["token"] as? String
                musicItem.pandoraId = row["pandoraId"] as? String
                musicItem.type = strToMusicType(row["type"] as? String)
                musicItem.releaseDate = row["releaseDate"] as? String
                musicItem.artistName = row["artistName"] as? String
                musicItem.duration = row["duration"] as? Int ?? -1
                musicItem.artistId = row["artistId"] as? String
                musicItem.albumId = row["albumId"] as? String
                musicItem.shareableUrlPath = row["shareableUrlPath"] as? String
                musicItem.cellType = CellType.SEARCH
                
//                print(row)
                
                if let rightsDict = row["rightsInfo"] as? [String: AnyObject] {
                    musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
                }
                
                if musicItem.type == MusicType.ARTIST || musicItem.type == MusicType.COMPOSER {
                    musicItem.artistId = musicItem.pandoraId
                }
                items.append(musicItem)
            }
        }
        return items
    }
    
    //
    class func parseAlbumIntoTracksv2(results: [String: AnyObject]) -> [MusicItem] {
        var tracks:[MusicItem] = []
        
        let album = results["results0"] as! [String: AnyObject]
        let trackMap = results["results1"] as! [String: AnyObject]
    
        
        if let albumTracks = album["tracks"] as? [[String: AnyObject]] {
            for albumTrack in albumTracks {
                var albumArt = ""
                if let albumArtArray = albumTrack["albumArt"] as? [AnyObject] {
                    if albumArtArray.count > 1 {
                        albumArt = albumArtArray[2]["url"] as? String ?? ""
                    }
                }
                let musicItem = MusicItem()
                musicItem.pandoraId = albumTrack["pandoraId"] as? String
                
                let annotate = trackMap[musicItem.pandoraId!] as? [String: AnyObject]
                if annotate != nil {
                    let annotate = annotate!
                    if let icon = annotate["icon"] {
                        musicItem.dominantColor = icon["dominantColor"] as? String
                    }
                    
                    musicItem.name = albumTrack["songTitle"] as? String
                    musicItem.albumId = album["pandoraId"] as? String
                    musicItem.artistName = albumTrack["artistName"] as? String ?? ""
                    musicItem.artistId = annotate["artistId"] as? String ?? ""
                    musicItem.albumTitle = albumTrack["albumTitle"] as? String
                    musicItem.albumId = annotate["albumId"] as? String
                    musicItem.explicitness = annotate["explicitness"] as? String
                    if let rightsDict = annotate["rightsInfo"] {
                        musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
                    }
                    musicItem.type = MusicType.TRACK
                    musicItem.isAlbum = true
                    musicItem.albumArt = albumArt
                    musicItem.duration = albumTrack["trackLength"] as! Int
                    
                    tracks.append(musicItem)
                }
            }
        }
        return tracks;
    }
    
    class func parseAlbumIntoTracks(album: [String: AnyObject]) -> [MusicItem] {
        var tracks:[MusicItem] = []
        
        if let albumTracks = album["tracks"] as? [[String: AnyObject]] {
            for albumTrack in albumTracks {
                var albumArt = ""
                if let albumArtArray = albumTrack["albumArt"] as? [AnyObject] {
                    if albumArtArray.count > 1 {
                        albumArt = albumArtArray[2]["url"] as? String ?? ""
                    }
                }
                
                let musicItem = MusicItem()
                musicItem.name = albumTrack["songTitle"] as? String
                musicItem.albumId = album["pandoraId"] as? String
                musicItem.pandoraId = albumTrack["pandoraId"] as? String
                musicItem.artistName = albumTrack["artistName"] as? String ?? ""
                
                musicItem.artistId = album["artistId"] as? String ?? ""
                musicItem.albumTitle = albumTrack["albumTitle"] as? String
                
                if let rightsDict = albumTrack["rightsInfo"] {
                    musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
                }
                musicItem.type = MusicType.TRACK
                musicItem.albumArt = albumArt
                musicItem.duration = albumTrack["trackLength"] as! Int
                
                tracks.append(musicItem)
            }
        }
        return tracks;
    }
    

    class func artistKey(catalog: [String:AnyObject]) -> String {
        let artistKey = catalog["artistDetails"] != nil ? "artistDetails" : "composerDetails"
        return artistKey
    }
    
    class func artistDetails(catalog: [String: AnyObject]) -> MusicItem {
        let artistKey = self.artistKey(catalog: catalog)
        let musicItem = MusicItem()
        let heroImage = catalog[artistKey]!["heroImage"]! as! [String: String]
        musicItem.isArtist = true
        if let artId = heroImage["artId"] {
            musicItem.heroImageRaw = artId
        } else {
            musicItem.heroImage = ""
        }
        musicItem.listenerCount = catalog[artistKey]!["stationListenerCount"] as? Int ?? 0
        return musicItem
    }
        
    class func artistLatestRelease(catalog: [String: AnyObject]) -> [MusicItem] {
        let artistKey = self.artistKey(catalog: catalog)
        var items: [MusicItem] = []
        let annotations = catalog["annotations"] as! [String: AnyObject]
        if let latestRelease:String = catalog[artistKey]?["latestRelease"] as? String {
            let track = annotations[latestRelease] as! [String: AnyObject]
            let artId = track["icon"]!["artId"] as? String ?? ""
            var albumArt: String?
            if artId != "" {
                albumArt = self.iconArtIdURL(path: artId)
            }
            
            let musicItem = MusicItem()
            musicItem.name = track["name"] as? String
            musicItem.pandoraId = track["pandoraId"] as? String
            musicItem.artistId = track["artistId"] as? String
            musicItem.artistName = track["artistName"] as? String
            musicItem.explicitness = track["explicitness"] as? String
            musicItem.shareableUrlPath = track["shareableUrlPath"] as? String
            musicItem.type = MusicType.ALBUM
            musicItem.releaseDate = track["releaseDate"] as? String
            musicItem.latestRelease = true
            musicItem.albumArt = albumArt
            musicItem.cellType = CellType.ARTIST
            
            if let dominantColor = track["icon"]!["dominantColor"] as? String {
                musicItem.dominantColor = dominantColor
            }
            if let rightsDict = track["rightsInfo"] {
                musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
            }
            items.append(musicItem)
            
        }
        return items
    }
    
    class func artistAlbumsRelease(catalog: [String: AnyObject]) -> [MusicItem] {
        let artistKey = self.artistKey(catalog: catalog)
        var items: [MusicItem] = []
        let topAlbums = catalog[artistKey]!["topAlbums"]! as! [String]
        let annotations: Dictionary<String, AnyObject> = catalog["annotations"] as! [String: AnyObject]
        for pandoraId in topAlbums {
            let track = annotations[pandoraId] as! [String: AnyObject]
            let musicItem = MusicItem()
            if let icon = track["icon"] {
                musicItem.dominantColor = icon["dominantColor"] as? String
                let artId = icon["artId"] as? String ?? ""
                if artId != "" {
                    musicItem.albumArt = self.iconArtIdURL(path: artId)
                }
            }
            
            musicItem.name = track["name"] as? String
            musicItem.pandoraId = track["pandoraId"] as? String
            musicItem.artistName = track["artistName"] as? String
            musicItem.explicitness = track["explicitness"] as? String
            musicItem.albumTitle = track["albumTitle"] as? String
            musicItem.artistId = track["artistId"] as? String
            musicItem.shareableUrlPath = track["shareableUrlPath"] as? String
            musicItem.type = MusicType.ALBUM
            musicItem.cellType = CellType.ARTIST
            musicItem.releaseDate = track["releaseDate"] as? String
            if let rightsDict = track["rightsInfo"] {
                musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
            }
            items.append(musicItem)
        }
        return items
    }
    class func artistTopTracks(catalog: [String: AnyObject]) -> [MusicItem] {
        let artistKey = self.artistKey(catalog: catalog)
        var items: [MusicItem] = []
        let annotations = catalog["annotations"] as! [String: AnyObject]
        
        let MAX_TRACKS = 20
        var i = 0
        
        let topTracks = catalog[artistKey]!["topTracks"]! as! [String]
        for pandoraId in topTracks {
            let track = annotations[pandoraId] as! Dictionary<String, AnyObject>
            let artId = track["icon"]!["artId"] as? String ?? ""
            var albumArt: String?
            if artId != "" {
                albumArt = self.iconArtIdURL(path: artId)
            }
            
            let musicItem = MusicItem()
            musicItem.name = track["name"] as? String
            musicItem.pandoraId = track["pandoraId"] as? String
            musicItem.artistName = track["artistName"] as? String
            musicItem.albumTitle = ""
            musicItem.albumId = track["albumId"] as? String
            musicItem.artistId = track["artistId"] as? String
            
            musicItem.duration = track["duration"] as! Int
            musicItem.explicitness = track["explicitness"] as? String
            musicItem.shareableUrlPath = track["shareableUrlPath"] as? String
            musicItem.isArtist = true
            musicItem.cellType = CellType.ARTIST
            
            if let rightsDict = track["rightsInfo"] {
                musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
            }
            
            musicItem.type = MusicType.TRACK
            musicItem.albumArt = albumArt
            if let dominantColor = track["icon"]!["dominantColor"] as? String {
                musicItem.dominantColor = dominantColor
            }
            
            items.append(musicItem)
            i = i + 1
            if(i > MAX_TRACKS) {
                break;
            }
        }
        return items
    }
    
    class func artistSimilarArtists(catalog: [String: AnyObject]) -> [MusicItem] {
        let artistKey = self.artistKey(catalog: catalog)
        var items: [MusicItem] = []
        let annotations: [String: AnyObject] = catalog["annotations"] as! [String: AnyObject]
        let similarArtists = catalog[artistKey]!["similarArtists"]! as! [String]
        
        for pandoraId in similarArtists {
            let musicItem = MusicItem()
            let artist = annotations[pandoraId] as! [String: AnyObject]
            if let icon = artist["icon"]!["artUrl"] as? String {
                let albumArt = "https://content-images.p-cdn.com/"+(icon)
                musicItem.albumArt = albumArt
            }
            musicItem.name = artist["name"] as? String
            musicItem.pandoraId = artist["pandoraId"] as? String
            musicItem.artistName = artist["name"] as? String
            musicItem.artistId = artist["pandoraId"] as? String
            musicItem.shareableUrlPath = artist["shareableUrlPath"] as? String
            musicItem.type = MusicType.ARTIST
            items.append(musicItem)
        }
        
        return items
    }
    
    class func isRadioInteractive(rights: [String]) -> Bool {
        return rights.contains("allowReplay")
    }
    
    // When a station is played, parse the four tracks
    class func parseStationIntoItems(station: [String: AnyObject]) -> [MusicItem] {
        var items: [MusicItem] = []
        if let tracks = station["tracks"] as? [[String: Any]] {
            for track in tracks {
                // Refig this out:
                let albumArtArray = track["albumArt"] as! [AnyObject]
                var albumArt = ""
                
                if(albumArtArray.count > 0) {
                    // XXX: May error out, may not always be enough
                    albumArt = albumArtArray[2]["url"] as? String ?? ""
                }
                
                let musicItem = MusicItem()
                musicItem.pandoraId = track["pandoraId"] as? String
                musicItem.artistName = track["artistName"] as? String
                
                // Format of artist id when fetching from station: R23136
                let artistMusicId = String((track["artistMusicId"] as! String).dropFirst(1))
                musicItem.artistId = String(format:"AR:%@", artistMusicId)
                
                musicItem.albumTitle = track["albumTitle"] as? String
                musicItem.albumSeoToken = track["albumSeoToken"] as? String
    //            musicItem.duration = track["duration"] as? Int ?? -1
                musicItem.duration = track["trackLength"] as? Int ?? -1
                musicItem.allowSkip = track["allowSkip"] as? String
                musicItem.userSeed = track["userSeed"] as? String
                musicItem.trackToken = track["trackToken"] as? String
                musicItem.stationId = track["stationId"] as? String
                musicItem.audioURL = track["audioURL"] as? String
                musicItem.musicId = track["musicId"] as? String
                musicItem.name = track["songTitle"] as? String
                musicItem.rating = track["rating"] as? Int ?? 0
                
                // Station tracks don't show hasInteractive, so we deduce it ourselves
                if let rightsArray = track["rights"] as? Array<String> {
                    musicItem.hasInteractive = self.isRadioInteractive(rights: rightsArray)
                    musicItem.rights = rightsArray
                }
                musicItem.type = MusicType.TRACK
                musicItem.shareableUrlPath = track["shareableUrlPath"] as? String
                musicItem.albumArt = albumArt
                
                items.append(musicItem)
            }
        }
        return items
    }

    // Lists radio stations
    class func parseStationSearchIntoItems(stationResult: [String: AnyObject]) -> [MusicItem] {
        var items: [MusicItem] = []
        
        // Limit 50 stations only for time being
        let stations = (stationResult["stations"] as! [[String: Any]]).prefix(50)
        
        for station in stations {
            var albumArt = ""
            if let albumArtArray = station["art"] as? [AnyObject] {
                if(albumArtArray.count > 1) {
                    // XXX: May error out, may not always be enough
                    albumArt = albumArtArray[2]["url"] as? String ?? ""
                }
            }
            let musicItem = MusicItem()
            musicItem.pandoraId = station["pandoraId"] as? String
            musicItem.stationId = station["stationId"] as? String
            musicItem.name = station["name"] as? String
            musicItem.lastPlayed = station["lastPlayed"] as? String
            musicItem.albumArt = albumArt
            musicItem.dateCreated = station["dateCreated"] as? String ?? ""
            musicItem.isShuffle = station["isShuffle"] as? String
            musicItem.isThumbprint = station["isThumbprint"] as? String
            musicItem.artId = station["artId"] as? String
            musicItem.genre = station["genre"] as? String
            musicItem.creatorWebname = station["creatorWebname"] as? String
            musicItem.totalPlayTime = station["totalPlayTime"] as? String
            
            // musicItem.listenerCount = station["listenerCount"] as? Int ?? 0 // nonexistant
            
            musicItem.type = MusicType.STATION
            musicItem.albumArt = albumArt
            items.append(musicItem)
        }
        
        return items
    }
    
    // From create station artist page
    class func parseCreateStation(result:[String: AnyObject]) -> MusicItem {
        let musicItem = MusicItem()
        musicItem.stationId = result["stationId"] as? String
        musicItem.pandoraId = result["pandoraId"] as? String
        musicItem.name = result["name"] as? String
        return musicItem
    }
    
    class func parsePlaylistSearchIntoItems(playlistSearchResult:[String: AnyObject]) -> [MusicItem] {
        
        var items: [MusicItem] = []
        let annotationsDict = playlistSearchResult["annotations"] as! [String: AnyObject]
        
        let playlistsArray = playlistSearchResult["items"] as! [[String: Any]]
        
        for playlist in playlistsArray{
            let musicItem = MusicItem()
            
            let pandoraId = playlist["pandoraId"] as! String
            musicItem.pandoraId = pandoraId
            musicItem.playlistId = pandoraId
//            musicItem.type = playlist["pandoraType"] as? String
            
            if let rightsDict = playlist["rights"] as? Array<String> {
                musicItem.rights = rightsDict
            }
            
            if let annotated = annotationsDict[pandoraId] as? [String: AnyObject] {
                musicItem.name = annotated["name"] as? String
                musicItem.duration = annotated["duration"] as? Int ?? -1
                musicItem.shareableUrlPath = annotated["shareableUrlPath"] as? String
                musicItem.totalTracks = annotated["totalTracks"] as! Int
                musicItem.type = MusicType.PLAYLIST
                musicItem.thorLayersRaw = annotated["thorLayers"] as? String ?? ""
            }
            
            items.append(musicItem)
        }
        
        return items
    }
    
    
    class func parseAlbumNameFromShareURL(_ shareURL:String) -> String? {
        let urlComponents = shareURL.components(separatedBy: "/")
        
        if urlComponents.count == 6 {
            let albumName = (urlComponents[3]).replacingOccurrences(of: "-", with: " ")
            if albumName.range(of:"single") == nil { // not a single
                return albumName.capitalized
            }
        }
        
        return nil
    }
    
    class func parsePlaylistIntoItems(playlistResult:[String: AnyObject]) -> [MusicItem] {
        var items: [MusicItem] = []
        
        let annotationsDict: [String: AnyObject] = playlistResult["annotations"] as! [String: AnyObject]
        let tracksArray = playlistResult["tracks"] as! [[String: Any]]
        let playlistId = playlistResult["pandoraId"] as! String
        let playlistName = playlistResult["name"] as! String

        for trackMap in tracksArray{
            let musicItem = MusicItem()
            musicItem.thorLayersRaw = playlistResult["thorLayers"] as? String ?? ""
            
            musicItem.playlistId = playlistId // record to figure out which playlist is playing on sweep
            musicItem.playlistName = playlistName // record to display in now playing
            
            let pandoraId = trackMap["trackPandoraId"] as! String
            
            let track = annotationsDict[pandoraId] as! [String: AnyObject]
            
            if let artId = track["icon"]!["artId"] as? String {
                let albumArt = self.iconArtIdURL(path: artId)
                musicItem.albumArt = albumArt
            }
            
            if let dominantColor = track["icon"]!["dominantColor"] as? String {
                musicItem.dominantColor = dominantColor
            }
            
            if let shareUrl = track["shareableUrlPath"] as? String {
                musicItem.albumTitle = self.parseAlbumNameFromShareURL(shareUrl)
            } else {
                musicItem.albumTitle = ""
            }
            
            musicItem.name = track["name"] as? String
            musicItem.pandoraId = track["pandoraId"] as? String
            musicItem.artistName = track["artistName"] as? String
            musicItem.artistId = track["artistId"] as? String
            musicItem.albumId = track["albumId"] as? String
            musicItem.duration = track["duration"] as! Int
            musicItem.explicitness = track["explicitness"] as? String
            musicItem.shareableUrlPath = track["shareableUrlPath"] as? String
            if let rightsDict = track["rightsInfo"] {
                musicItem.hasInteractive = rightsDict["hasInteractive"] as? Bool ?? false
            }
            musicItem.type = MusicType.TRACK
            
            items.append(musicItem)
        }
        
        return items
    }

    // Called by menuvc artists
    class func parseArtistIntoItems(artistResults:[String: AnyObject]) -> [MusicItem] {
        var items: [MusicItem] = []

        let totalCount = artistResults["totalCount"] as! Int
        if totalCount > 0 {
            let annotationsDict = artistResults["annotations"] as! [String: AnyObject]
            let artistArray = artistResults["items"] as! [[String: AnyObject]]
            for artist in artistArray {
                let musicItem = MusicItem()
//                musicItem.type = artist["pandoraType"] as? String
                musicItem.type = MusicType.ARTIST
                let pandoraId = artist["pandoraId"] as! String
                let row = annotationsDict[pandoraId] as! [String: AnyObject]
                musicItem.name = row["name"] as? String
                musicItem.pandoraId = row["pandoraId"] as? String
                // musicItem.albumCount = row["albumCount"] as? Int
                musicItem.artistId = row["pandoraId"] as? String
                musicItem.shareableUrlPath = row["shareableUrlPath"] as? String
                musicItem.cellType = CellType.ARTIST
                
                if let icon = row["icon"]!["thorId"] as? String {
                    let albumArt = "https://content-images.p-cdn.com/"+(icon)
                    musicItem.albumArt = albumArt
                }
                items.append(musicItem)
            }
        }
        return items
    }
    
    class func iconArtIdURL(path: String) -> String{
        return String(format:"https://content-images.p-cdn.com/%@_500W_500H.jpg",path)
    }
    
    
    class func convertSecsToMinSec(_ totalSeconds: NSInteger) -> String {
        let minutes = totalSeconds / 60;
        let seconds = totalSeconds % 60;
        return String(format: "%ld:%02ld", minutes, seconds)
    }
    
    
    class func convertDateToLastListened(_ fromDate: Date) -> String {
        let totalSeconds  = Calendar.current.dateComponents([.second], from: fromDate, to: Date()).second!
        if (totalSeconds / 60 <= 0 ) {
            return String(format: "%lu seconds ago", totalSeconds)
        }
        else if (totalSeconds / (3600) <= 0) {
            let minutes = totalSeconds / (60)
            return String(format: "%lu minutes ago", minutes)
        }
        else if (totalSeconds / (3600 * 24) <= 0) {
            let hours = totalSeconds / (3600)
            return String(format: "%lu hours ago", hours)
        }
        else if (totalSeconds / (3600 * 24 * 7) <= 0) {
            let hours = totalSeconds / (3600 * 24)
            return String(format: "%lu days ago", hours)
        }
        else if (totalSeconds / (3600 * 24 * 7 * 4) <= 0) {
            let hours = totalSeconds / (3600 * 24 * 7)
            return String(format: "%lu weeks ago", hours)
        }
        else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            return dateFormatter.string(from: fromDate)
        }
    }
    
    class func charLengthInSize(_ text:String, size: CGSize, fontAttributes:[NSAttributedStringKey : Any]) -> Int {
        let attributeString = NSAttributedString(string: text, attributes: fontAttributes)
        let frameSetterRef = CTFramesetterCreateWithAttributedString(attributeString as CFAttributedString)

        var characterFitRange = CFRange()
        CTFramesetterSuggestFrameSizeWithConstraints(frameSetterRef, CFRangeMake(0, 0), nil, size, &characterFitRange)
        return characterFitRange.length
    }
}

