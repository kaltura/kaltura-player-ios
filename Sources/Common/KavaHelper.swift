//
//  KavaHelper.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/31/20.
//

import Foundation
import PlayKit
import PlayKitKava

public class KavaHelper {
    
    static public func getPluginConfig(ovpPartnerId: Int64,
                                ovpEntryId: String,
                                ks: String?,
                                referrer: String,
                                playbackContext: String?,
                                analyticsUrl: String?,
                                playlistId: String?) -> KavaPluginConfig {
            
        let clientAppVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "BundleVersionMissing"
        let kavaPluginConfig = KavaPluginConfig(partnerId: Int(ovpPartnerId),
                                                entryId: ovpEntryId,
                                                ks: ks,
                                                userId: nil, // TODO: userId is missing to be sent to kava
                                                playbackContext: playbackContext,
                                                referrer: referrer,
                                                applicationVersion: clientAppVersion,
                                                playlistId: playlistId,
                                                customVar1: nil, // TODO: customVar's are missing to be sent to kava
                                                customVar2: nil,
                                                customVar3: nil)
        
        if var analyticsUrl = analyticsUrl {
            // TODO: Add a function to the Utils
            if analyticsUrl.hasSuffix("/api_v3/index.php") {
                // Do nothing, the url is correct
            } else if analyticsUrl.hasSuffix("/api_v3/") {
                analyticsUrl += "index.php"
            } else if analyticsUrl.hasSuffix("/api_v3") {
                analyticsUrl += "/index.php"
            } else if analyticsUrl.hasSuffix("/") {
                analyticsUrl += "api_v3/index.php"
            } else {
                analyticsUrl += "/api_v3/index.php"
            }
            
            kavaPluginConfig.baseUrl = analyticsUrl
        }
        
        return kavaPluginConfig
    }
}
