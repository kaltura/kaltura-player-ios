//
//  KalturaBasicPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 1/9/20.
//

import Foundation
import PlayKit

class KalturaBasicPlayer: KalturaPlayer {
    
    var basicPlayerOptions: BasicPlayerOptions
    
    init(basicPlayerOptions: BasicPlayerOptions) {
        self.basicPlayerOptions = basicPlayerOptions
        super.init(pluginConfig: basicPlayerOptions.pluginConfigs)
    }
    
    func prepare() {
        let source = PKMediaSource(basicPlayerOptions.id, contentUrl: basicPlayerOptions.contentUrl, drmData: basicPlayerOptions.drmData, mediaFormat: basicPlayerOptions.mediaFormat)
        // setup media entry
        let mediaEntry = PKMediaEntry(basicPlayerOptions.id, sources: [source], duration: -1)
        
        // create media config
        let mediaConfig = MediaConfig(mediaEntry: mediaEntry)
        
        super.prepare(mediaConfig: mediaConfig)
    }
}
