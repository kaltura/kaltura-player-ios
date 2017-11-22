//
//  ViewController.swift
//  KalturaPlayerExample
//
//  Created by Vadik on 21/11/2017.
//  Copyright © 2017 kaltura. All rights reserved.
//

import UIKit
import KalturaPlayer
import PlayKit

class ViewController: UIViewController {

    var player: KalturaPlayer?
    var playheadTimer: Timer?
    @IBOutlet weak var playerContainer: PlayerView!
    @IBOutlet weak var playheadSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var options = KalturaPlayerOptions()
        options.preload = true
        //options.autoPlay = true
        
        // 1. Load the player
        do {
            self.player = try KalturaOvpPlayer(partnerId: 2215841, ks: nil, pluginConfig: nil, options: options)
            self.player?.loadMedia(entryId: "1_w9zx2eti")/* { [weak self] (entry, error) in
                self?.player?.prepare()
            }*/
            self.player?.view = self.playerContainer
            
        } catch let e {
            // error loading the player
            print("error:", e.localizedDescription)
        }
    }
    
    /************************/
    // MARK: - Actions
    /***********************/
    
    @IBAction func playTouched(_ sender: Any) {
        guard let player = self.player else {
            print("player is not set")
            return
        }
        
        if !(player.isPlaying) {
            self.playheadTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                self.playheadSlider.value = Float(player.currentTime / player.duration)
            })
            
            player.play()
        }
    }
    
    @IBAction func pauseTouched(_ sender: Any) {
        guard let player = self.player else {
            print("player is not set")
            return
        }
        
        self.playheadTimer?.invalidate()
        self.playheadTimer = nil
        player.pause()
    }
    
    @IBAction func playheadValueChanged(_ sender: Any) {
        guard let player = self.player else {
            print("player is not set")
            return
        }
        
        let slider = sender as! UISlider
        
        print("playhead value:", slider.value)
        player.currentTime = player.duration * Double(slider.value)
    }


}

