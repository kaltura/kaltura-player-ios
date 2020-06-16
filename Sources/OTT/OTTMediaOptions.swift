//
//  OTTMediaOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/6/20.
//

import Foundation
import PlayKitProviders

@objc public class OTTMediaOptions: MediaOptions {
    
    @objc public var ks: String?
    @objc public var assetId: String?
    @objc public var assetType: AssetType = .unset
    @objc public var assetReferenceType: AssetReferenceType = .unset
    @objc public var formats: [String]?
    @objc public var fileIds: [String]?
    @objc public var playbackContextType: PlaybackContextType = .unset
    @objc public var networkProtocol: String?
}
