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
import PlayKit_IMA
import PlayKitYoubora

let ovpBaseUrl = "http://cdnapisec.kaltura.com"
let ovpPartnerId = 2215841
let ovpEntryId = "1_w9zx2eti"
let uiconfId = 41188731

class OVPViewController: UIViewController {
    
    var player: KalturaOvpPlayer?
    var playheadTimer: Timer?
    @IBOutlet weak var playerContainer: PlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PlayKitManager.shared.registerPlugin(IMAPlugin.self)
        PlayKitManager.shared.registerPlugin(YouboraPlugin.self)
        
        PlayerConfigManager.shared.retrieve(by: uiconfId, baseUrl: ovpBaseUrl, partnerId: ovpPartnerId, ks: nil) { (uiConf, error) in
            var playerOptions = KalturaPlayerOptions(partnerId: ovpPartnerId)
            playerOptions.serverUrl = ovpBaseUrl
            playerOptions.preload = true
            playerOptions.uiManager = DefaultKalturaUIMananger()
            playerOptions.uiConf = uiConf

            var config = [String : Any]()
            config[YouboraPlugin.pluginName] = AnalyticsConfig(params: ["p1" : 1])
            
            let imaConfig = IMAConfig()
            imaConfig.webOpenerPresentingController = self
            imaConfig.companionView = UIView()
            config[IMAPlugin.pluginName] = imaConfig

            playerOptions.pluginConfig = PluginConfig(config: config)
            
            self.player = KalturaOvpPlayer.create(with: playerOptions)
            
            let mediaOptions = OVPMediaOptions(entryId: ovpEntryId)
            self.player?.loadMedia(mediaOptions: mediaOptions)
            self.player?.view = self.playerContainer
        }
    }
}


