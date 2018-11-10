//
//  History.swift
//  Milkshake
//
//  Created by Dean Liu on 11/9/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//

import Cocoa

//enum RatingType: Int {
//    case THUMBDOWN
//    case THUMBUP
//    case NONE
//}

class History: NSObject {
    
    private var thumbsMap:[String: Int] = [:]
    private var MAX_ITEMS = 30
    
    func getThumbForId(pandoraId: String) -> Int {
        if let result = thumbsMap[pandoraId] {
            return result
        }
        return 0
    }
    
    override init() {
        super.init()
    }
    
    class func getListenerHistoryKey() -> String{
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let listener_history = String(format:"%@_history", appDelegate.listenerId)
        return listener_history
    }
    
    class func getListenerRatingKey() -> String{
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let listener_history = String(format:"%@_ratings", appDelegate.listenerId)
        return listener_history
    }
    
    class func getArchiveThumbsMap() -> [String: Int]{
        let historyRatingData = UserDefaults.standard.object(forKey: History.getListenerRatingKey()) as? Data
        var thumbsMap:[String: Int] = [:]
        if let historyRatingData = historyRatingData {
            thumbsMap = NSKeyedUnarchiver.unarchiveObject(with: historyRatingData) as? [String: Int] ?? [:]
        }
        return thumbsMap
    }

    class func getArchiveMusic() -> [MusicItem] {
        let historyData = UserDefaults.standard.object(forKey: History.getListenerHistoryKey()) as? Data
        var historyArray = [] as [MusicItem]
        if let historyData = historyData {
            historyArray = NSKeyedUnarchiver.unarchiveObject(with: historyData) as? [MusicItem] ?? []
        }
        return historyArray
    }
    
    func storeThumbForId(pandoraId: String, rating: Int) {
        self.thumbsMap = History.getArchiveThumbsMap()
        self.thumbsMap[pandoraId] = rating
        self.saveArchiveThumbs()
    }
    
    func saveArchiveThumbs() {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: self.thumbsMap)
        UserDefaults.standard.set(encodedData, forKey: History.getListenerRatingKey())
    }
    
    // Remove any IDs from thumb map / rating that doesn't exist in our history array
    func cleanUp(thumbsMap: [String:Int], historyArray:[MusicItem]) -> [String:Int]{
        var thumbsMap = thumbsMap
        let pandoraIds = thumbsMap.keys
        var historyIds: [String] = []
        for item in historyArray {
            if let pandoraId = item.pandoraId {
                historyIds.append(pandoraId)
            }
        }
        for pid in pandoraIds {
            if !historyIds.contains(pid) {
                thumbsMap[pid] = nil
            }
        }
        return thumbsMap
    }
    
    func fetchMusicFromHistory() -> [MusicItem] {
        let historyArray = History.getArchiveMusic()
        if self.thumbsMap.count <= 0 {
            self.thumbsMap = History.getArchiveThumbsMap()
            self.thumbsMap = self.cleanUp(thumbsMap: self.thumbsMap, historyArray: historyArray)
            self.saveArchiveThumbs()
        }
        for item in historyArray {
            let pandoraId = item.pandoraId ?? ""
            item.rating = thumbsMap[pandoraId] ?? item.rating
        }
        return historyArray
    }

    func saveToHistory(item: MusicItem) -> [MusicItem] {
        self.storeThumbForId(pandoraId: item.pandoraId!, rating: item.rating)
        var historyArray = History.getArchiveMusic()
        if historyArray.count > MAX_ITEMS {
            let removed = historyArray.removeLast()
            self.thumbsMap[removed.pandoraId!] = nil
        }
        print("Total thumb map")
        print(self.thumbsMap)
        print(self.thumbsMap.count)
        item.cellType = CellType.HISTORY
        historyArray.insert(item, at: 0)
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: historyArray)
        UserDefaults.standard.set(encodedData, forKey: History.getListenerHistoryKey())
        return historyArray
    }
}
