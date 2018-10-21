//
//  SpectrumAnalyzerView.swift
//  Milkshake
//
//  Created by Dean Liu on 1/15/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//
//  https://github.com/666tos/SpectrumAnalyzerSample
//  Translated from Obj-C to swift
//
//  Displays spectrum on the NowPlayingView.swift
//  KVO receiver

import Cocoa

class SpectrumAnalyzerView: NSView {

    let kDefaultMinDbLevel = Float(-40.0);
    let kDefaultMinDbFS = Float(-110.0);
    let kDBLogFactor = Float(4.0);
    let kMaxQueuedDataBlocks = 2;
    let kFrameInterval = 2; //FPS = 60/kFrameInterval, for example kFrameInterval = 2 corresponds to 60/2 = 30FPS
    
    var spectrumData: [[Float]] = []
    var showsBlocks = true
    
    let columnMargin:CGFloat = 2.0 //5.0 //6.0;
    let columnWidth:CGFloat = 20.0// 20.0//24.0;
    
    var barBackgroundColor: NSColor?
    var barFillCompColor: NSColor = NSColor(calibratedRed: 0.0117647058823529, green: 0.282352941176471, blue: 0.835294117647059, alpha: 0.55)
    var barFillColor: NSColor = NSColor(calibratedRed: 250/255.0, green: 148/255.0, blue: 55/255.0, alpha: 0.55){
        willSet {
            self.barFillCompColor = newValue.complementary()
        }
        didSet {
            for layer in self.shapes {
                layer?.removeFromSuperlayer()
            }
            self.shapes = [CAGradientLayer?](repeating:nil, count: 20)
        }
    }

    
    var shapes = [CAGradientLayer?](repeating:nil, count: 20)
    var isObserving: Bool = false
    var currentSpectrumData:[Float] = [Float]()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        if self.isObserving == false {
            self.isObserving = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.audioManagerDidChangeSpectrumData),
                name: NSNotification.Name(rawValue: "NIAudioManagerDidChangeSpectrumData"),
                object: nil)
        }
    }
    
    @objc func audioManagerDidChangeSpectrumData(notification:NSNotification) {
        let lockQueue = DispatchQueue(label: "com.milkshake.LockQueue")
        lockQueue.sync() {
            if (self.spectrumData.count > kMaxQueuedDataBlocks) {
                self.spectrumData.remove(at: 0)
            }
            
            if let spectrumData = notification.userInfo!["NIAudioManagerSpectrumDataKey"] as? [Float] {
                if spectrumData[0] > -200  {
                    self.spectrumData.append(spectrumData)
                    self.needsDisplay = true
                } else {
//                    print("inf: ", spectrumData)
                }
            }
            
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let lockQueue = DispatchQueue(label: "com.milkshake.LockQueue")
        lockQueue.sync() {
            if self.spectrumData.count > 0 {
                currentSpectrumData = self.spectrumData[0]
            }
            
            if self.spectrumData.count > 1 {
                self.spectrumData.remove(at: 0)
            }
        }
        
        let count = currentSpectrumData.count;
        let maxWidth = self.bounds.size.width;
        let maxHeight = self.bounds.size.height;
        
        let offset = self.columnMargin;
        var width = self.columnWidth;
        
        if width <= 0.0 {
            if count > 0 {
                width = (maxWidth - CGFloat(count - 1) * offset) / CGFloat(count);
                width = CGFloat(floorf(Float(width)));
            }
        }
        
        let restSpace = maxWidth - (CGFloat(count) * width + CGFloat(count - 1) * offset);
        var x = restSpace/2.0;
        
        if self.showsBlocks {
            let blockWidth = CGFloat(10.0)
            let blocksCount = Int(maxHeight/blockWidth);
            if blocksCount > 0 {
                let lineWidth:CGFloat = 2.0;
                var y = self.bounds.size.height + lineWidth;
//                var y = 0 + lineWidth;
                
                let clipBezierPath = NSBezierPath() // NSBezierPath [BezierPath bezierPath];
                
                for _ in 0..<blocksCount {
                    clipBezierPath.append(NSBezierPath(rect: CGRect(x: 0, y: y, width: maxWidth, height: blockWidth)))
                    y -= blockWidth + lineWidth ;
                }
                clipBezierPath.close()
                clipBezierPath.addClip()
                
                /* for adding splits on the gradient */
                let mask = CAShapeLayer()
                mask.path = clipBezierPath.cgPath;
                self.layer?.mask = mask
            }
        }
        
        let barBackgroundPath = NSBezierPath()
        let barFillPath = NSBezierPath()
        
        for i in 0..<count {
            var frame = CGRect(x: x, y: 0, width: width, height: maxHeight)

            barBackgroundPath.append(NSBezierPath(rect: frame))
            
            let value = currentSpectrumData[i];

            let floatValue = value;
            
            if (!floatValue.isNaN){
                var height:CGFloat = 0.0;
                
                if floatValue <= kDefaultMinDbLevel {
                    height = 1.0 ///UI_SCREEN_SCALE;
                }
                else if floatValue >= 0 {
                    height = maxHeight - 1.0 ///UI_SCREEN_SCALE;
                }
                else {
                    let normalizedValue = (kDefaultMinDbLevel - floatValue)/kDefaultMinDbLevel;
                    //                normalizedValue = pow(normalizedValue, 1.0/kDBLogFactor);

                    height = CGFloat(floor(normalizedValue * Float(maxHeight) + 0.5))
                }
                
                frame.origin.y = 0 // maxHeight - height; // Use this to start from top
                frame.size.height = height;
                barFillPath.append(NSBezierPath(rect: frame))
            }
            
            x += width + offset;
            
            
            if shapes[i] != nil {
                if let gradient = shapes[i] {
                    gradient.frame = barFillPath.bounds
                    let shapeMask = CAShapeLayer()
                    shapeMask.path = barFillPath.cgPath
                    gradient.mask = shapeMask
                }
            } else {
                let gradient = CAGradientLayer()
                gradient.frame = barFillPath.bounds
                gradient.colors = [barFillCompColor.cgColor, barFillColor.cgColor]
                let shapeMask = CAShapeLayer()
                shapeMask.path = barFillPath.cgPath
                
                gradient.mask = shapeMask
                shapes[i] = gradient
                self.layer?.addSublayer(gradient)
            }
            
        }

//        let clear:NSColor = NSColor.clear
//        clear.set()
//        self.barBackgroundColor?.setFill()
//        barBackgroundPath.fill()
        
//        self.barFillColor.setFill();
//        barFillPath.fill()

    }
    
}
