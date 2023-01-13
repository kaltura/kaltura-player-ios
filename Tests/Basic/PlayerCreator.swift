// ===================================================================================================
// Copyright (C) 2022 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import XCTest
import Foundation
import Quick
import SwiftyJSON
import KalturaPlayer

protocol PlayerCreator: class {}

// All xctest case classes should have player creator.
extension XCTestCase: PlayerCreator {}

extension PlayerCreator {
    
    func createPlayer(pluginConfigDict: [String : Any]? = nil, shouldStartPreparing: Bool = true) -> KalturaPlayer? {
        
        let playerOptions = PlayerOptions()
        playerOptions.autoPlay = false
        playerOptions.preload = true
        
        let kalturaBasicPlayer = KalturaBasicPlayer(options: playerOptions)
        
        let url = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        if let contentUrl = URL(string: url) {
            kalturaBasicPlayer.setupMediaEntry(id: "1", contentUrl: contentUrl)
        }
        
        return kalturaBasicPlayer
    }
    
    func destroyPlayer(_ player: KalturaPlayer!) {
        player.destroy()
    }
    
}
