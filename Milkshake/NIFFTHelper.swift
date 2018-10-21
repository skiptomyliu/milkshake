
//
//  NIFFTHelper.swift
//  Milkshake
//
//  Created by Dean Liu on 1/15/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//
//  https://github.com/666tos/SpectrumAnalyzerSample
//  Translated to swift from Obj-C
//  Heavy lifter for consuming the tapped audio (Music -> TapManager) and does a
//  fourier transform into 10 frequencies

import Cocoa
import Accelerate
import CoreAudio
import Foundation

class NIFFTHelper: NSObject {
    var _fftSetup: FFTSetup;
    var _windowBuffer: UnsafeMutablePointer<Float32>!
    var _complexA: [COMPLEX_SPLIT] = []
    
    var _outFFTData: UnsafeMutablePointer<Float32>!
    var _tmpFFTData0: [UnsafeMutablePointer<Float32>] = []
//    Float32 *_tmpFFTData0[2];
    var _numberOfSamples:UInt32

    let NIFFTHelperChannelsCount:Int = 2;
    let NIFFTHelperInputBufferSize:UInt32 = 16384;
    let NIFFTHelperMaxInputSize:UInt32  = 2<<9; //10 frequencies
    let NIFFTHelperMaxBlocksBeforSkipping: UInt32  = 4;
    
    var operationQueue: OperationQueue
    
    init(numberOfSamples:UInt32) {
        _numberOfSamples = numberOfSamples;
        
        let nOver2 = NIFFTHelperMaxInputSize/2;
        let log2n = Log2Ceil(NIFFTHelperMaxInputSize); //vDSP_Length
        
        _fftSetup = vDSP_create_fftsetup(vDSP_Length(log2n), FFTRadix(FFT_RADIX2))!;
        _windowBuffer = UnsafeMutablePointer<Float32>.allocate(capacity: Int(NIFFTHelperMaxInputSize))

        
        let total = MemoryLayout.size(ofValue: (MemoryLayout<Float32>.size * Int(NIFFTHelperMaxInputSize)))
        memset(_windowBuffer, 0, total);
        vDSP_hann_window(_windowBuffer, vDSP_Length(NIFFTHelperMaxInputSize), Int32(vDSP_HANN_NORM));
        
        for i in 0..<NIFFTHelperChannelsCount {
            _complexA.append(
                COMPLEX_SPLIT(
                    realp: UnsafeMutablePointer<Float32>.allocate(capacity: Int(NIFFTHelperMaxInputSize)),
                    imagp: UnsafeMutablePointer<Float32>.allocate(capacity: Int(NIFFTHelperMaxInputSize))
                )
            )
            _tmpFFTData0.append(
                UnsafeMutablePointer<Float32>.allocate(capacity: Int(NIFFTHelperMaxInputSize))
            )
            memset(_tmpFFTData0[i], 0, Int(nOver2) * MemoryLayout<Float32>.size);
        }
        _outFFTData = UnsafeMutablePointer<Float32>.allocate(capacity: Int(nOver2))
        memset(_outFFTData, 0, Int(nOver2) * MemoryLayout<Float32>.size);
        
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        super.init()
    }

    deinit {
        self.operationQueue.cancelAllOperations()
        vDSP_destroy_fftsetup(_fftSetup);
        for i in 0..<NIFFTHelperChannelsCount {
            free(_complexA[i].realp);
            free(_complexA[i].imagp);
            free(_tmpFFTData0[i]);
        }
        free(_outFFTData);
    }
    
    func cleanupChannelInputs(channelInputs: [UnsafeMutablePointer<Float32>], size:UInt32) {
        for channel in 0..<size {
            free(channelInputs[Int(channel)]);
        }
//        free(channelInputs);
    }
    
    func performComputation(bufferListInOut:UnsafeMutablePointer<AudioBufferList>, completion:@escaping([Float]) -> ()) {

       let audioBuffer0 =  bufferListInOut[0]
        var numSamples = min(Int(audioBuffer0.mBuffers.mDataByteSize)/MemoryLayout<Float32>.size, Int(_numberOfSamples))
        
        let bytesize = Int(audioBuffer0.mBuffers.mDataByteSize)
        
        numSamples = Int(NextPowerOfTwo(x: UInt32(numSamples)));

        if numSamples <= 0 || bytesize <= 0{
            return;
        }

        if self.operationQueue.operationCount > 1 {
            self.operationQueue.cancelAllOperations()
        }
        
        let maxChannels = min(NIFFTHelperChannelsCount, Int(audioBuffer0.mNumberBuffers))
        var channelInputs = [UnsafeMutablePointer<Float32>]()
    
        for _ in 0..<maxChannels {
            
            channelInputs.append(
                UnsafeMutablePointer<Float32>.allocate(capacity: MemoryLayout<Float32>.size * numSamples)
            )
        }

        for i in 0..<maxChannels-1 {
            
            let audioBuffer = bufferListInOut[i].mBuffers
            
            if (audioBuffer.mData == nil) {
                self.cleanupChannelInputs(channelInputs: channelInputs, size: UInt32(maxChannels))
                return;
            }
            memcpy(channelInputs[i], audioBuffer.mData, MemoryLayout<Float32>.size * numSamples);

        }
        
        
        self.operationQueue.addOperation({
            let dataBlocksCount = min(numSamples/Int(self.NIFFTHelperMaxInputSize), Int(self.NIFFTHelperMaxBlocksBeforSkipping));
            
            for i in 0..<dataBlocksCount {
                
                let log2FFTSize = Log2Ceil(self.NIFFTHelperMaxInputSize);
                let bins = self.NIFFTHelperMaxInputSize>>1
                
                var one = Float(1.0)
                var fBins = Float(bins)
                let dataOffset = UInt32(i) * self.NIFFTHelperMaxInputSize;
                
                var currentChannelInputs: [UnsafeMutablePointer<Float32>] = []
                
                for channel in 0..<maxChannels {
                    currentChannelInputs.append(channelInputs[channel].advanced(by: Int(dataOffset)))
                    
                    vDSP_vmul(currentChannelInputs[channel], 1, self._windowBuffer, 1, currentChannelInputs[channel], 1, vDSP_Length(self.NIFFTHelperMaxInputSize));
                    
                    //Convert float array of reals samples to COMPLEX_SPLIT array A
                    currentChannelInputs[channel].withMemoryRebound(to: DSPComplex.self, capacity: Int(bins)) {inAudioDataPtr in
                        vDSP_ctoz(inAudioDataPtr, 2, &(self._complexA[channel]), 1, vDSP_Length(bins))
                    }
                    
                    //Perform FFT using fftSetup and A
                    //Results are returned in A
                    vDSP_fft_zrip(self._fftSetup, &(self._complexA[channel]), 1, vDSP_Length(log2FFTSize), FFTDirection(FFT_FORWARD));
                    
                    // compute Z magnitude
                    vDSP_zvabs(&(self._complexA[channel]), 1, self._tmpFFTData0[channel], 1, vDSP_Length(bins));
                    vDSP_vsdiv(self._tmpFFTData0[channel], 1, &fBins, self._tmpFFTData0[channel], 1, vDSP_Length(bins));
                    
                    // convert to Db
                    vDSP_vdbcon(self._tmpFFTData0[channel], 1, &one, self._tmpFFTData0[channel], 1, vDSP_Length(bins), 1);
                    
                    // db correction considering window
                    //                vDSP_vsadd(_tmpFFTData0[channel], 1, &fGainOffset, _tmpFFTData0[channel], 1, bins);
                }
                
                memcpy(self._outFFTData, self._tmpFFTData0[0], MemoryLayout<Float32>.size * Int(bins));
                
                // stereo analysis ; for this demo, we only support up to 2 channels
                for channel in 0..<maxChannels {
                    vDSP_vadd(self._outFFTData, 1, self._tmpFFTData0[channel], 1, self._tmpFFTData0[0], 1, vDSP_Length(bins));
                }
                var div = Float(maxChannels)
                vDSP_vsdiv(self._outFFTData, 1, &div, self._outFFTData, 1, vDSP_Length(bins));
                
                var spectrumData: [Float] = []
                for spectrum in 0..<log2FFTSize {
                    let f = self._outFFTData[Int(spectrum)]
                    spectrumData.append(f)
                }
                
//              completion(spectrumData);
                completion(AddFreq(freqs: spectrumData))
            }
            
            self.cleanupChannelInputs(channelInputs: channelInputs, size: UInt32(maxChannels))
        })
        
       
    }
}


func CountLeadingZeroes(_ x: UInt32) -> UInt32 {
    var x = x
    var n : UInt32 = 32;
    var y : UInt32;
    
    y = x >> 16; if (y != 0) { n = n - 16; x = y; }
    y = x >> 8; if (y != 0) { n = n - 8; x = y; }
    y = x >> 4; if (y != 0) { n = n - 4; x = y; }
    y = x >> 2; if (y != 0) { n = n - 2; x = y; }
    y = x >> 1; if (y != 0) { return n - 2; }
    
    return n - x;
}

func AddFreq(freqs:[Float]) -> [Float]{
    var newFreqs = [Float]()
    var i = 0
    for value in freqs {
        var fuzz = Float(arc4random_uniform(3)) + Float(arc4random_uniform(100))/100.0
        fuzz = arc4random_uniform(2) > 0 ? fuzz * -1 : fuzz

        newFreqs.append(value)
        if (i % 3 == 0) {
            newFreqs.append(value + fuzz)
        }
        i += 1
    }
    return newFreqs
}

// base 2 log of next power of two greater or equal to x
func Log2Ceil(_ x: UInt32) -> UInt32 {
    return 32 - CountLeadingZeroes(x - 1);
}
// base 2 log of next power of two greater or equal to x
// next power of two greater or equal to x
func NextPowerOfTwo(x:UInt32) -> UInt32{
    return 1 << Log2Ceil(x);
}



