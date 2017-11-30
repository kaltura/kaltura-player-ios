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
import PlayKitOVP

let ovpBaseUrl = "https://cdnapisec.kaltura.com/"
let ovpPartnerId: Int64 = 2215841
let ovpEntryId = "1_w9zx2eti"

class OVPViewController: UIViewController {
    
    var player: KalturaOvpPlayer?
    var playheadTimer: Timer?
    @IBOutlet weak var playerContainer: PlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OVPWidgetSession.get(baseUrl: ovpBaseUrl, partnerId: ovpPartnerId) { (ks, error) in
            if let error = error {
                PKLog.error(error.localizedDescription)
            } else {
                var playerOptions = KalturaPlayerOptions()
                playerOptions.serverUrl = ovpBaseUrl
                playerOptions.preload = true
                playerOptions.uiManager = DefaultKalturaUIMananger()
                
                let mediaOptions = OVPMediaOptions(entryId: ovpEntryId)
                
                // 1. Load the player
                do {
                    self.player = try KalturaOvpPlayer(partnerId: ovpPartnerId, ks: ks, pluginConfig: nil, options: playerOptions)
                    self.player?.loadMedia(mediaOptions: mediaOptions)
                    self.player?.view = self.playerContainer
                    
                } catch let e {
                    // error loading the player
                    print("error:", e.localizedDescription)
                }
            }
        }
    }
}


