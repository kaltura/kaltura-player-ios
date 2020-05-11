//
//  KalturaOTTPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 4/5/20.
//

import Foundation
import PlayKit
import PlayKitProviders

public class KalturaOTTPlayer: KalturaPlayer {

    private var ottPlayerOptions: OTTPlayerOptions
    var ottMediaOptions: OTTMediaOptions? {
        didSet {
            mediaOptions = ottMediaOptions
        }
    }
    
    private var sessionProvider: SimpleSessionProvider
    
    /**
       A Kaltura Player for OTT Clients.
    
       Create the player options, `OTTPlayerOptions`, and pass it to the `KalturaOTTPlayer`.
       Check the `OTTPlayerOptions` for more info regarding the available options and defaults.
       Create a `KalturaPlayerView` in the code or in the xib and pass it to the `KalturaOTTPlayer`.
       
       **Example:**
    
           let ottPlayerOptions = OTTPlayerOptions()
           let kalturaOTTPlayer = KalturaOTTPlayer(options: ottPlayerOptions)
           kalturaOTTPlayer.view = kalturaPlayerView
    
       * Parameters:
           * options: The player's initialize options.
    */
    public init(options: OTTPlayerOptions) {
        ottPlayerOptions = options
        
        sessionProvider = SimpleSessionProvider(serverURL: KalturaOTTPlayerManager.shared.serverURL, partnerId: KalturaOTTPlayerManager.shared.partnerId, ks: ottPlayerOptions.ks)
        
        super.init(playerOptions: ottPlayerOptions)
    }
    
    // MARK: - Public Methods
    
    public func loadMedia(options: OTTMediaOptions, callback: @escaping (Error?) -> Void) {
        ottMediaOptions = options
        
        if options.ks?.isEmpty == false {
            sessionProvider.ks = options.ks
        } else {
            sessionProvider.ks = ottPlayerOptions.ks
        }
        
        let phoenixMediaProvider = PhoenixMediaProvider()
        phoenixMediaProvider.set(assetId: options.assetId)
        phoenixMediaProvider.set(type: options.assetType)
        phoenixMediaProvider.set(refType: options.assetReferenceType)
        phoenixMediaProvider.set(playbackContextType: options.playbackContextType)
        phoenixMediaProvider.set(formats: options.formats)
        phoenixMediaProvider.set(fileIds: options.fileIds)
        phoenixMediaProvider.set(networkProtocol: options.networkProtocol)
        phoenixMediaProvider.set(referrer: ottPlayerOptions.referrer)
        phoenixMediaProvider.set(sessionProvider: sessionProvider)
        
        phoenixMediaProvider.loadMedia { (pkMediaEntry, error) in
            guard let mediaEntry = pkMediaEntry else {
                callback(error)
                return
            }
            
            self.mediaEntry = mediaEntry
            callback(nil)
        }
    }
    
    /**
        Update the player's initialized options.
     
        * Parameters:
            * playerOptions: A new player options.
     */
    public func updatePlayerOptions(_ playerOptions: OTTPlayerOptions) {
        self.ottPlayerOptions = playerOptions
        super.updatePlayerOptions(playerOptions)
    }
}
