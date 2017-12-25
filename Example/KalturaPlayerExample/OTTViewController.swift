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
import PlayKitOTT

let ottServerUrl = "http://api-preprod.ott.kaltura.com/v4_5/api_v3"
let ottPartnerId = 198
let ottAssetId = "259153"
let ottFileId = "804398"

class OTTViewController: UIViewController {

    var player: KalturaPhoenixPlayer?
    var playheadTimer: Timer?
    @IBOutlet weak var playerContainer: PlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PlayerConfigManager.shared.retrieve(by: uiconfId, baseUrl: ovpBaseUrl, partnerId: ovpPartnerId) { (uiConf, error) in
            var playerOptions = KalturaPlayerOptions(partnerId: ottPartnerId)
            playerOptions.serverUrl = ottServerUrl
            playerOptions.autoPlay = true
            playerOptions.uiManager = DefaultKalturaUIMananger()
            playerOptions.uiConf = uiConf
            
            self.player = KalturaPhoenixPlayer.create(with: playerOptions)
            
            let mediaOptions = PhoenixMediaOptions(assetId: ottAssetId, fileIds: [ottFileId])
            self.player?.loadMedia(mediaOptions: mediaOptions)
            self.player?.view = self.playerContainer
        }
    }
}

