//
//  PlayerViewController.swift
//  Milkshake
//
//  Created by Dean Liu on 12/11/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//
//  Used to be a different VC, now being re-purposed
//  Currently dedicated to slider scrubbing.

import Cocoa

class PlayerViewController: NSViewController, MusicTimeProtocol {
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var bgView: NSView!
    @IBOutlet weak var userSlider: MySlider!
    @IBOutlet weak var bgSlider: NSSlider!
    
    @IBOutlet weak var playerTimeTextField: NSTextField!
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    var isUserDraggingSlider = false // Flag, only update slider if user isn't dragging
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.disable()
        self.view.wantsLayer = true
        self.view.needsLayout = true
        self.view.needsDisplay = true

        self.bgView.wantsLayer = true
        self.bgView.needsLayout = true
        self.bgView.needsDisplay = true
    }
    
    func disable() {
        self.userSlider.alphaValue = 0.0
        self.userSlider.isEnabled = false
    }
    
    func enable() {
        self.userSlider.isEnabled = true
    }
    
    func setViewWithMusicItem(item: MusicItem) {
        self.enable()
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func updateMusicTimeProtocol(duration: Float, totalTime: Float) {
        self.updateSliderTime(duration: duration, totalTime: totalTime)
        let timeLeft = totalTime - duration

        if (timeLeft <= 10 && appDelegate.music?.crossFade == true && appDelegate.music?.timeObserverToken != nil) {
            appDelegate.music?.removeTimeObserver()
            appDelegate.music?.playNext()
        }
    }
    
    func updateSliderTime(duration: Float, totalTime: Float) {
        if isUserDraggingSlider == false {
            let percent = Double(duration/totalTime)
            self.bgSlider.doubleValue = percent
            self.userSlider.doubleValue = percent
        }
    }
  
    @IBAction func sliderDragged(_ sender: Any) {
        let slider = sender as! NSSlider
        let event = NSApplication.shared.currentEvent
        let startingDrag = event?.type == NSEvent.EventType.leftMouseDown
        let endingDrag = event?.type == NSEvent.EventType.leftMouseUp
        let dragging = event?.type == NSEvent.EventType.leftMouseDragged;
        
        if startingDrag {
            self.isUserDraggingSlider = true
        }
        
        if endingDrag {
            self.isUserDraggingSlider = false
            self.appDelegate.music?.scrub(toPercent: slider.doubleValue)
            self.appDelegate.music?.addTimeObserver()
        }
        
        if dragging {
            self.isUserDraggingSlider = true
            self.bgSlider.doubleValue = slider.doubleValue
        }
    }
}
