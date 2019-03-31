//
//  API.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Handles all the network API request.
//

import Foundation
import Alamofire
import Locksmith

class API: NSObject {
    var X_AuthToken: String?
    var X_CsrfToken: String = "0123456789abcdef"
    var RETRY = 1
    var curRetry = 0
    var base_cookie = "_ga=GA1.2.34567890.1234567890;csrftoken=0123456789abcdef;_gid=GA1.2.1234567890.1234567890; _uetsid=_uetff68c25a;"
    var cookies = ""
    
    // Base network request function called by all API methods
    // footnote (fn1) If the X_Auth token is expired, repeat the request once.
    // footnote (fn2) If a request fails, repeat the request once
    //   this seems to help mostly against fetching Playlists
    func request(_ url:String, params:[String: Any], callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        var headers: [String: String]  = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:56.0) Gecko/20100101 Firefox/56.0",
            "X-CsrfToken": self.X_CsrfToken,
            "Cookie": self.cookies
        ]
        
        if let X_AuthToken = self.X_AuthToken {
            headers["X-AuthToken"] = X_AuthToken
        }

        Alamofire.request(
            url,
            method: .post,
            parameters: params,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseJSON { response in
            if let responseValue = response.result.value {
                if let responseCookie = HTTPCookieStorage.shared.cookies {
                    self.parseCookie(cookies: responseCookie)
                }
                if let headerFields = response.response?.allHeaderFields as? [String: String],
                    let URL = response.request?.url
                {
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
                    print(cookies)
                }
                let rv = responseValue as! [String: AnyObject]

                if (rv["errorCode"] as? Int) == 1001 {
                    print("Token needs to be refreshed!!")
                    print(self.X_AuthToken)
                    self.X_AuthToken = ""

                    if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "Milkshake") {
                        let username = dictionary["username"] as! String
                        let password = dictionary["password"] as! String
                        self.auth(username: username, pass: password) { responseDict in
                            self.X_AuthToken = responseDict["authToken"] as? String;
                            // Clear the station queues because they're all expired
                            print(self.X_AuthToken)
                            if url.hasSuffix("annotateObjectsSimple") {
                                print("Clearing out... trying again")
                                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                                appDelegate.radio.stationTracks.removeAll()
                                appDelegate.radio.playNext()
                            } else {
                                // (fn1) After setting new token, we repeat the request
                                self.request(url, params: params, callbackHandler: callbackHandler)
                            }
                        }
                    } else {
                        // xxx: todo:
                        print("No stored passwords... re-load back to login screen")
                    }
                    
                }
                // (fn2) Only repeat if not stream violation
                else if(rv["errorCode"] != nil && (rv["errorString"] as? String) != "STREAM_VIOLATION") {
                    print("retrying... error code", rv["errorCode"]!)
                    self.curRetry += 1
                    if self.curRetry <= self.RETRY {
                        self.request(url, params: params, callbackHandler: callbackHandler)
                    } else {
                        callbackHandler(rv)
                    }
                }
                else {
                    self.curRetry = 0
                    callbackHandler((response.result.value as? [String: AnyObject])!)
                }
            }
        }
    }
    
    func parseCookie(cookies: [HTTPCookie]) {
        var cookieStr = ""
        for cookie in cookies {
            cookieStr = cookieStr + cookie.name + "=" + cookie.value + ";"
        }
        self.cookies = self.base_cookie + cookieStr
        print(self.cookies)
    }
        
    
    func auth(username:String, pass:String, callbackHandler:@escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let parameters: [String: Any] = [
            "existingAuthToken": "",
            "username": username,
            "password": pass,
            "keepLoggedIn": NSNumber(value: true)
        ]
        let url: String = "https://www.pandora.com/api/v1/auth/login"
        self.request(url, params: parameters, callbackHandler: callbackHandler)
    }
    
    func auth(username:String, token:String, callbackHandler:@escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let params: [String: Any] = [
            "existingAuthToken": token,
            "username": username,
            "password": "",
            "keepLoggedIn": true
        ]
        let url: String = "https://www.pandora.com/api/v1/auth/login"
        self.request(url, params: params, callbackHandler: callbackHandler)
    }
    
    func playbackResumed(forceActive:Bool, callbackHandler:@escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let params: [String: Any] = [
            "forceActive": true
        ]
        let url: String = "https://www.pandora.com/api/v1/station/playbackResumed"
        self.request(url, params: params, callbackHandler: callbackHandler)
    }
    
    func search(txt:String, callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        var types =  ["AL", "AR", "CO", "PL", "SF", "TR"]
        if appDelegate.isPremium == false {
            types =  ["AR", "CO", "SF", "TR"]
        }
        let params: [String: Any] = [
            "query": txt,
            "types": types,
            "listener":"",
            "start":0,
            "count":20,
            "annotate":NSNumber(value:true),
            "filters":[],
            "searchTime":Int(Date().timeIntervalSince1970 * 1000)
        ]
        self.request("https://www.pandora.com/api/v3/sod/search", params: params, callbackHandler: callbackHandler)
    }
    
//    func getAudioPlaybackInfoPandoraId(pid:String, sid:String, callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
//
//        let params: [String: Any] = [
//            "pandoraId": pid,
//            "sourcePandoraId": sid,
//        ]
//        self.request("https://www.pandora.com/api/v1/ondemand/getAudioPlaybackInfo", params: params, callbackHandler: callbackHandler)
//    }
    
    func getAudioPlaybackInfoPandoraId(item:MusicItem, callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let params: [String: Any] = [
            "pandoraId": item.pandoraId!,
            "sourcePandoraId": item.albumId!,
            ]
        self.request("https://www.pandora.com/api/v1/ondemand/getAudioPlaybackInfo", params: params) { (response) in
            let returnDict: [String: Any] = [
                "musicItem": item,
                "response": response
            ]
            callbackHandler(returnDict as [String : AnyObject])
        }
    }
    
    //  Fetching album is a 2-part sequential request:
    //  1.  Fetch base album info that contains track links
    //  2.  Annotate each track to obtain extra info not avail in step 1: (album id, dominant color, etc.)
    // step 1.
    func albumToken(token:String, callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let params: [String: Any] = [
            "token": token
        ]
        self.request("https://www.pandora.com/api/v1/music/album", params: params) { (response) in
            self.callbackAlbum(results:response, callbackHandler: callbackHandler )
        }
    }
    
    // step 1 callback.  Parse the album into tracks and then call annotate network request
    func callbackAlbum(results: [String: AnyObject], callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let items = Util.parseAlbumIntoTracks(album: results)
        var trackIds = [String]()
        for  item in items {
            trackIds.append(item.pandoraId!)
        }
        self.annotateObjectsSimple(trackIds: trackIds, results:results,  callbackHandler: callbackHandler)
    }
    
    // step 2:  Annotate objects.  Results of step 1 are put into 'results0' and step 2 results in 'results1'
    //  xxx: refactor to eliminate results0 and results1 and just use results1?
    //        The annotated results are only being used at the moment
    func annotateObjectsSimple(trackIds:[String], results:[String: AnyObject], callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "pandoraIds": trackIds
        ]

        self.request("https://www.pandora.com/api/v4/catalog/annotateObjectsSimple", params: params){ (response) in
            let returnDict: [String: Any] = [
                "results0": results,
                "results1": response
            ]
            
            callbackHandler(returnDict as [String : AnyObject])
        }
    }

    func annotateObjectsSimple(trackIds:[String], callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "pandoraIds": trackIds
        ]
        
        self.request("https://www.pandora.com/api/v4/catalog/annotateObjectsSimple", params: params, callbackHandler: callbackHandler)
    }
    
    // Deprecated?  we should just be calling catalogDetails now for fetching artist details.  Remove below comment block in future:
    //1
    /*
    func artistToken(token:String, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "token": token
        ]
        self.request("https://www.pandora.com/api/v1/music/artist", params: params) { (response) in
            self.callbackArtistToken(results:response, callbackHandler: callbackHandler )
        }
    }
    //2
    func callbackArtistToken(results:[String: Any], callbackHandler: @escaping(_ Dictionary:[String:AnyObject]) -> ()) {
        let pandoraId = results["pandoraId"] as! String
        self.catalogDetails(pandoraId: pandoraId, callbackHandler: callbackHandler)
    }
    */
    
    // Get artist details
    func catalogDetails(pandoraId:String, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "pandoraId": pandoraId
        ]
        self.request("https://www.pandora.com/api/v4/catalog/getDetails", params: params){ (response) in
            callbackHandler(response)
        }
    }
 
    //4  part of deprecation, just call catalogDetails now
    /*
    func callbackCatalogDetails(catalogResults:[String: AnyObject], artistResults:[String: Any], callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        callbackHandler(catalogResults);
    }
     */
    
    // Token is needed to perform API requests to fetch details of an artist or album
    //  The token is nested in the ShareableUrlPath, this function extracts it
    //xxx refactor to use willSet and didSet
    class func getTokenFromItem(_ item: MusicItem) -> String {
        if let shareableUrlPath:String = item.shareableUrlPath {
            let pathArray = shareableUrlPath.components(separatedBy: "/")
            let tokenArray = pathArray[2...pathArray.count-1]
            let token = tokenArray.joined(separator: "/")
            return token
        }
        return ""
    }
    
    func getSortedArtists(callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "request": [
                "offset": 0,
                "limit": 50,
                "annotationLimit": 100
            ]
        ]
        self.request("https://www.pandora.com/api/v5/collections/getSortedArtists", params: params, callbackHandler: callbackHandler)
    }
    
    
    /*
     
     Radio Requests
     
     */
    
    func getStations(callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "pageSize": 250,
        ]
        self.request("https://www.pandora.com/api/v1/station/getStations", params: params, callbackHandler: callbackHandler)
    }
    // Get music tracks of station
    func getPlaylistFragment(stationId:String, isStationStart:Bool, lastPlayedTrackToken:String?, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        var params: [String: Any] = [
            "stationId": stationId,
            "isStationStart": isStationStart,
            "fragmentRequestReason":"Normal", // set to "Skip" when skipping
            "audioFormat":"mp3-hifi",
            "startingAtTrackId":"", //null
            "onDemandArtistMessageArtistUidHex":"", //null
            "onDemandArtistMessageIdHex":"" //null
        ]
        if lastPlayedTrackToken != nil {
            params["lastPlayedTrackToken"] = lastPlayedTrackToken
        }
        self.request("https://www.pandora.com/api/v1/playlist/getFragment", params: params, callbackHandler: callbackHandler)
    }
    
    func addFeedback(trackToken:String, isPositive:Bool, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "trackToken": trackToken,
            "isPositive": isPositive,
        ]
        self.request("https://www.pandora.com/api/v1/station/addFeedback", params: params, callbackHandler: callbackHandler)
    }
    
    func deleteFeedback(trackToken:String, isPositive:Bool, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "trackToken": trackToken,
            "isPositive": isPositive,
            ]
        self.request("https://www.pandora.com/api/v1/station/deleteFeedback", params: params, callbackHandler: callbackHandler)
    }
    
    func trackStarted(trackToken: String, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "trackToken": trackToken
        ]
        self.request("https://www.pandora.com/api/v1/station/trackStarted", params: params, callbackHandler: callbackHandler)
    }
    
    func createStation(pandoraId:String, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "pandoraId": pandoraId,
            "creativeId": "",
            "lineId": "",
            "creationSource": ""
        ]
        self.request("https://www.pandora.com/api/v1/station/createStation", params: params, callbackHandler: callbackHandler);
    }
    
    /*
     
    Playlists
     
    */
    
    func getSortedPlaylists(callbackHandler: @escaping(_ Dictionary: [String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "request": [
                "sortOrder": "MOST_RECENT_MODIFIED",
                // "offset": 20,  // implement later for paging
                "limit": 100,
                "annotationLimit": 100
                ]
            ]
        self.request("https://www.pandora.com/api/v5/collections/getSortedPlaylists", params: params, callbackHandler: callbackHandler)
    }
    
    func getTracks(pandoraId:String, callbackHandler: @escaping(_ Dictionary:[String: AnyObject]) -> ()) {
        let params: [String: Any] = [
            "request": [
                "pandoraId": pandoraId,
                "playlistVersion": 0,
                "offset": 0,
                "limit":100,
                "annotationLimit": 100
            ]
        ]
        self.request("https://www.pandora.com/api/v6/playlists/getTracks", params: params, callbackHandler: callbackHandler)
    }
    
}

