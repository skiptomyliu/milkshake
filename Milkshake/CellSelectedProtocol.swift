//
//  CellSelectedProtocol.swift
//  Milkshake
//
//  Created by Dean Liu on 11/28/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa

protocol CellSelectedProtocol: class {
    func cellSelectedProtocol(cell: SearchTableCellView)
    func cellHighlightedProtocol(item: MusicItem)
    func cellArtistSelectedProtocol(item: MusicItem)
    func cellAlbumSelectedProtocol(item: MusicItem)
    func cellPlaylistSelectedProtocol(item: MusicItem)
    func cellPlayPlaylistSelectedProtocol(item: MusicItem)
    func cellTopSongsSelectedProtocol()
    func cellCreateStationSelectedProtocol(pandoraId: String)
    func escKeyProtocol();
    func searchKeyProtocol(keyChar: String)
}

protocol MusicChangedProtocol: class {
    func musicPreflightChangedProtocol(item: MusicItem)
    func musicChangedProtocol(item: MusicItem)
    func musicPlayedProtocol()
    func musicPausedProtocol()
    func musicLoadingIndicatorProtocol(isStart:Bool)
}

protocol MusicTimeProtocol: class {
    func updateMusicTimeProtocol(duration:Float, totalTime:Float)
}

protocol MenuSelectedProtocol: class {
    func menuSelectedProtocol(index:Int)
}

protocol LoginProtocol: class {
    func handleSuccessLogin(results:Dictionary<String,AnyObject>)
}
