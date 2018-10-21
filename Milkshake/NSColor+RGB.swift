//
//  NSColor+RGB.swift
//  Milkshake
//
//  Created by Dean Liu on 1/17/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//
//  Hex to RGB and RGB -> Complementary RGB
//

import Cocoa

extension NSColor {
    
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") { cString.removeFirst() }
        
        if cString.count != 6 {
            self.init(hex: "ff0000") // return red color for wrong hex input
            return
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
    
    func complementary() -> NSColor {
        // get the current values and make the difference from white:
        let compRed: CGFloat = 1.0 - self.redComponent
        let compGreen: CGFloat = 1.0 - self.greenComponent
        let compBlue: CGFloat = 1.0 - self.blueComponent
        return NSColor(calibratedRed: compRed, green: compGreen, blue: compBlue, alpha: self.alphaComponent)
    }
    
}
