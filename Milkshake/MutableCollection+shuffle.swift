//
//  MutableCollection+shuffle.swift
//  Milkshake
//
//  Created by Dean Liu on 1/28/18.
//  Copyright © 2018 Dean Liu. All rights reserved.
//
//  Shuffle an array.  Used for music shuffling
//

import Cocoa

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}
