//
//  RoundView.swift
//  Milkshake
//
//  Created by Dean Liu on 11/27/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Background for the application.
//  Round the window and gaussian blur album images as the background

import Cocoa

class RoundView: NSView {
    
    var backgroundImage: NSImage?
    var savedLayer: CALayer?

    required override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        self.addGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addGradient()
    }
    
    override func awakeFromNib() {
        self.addGradient()
        super.awakeFromNib()
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    func addGradient() {
        if (self.layer?.sublayers![0] is CAGradientLayer) == false {
            self.wantsLayer = true
            let colorTop =  NSColor(red: 220/255.0, green: 36/255.0, blue: 65/255.0, alpha: 1.0).cgColor
            let colorBottom = NSColor(red:50/255.0, green: 40/255.0, blue: 188/255.0, alpha: 1.0).cgColor
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [colorBottom, colorTop]
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.frame = self.bounds
            self.layer?.addSublayer(gradientLayer)
        }
    }
    
    func getResizeMultiplier(image:NSImage) -> CGFloat {
        if image.size.height > self.frame.height {
            return self.frame.height / image.size.height
        }
        return image.size.height / self.frame.height
    }
    
    func gaussianBlurOfRadius(image:NSImage, radius: CGFloat) -> NSImage {
        image.lockFocus()
        let beginImage = CIImage(data: image.tiffRepresentation!)
        let gaussFilter = CIFilter(name: "CIGaussianBlur")!
        gaussFilter.setValue(beginImage, forKey: kCIInputImageKey)
        gaussFilter.setValue(radius, forKey: kCIInputRadiusKey)
        let gaussImg = gaussFilter.value(forKey: kCIOutputImageKey) as! CIImage
        
        let exposeFilter = CIFilter(name: "CIExposureAdjust")!
        exposeFilter.setValue(gaussImg, forKey: kCIInputImageKey)
        exposeFilter.setValue(-2.0, forKey: kCIInputEVKey)
        let output = exposeFilter.value(forKey: kCIOutputImageKey) as! CIImage
        
        let rect = NSMakeRect(0, 0, image.size.width, image.size.height)
        
        output.draw(in: rect, from: rect, operation: NSCompositingOperation.sourceOver, fraction: 1)
        image.unlockFocus()
        return image
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if var img = self.backgroundImage {

            if (self.layer?.sublayers![0] is CAGradientLayer) {
                self.layer?.sublayers![0].removeFromSuperlayer()
            }
            
            img = self.gaussianBlurOfRadius(image: img, radius: 10)
            let multiply = self.getResizeMultiplier(image: img)
            let width = img.size.width * multiply
            let height = img.size.height * multiply
            let x = (width - self.frame.size.width) / 2.0
            img.draw(in: CGRect(x: -x, y: 0, width: width, height: height), from: NSZeroRect, operation:NSCompositingOperation.sourceOver, fraction: 1.0)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(nil)
    }
}

