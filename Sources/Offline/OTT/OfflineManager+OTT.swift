//
//  OfflineManager+OTT.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/19/20.
//

import Foundation
import PlayKit
import PlayKitProviders

extension OfflineManager {
    
    private func retrieveMediaEntry(mediaOptions: OTTMediaOptions, callback: @escaping (Error?, PKMediaEntry?) -> Void) {
        let phoenixMediaProvider = mediaOptions.mediaProvider()
        
        let sessionProvider = SimpleSessionProvider(serverURL: KalturaOTTPlayerManager.shared.serverURL,
                                                    partnerId: KalturaOTTPlayerManager.shared.partnerId,
                                                    ks: mediaOptions.ks)
        
        phoenixMediaProvider.set(referrer: KalturaOTTPlayerManager.shared.referrer)
        phoenixMediaProvider.set(sessionProvider: sessionProvider)
        
        phoenixMediaProvider.loadMedia { (pkMediaEntry, error) in
            guard let mediaEntry = pkMediaEntry else {
                if let error = error {
                    switch error {
                    case let nsError as NSError:
                        callback(OfflineManagerError.mediaProviderError(code: String(nsError.code), message: nsError.description), nil)
                    case let pkError as PKError:
                        callback(OfflineManagerError.mediaProviderError(code: String(pkError.code), message: pkError.errorDescription), nil)
                    default:
                        callback(OfflineManagerError.mediaProviderError(code: "LoadMediaError", message: error.localizedDescription), nil)
                    }
                } else {
                    callback(OfflineManagerError.invalidPKMediaEntry, nil)
                }
                return
            }
            callback(error, mediaEntry)
        }
    }
    
    public func prepareAsset(mediaOptions: OTTMediaOptions, options: OfflineSelectionOptions, callback: @escaping (Error?, AssetInfo?, PKMediaEntry?) -> Void) {
        
        retrieveMediaEntry(mediaOptions: mediaOptions) { (error, pkMediaEntry) in
            guard let mediaEntry = pkMediaEntry else {
                callback(error, nil, nil)
                return
            }
            
            self.prepareAsset(mediaEntry: mediaEntry, options: options) { (error, assetInfo) in
                callback(error, assetInfo, mediaEntry)
            }
        }
    }
}

// MARK: - DRM

extension OfflineManager {
    
    public func renewDrmAssetLicense(mediaOptions: OTTMediaOptions) {
        retrieveMediaEntry(mediaOptions: mediaOptions) { [weak self] (error, pkMediaEntry) in
            guard let self = self else { return }
            
            guard let mediaEntry = pkMediaEntry else {
                PKLog.error("The PKMediaEntry could not be retrieved, error: \(String(describing: error))")
                return
            }
            
            self.renewDrmAssetLicense(mediaEntry: mediaEntry)
        }
    }
}
