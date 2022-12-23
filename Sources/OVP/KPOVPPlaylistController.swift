//
//  KPOVPPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergey Chausov on 17.12.2021.
//

import Foundation
import PlayKit
import KalturaPlayer

@objc public class KPOVPPlaylistController: KPPlaylistController {
    
    internal var originalOVPMediaOptions: [OVPMediaOptions]?
    
    override public func prepareMediaOptions(forMediaEntry entry: PKMediaEntry) -> MediaOptions? {
        
        let options: MediaOptions
        
        if let ovpOptions = self.originalOVPMediaOptions?.first(where: { $0.entryId == entry.id }) {
            options = ovpOptions
        } else {
            PKLog.error("Media :\(entry.id) is missing in playlist OVP media options.")
            return nil
        }
        
        return options
    }
    
}
