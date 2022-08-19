//
//  Callback.swift
//  Milkshake
//
//  Created by Dean Liu on 1/12/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//
//  Callback from API requests to create array of MusicItems
//  Resultant array of MusicItems is then used to create ResultsViewController
//

import Cocoa

class Callback: NSObject {
    
    static func callbackArtist(results: [String: AnyObject]) -> [MusicItem] {
        
        var items: [MusicItem] = []
        let artistLatestRelease = Util.artistLatestRelease(catalog: results)
        let artistTopTracks = Util.artistTopTracks(catalog: results)
        let artistAlbumsRelease = Util.artistAlbumsRelease(catalog: results)
        let artistSimilarArtists = Util.artistSimilarArtists(catalog: results)
        
        let artistDetailsItem = Util.artistDetails(catalog: results)
        artistDetailsItem.isHeader = true
        
        // Set the artist name based on top track.  If blank, set based on album
        artistDetailsItem.name = artistTopTracks.count > 0 ? artistTopTracks[0].artistName : nil
        if (artistAlbumsRelease.count > 0 && artistDetailsItem.name == nil) {
            artistDetailsItem.name = artistAlbumsRelease[0].artistName
        }
        
        let artistKey = Util.artistKey(catalog: results)
        artistDetailsItem.pandoraId = results[artistKey]!["pandoraId"] as? String
        artistDetailsItem.artistId = artistDetailsItem.pandoraId
        items.append(artistDetailsItem)
        
        let latestHeader = MusicItem()
        latestHeader.name = "LATEST RELEASE"
        latestHeader.isHeader = true
        items.append(latestHeader)
        items = items + artistLatestRelease
        
        let topHeader = MusicItem()
        topHeader.name = "TOP SONGS"
        topHeader.isHeader = true
        items.append(topHeader)
        items = items + artistTopTracks
        
        let albumHeader = MusicItem()
        albumHeader.name = "ALBUMS"
        albumHeader.isHeader = true
        items.append(albumHeader)
        items = items + artistAlbumsRelease
        
        let artistsHeader = MusicItem()
        artistsHeader.name = "SIMILAR ARTISTS"
        artistsHeader.isHeader = true
        items.append(artistsHeader)
        items = items + artistSimilarArtists
        return items
    }
    
    static func callbackStationsList(results: [String: AnyObject]) -> [MusicItem] {
        var stationResults = Util.parseStationSearchIntoItems(stationResult: results)
        let stationsHeader = MusicItem()
        stationsHeader.name = "STATIONS"
        stationsHeader.isHeader = true
//        stationResults.insert(stationsHeader, at: 0)
        
        let stationShuffleRow = MusicItem()
        stationShuffleRow.name = "Shuffle Stations"
        stationShuffleRow.isHeaderAction = true
        stationShuffleRow.hasInteractive = true
        stationShuffleRow.type = MusicType.STATION
        stationShuffleRow.isShuffle = true
        stationResults.insert(stationShuffleRow, at: 0)
        return stationResults
    }
        
    static func callbackPlaylistList(results: [String: AnyObject]) -> [MusicItem] {
        var playlistResults = Util.parsePlaylistSearchIntoItems(playlistSearchResult: results)
        let playlistHeader = MusicItem()
        playlistHeader.name = "PLAYLISTS"
        playlistHeader.isHeader = true
        playlistResults.insert(playlistHeader, at: 0)
        return playlistResults
    }
}
