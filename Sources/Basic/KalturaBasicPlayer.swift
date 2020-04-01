//
//  KalturaBasicPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 1/9/20.
//

import Foundation
import PlayKit

public class KalturaBasicPlayer: KalturaPlayer, IKalturaPlayer {

    var basicPlayerOptions: BasicPlayerOptions
    
    public init(basicPlayerOptions: BasicPlayerOptions) {
        self.basicPlayerOptions = basicPlayerOptions
        super.init(pluginConfig: self.basicPlayerOptions.pluginConfigs)
    }
    
    public func prepare() {
        let source = PKMediaSource(basicPlayerOptions.id, contentUrl: basicPlayerOptions.contentUrl, drmData: basicPlayerOptions.drmData, mediaFormat: basicPlayerOptions.mediaFormat)
        // setup media entry
        let mediaEntry = PKMediaEntry(basicPlayerOptions.id, sources: [source], duration: -1)

        // create media config
        let mediaConfig = MediaConfig(mediaEntry: mediaEntry)

        super.prepareMediaConfig(mediaConfig)
    }
}
