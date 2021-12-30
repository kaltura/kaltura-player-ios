//
//  KPOVPPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergey Chausov on 17.12.2021.
//

import Foundation
import PlayKit

@objc public class KPOVPPlaylistController: KPPlaylistController {
    
    override internal func prepareMediaOptions(forMediaEntry entry: PKMediaEntry) -> MediaOptions? {
        let ovpOptions = OVPMediaOptions()
        ovpOptions.ks = self.player?.playerOptions.ks
        ovpOptions.entryId = entry.id
        
        return ovpOptions
    }
    
}
