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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var options = KalturaPlayerOptions()
        options.preload = true
        options.uiManager = DefaultKalturaUIMananger()
        options.autoPlay = true
        
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
}

