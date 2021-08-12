//
//  KalturaBasicPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 1/9/20.
//

import Foundation
import PlayKit
import KalturaNetKit

@objc public class KalturaBasicPlayer: KalturaPlayer {
    
    /**
        Set up the Kaltura Player.

        The setup will register any Kaltura's plugin which will be added in the pod file.
        Supporting `PlayKit_IMA` and `PlayKitYoubora` pods.
     */
    @objc public static func setup() {
        // This needs to be done in order for it to be initialized.
        let _ = KalturaBasicPlayerManager.shared
    }
    
    /**
        A Kaltura Player for external media.
     
        Create the player options, `BasicPlayerOptions`, and pass it to the `KalturaBasicPlayer`.
        Check the `BasicPlayerOptions` for more info regarding the available options and defaults.
        Create a `KalturaPlayerView` in the code or in the xib and pass it to the `KalturaBasicPlayer`.
        
        **Example:**
     
            let basicPlayerOptions = BasicPlayerOptions()
            let kalturaBasicPlayer = KalturaBasicPlayer(options: basicPlayerOptions)
            kalturaBasicPlayer.view = kalturaPlayerView
     
        * Parameters:
            * basicPlayerOptions: The player's initialize options.
     */
    @objc public init(options: PlayerOptions) {
        super.init(playerOptions: options)
    }
    
    // MARK: - Public Methods
    
    /**
        Set up the player's MediaEntry.
     
        * Parameters:
            * id: An identifier for the media entry.
            * contentUrl: The content url.
            * drmData: The DRM data if exists.
            * mediaFormat: The media's format.
            * mediaType: The media type.
            * mediaOptions: Additional media options. See `MediaOptions`.
     */
    @objc public func setupMediaEntry(id: String, contentUrl: URL, drmData: [DRMParams]? = nil, mediaFormat: PKMediaSource.MediaFormat = .unknown, mediaType: MediaType = .unknown, mediaOptions: MediaOptions? = nil) {
        let source = PKMediaSource(id, contentUrl: contentUrl, drmData: drmData, mediaFormat: mediaFormat)
        // setup media entry
        let mediaEntry = PKMediaEntry(id, sources: [source], duration: -1)
        mediaEntry.mediaType = mediaType
        
        self.mediaOptions = mediaOptions
        self.mediaEntry = mediaEntry
    }
}
