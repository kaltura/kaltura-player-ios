//
//  OVPPlaylistOptions.swift
//  PlayKitProviders
//
//  Created by Sergii Chausov on 30.08.2021.
//

import Foundation
import PlayKitProviders

@objc public class OVPPlaylistOptions: NSObject {
    
    @objc public var ks: String?
    @objc public var playlistId: String?
    
    @objc public var redirectFromEntryId: Bool = true
    
    internal func playlistProvider() -> OVPPlaylistProvider {
        let ovpPlaylistProvider = OVPPlaylistProvider()
        ovpPlaylistProvider.set(playlistId: playlistId)
        return ovpPlaylistProvider
    }
}
