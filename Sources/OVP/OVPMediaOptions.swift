//
//  OVPMediaOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 8/2/20.
//

import Foundation
import PlayKitProviders

@objc public class OVPMediaOptions: MediaOptions {
    
    @objc public var ks: String?
    @objc public var entryId: String?
    @objc public var uiconfId: NSNumber?

    internal func mediaProvider() -> OVPMediaProvider {
        let ovpMediaProvider = OVPMediaProvider()
        ovpMediaProvider.set(entryId: entryId)
        ovpMediaProvider.set(uiconfId: uiconfId)
        
        return ovpMediaProvider
    }
}
