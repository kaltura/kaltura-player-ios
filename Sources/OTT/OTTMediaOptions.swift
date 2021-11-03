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
    @objc public var urlType: String?
    @objc public var streamerType: String?
    @objc public var adapterData: [String: String]?
    
    internal func mediaProvider() -> PhoenixMediaProvider {
        let phoenixMediaProvider = PhoenixMediaProvider()
        phoenixMediaProvider.set(assetId: assetId)
        phoenixMediaProvider.set(type: assetType)
        phoenixMediaProvider.set(refType: assetReferenceType)
        phoenixMediaProvider.set(formats: formats)
        phoenixMediaProvider.set(fileIds: fileIds)
        phoenixMediaProvider.set(playbackContextType: playbackContextType)
        phoenixMediaProvider.set(networkProtocol: networkProtocol)
        phoenixMediaProvider.set(urlType: urlType)
        phoenixMediaProvider.set(streamerType: streamerType)
        phoenixMediaProvider.set(adapterData: adapterData)
        
        return phoenixMediaProvider
    }
    
    @discardableResult
    @nonobjc public func set(ks: String?) -> Self {
        self.ks = ks
        return self
    }
    
    @discardableResult
    @nonobjc public func set(assetId: String?) -> Self {
        self.assetId = assetId
        return self
    }
    
    @discardableResult
    @nonobjc public func set(assetType: AssetType) -> Self {
        self.assetType = assetType
        return self
    }
    
    @discardableResult
    @nonobjc public func set(assetReferenceType: AssetReferenceType) -> Self {
        self.assetReferenceType = assetReferenceType
        return self
    }
    
}
