//
//  TapManager.swift
//  Milkshake
//
//  Created by Dean Liu on 2/4/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate
import AVKit

class TapManager: NSObject {
    
    static var fftHelper: NIFFTHelper?
    static var tapAddr: MTAudioProcessingTap?
    
    func tap() -> Unmanaged<MTAudioProcessingTap>? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: tapUnprepare,
            process: tapProcess)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        
        print("err: \(err)\n")
        if err == noErr { }
        
        TapManager.tapAddr = tap?.takeRetainedValue()
        
        return tap
    }
    
    let tapInit: MTAudioProcessingTapInitCallback = {
        (tap, clientInfo, tapStorageOut) in
        let nonOptionalSelf = clientInfo!.assumingMemoryBound(to: AppDelegate.self).pointee
        // print("init \(tap, clientInfo, tapStorageOut, nonOptionalSelf)\n")
    }
    
    let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
        (tap) in
        print("finalize \(tap)\n")
    }
    
    let tapPrepare: MTAudioProcessingTapPrepareCallback = {
        (tap, b, c) in
        print("prepare: \(tap, b, c)\n")
    }
    
    let tapUnprepare: MTAudioProcessingTapUnprepareCallback = {
        (tap) in
        print("unprepare \(tap)\n")
    }
    
    
    let tapProcess: MTAudioProcessingTapProcessCallback = {
        (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
        
        if (fftHelper == nil){
            fftHelper = NIFFTHelper(numberOfSamples: 16384)
        }
        
        fftHelper?.performComputation(bufferListInOut: bufferListInOut) { (result) in
            DispatchQueue.main.async {
                var userInfo: [String: Any] = [:]
                userInfo["NIAudioManagerSpectrumDataKey"] = result
                if tap == tapAddr {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NIAudioManagerDidChangeSpectrumData"), object: nil, userInfo:userInfo)
                }
            };
            
        }
        
    }    
}
