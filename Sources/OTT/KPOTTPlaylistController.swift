//
//  KPOTTPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergey Chausov on 17.12.2021.
//

import Foundation
import PlayKit

@objc public class KPOTTPlaylistController: KPPlaylistController {
    
    internal var originalOTTMediaOptions: [OTTMediaOptions]?
    
    override internal func prepareMediaOptions(forMediaEntry entry: PKMediaEntry) -> MediaOptions? {
        let options: OTTMediaOptions
        
        if let ottOptions = self.originalOTTMediaOptions?.first(where: { $0.assetId == entry.id }) {
            options = ottOptions
        } else {
            PKLog.error("Media :\(entry.id) is missing in playlist OTT media options.")
            return nil
        }
        
        return options
    }
    
}
