//
//  OTTMediaOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/6/20.
//

import Foundation
import PlayKitProviders

public class OTTMediaOptions: MediaOptions {
    
    public var ks: String?
    public var assetId: String?
    public var assetType: AssetType = .unset
    public var assetReferenceType: AssetReferenceType = .unset
    public var formats: [String]?
    public var fileIds: [String]?
    public var playbackContextType: PlaybackContextType = .unset
    public var networkProtocol: String?
}
