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
    
    /**
        This function will retrieve the `PKMediaEntry` for the given `OTTMediaOptions`.
     
        * Parameters:
            * mediaOptions: The media options required to retrieve the media entry. See `OTTMediaOptions` for more details.
            * callback:
            * error: An `OfflineManagerError` if occurred, otherwise nil. See `OfflineManagerError` for more details.
            * mediaEntry: A `PKMediaEntry` if retrieved, otherwise nil. See `PKMediaEntry` for more details.
     */
    private func retrieveMediaEntry(mediaOptions: OTTMediaOptions, callback: @escaping (_ error: Error?, _ mediaEntry: PKMediaEntry?) -> Void) {
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
    
    /**
        Call this function to prepare the asset in order to start downloading the media.
            
        The function will retrieve the `PKMediaEntry` with the media options provided.
     
        The function will fetch the preferred `PKMediaSource` for download purposes, taking into account the capabilities of the device. If a media source was not retrieved, an `OfflineManagerError.noMediaSourceToDownload` is returned.
     
        The item will be added to the ContentManager. In case of an error, an `OfflineManagerError.itemCanNotBeAdded` with the error message will be returned.
     
        The item metadata will be loaded with the `OfflineSelectionOptions` provided. In case of an error an `OfflineManagerError.loadItemMetadataFailed` with the error message will be returned.
     
        If all has been successful, an `AssetInfo` and `PKMediaEntry` object will be returned.
     
        * Parameters:
            * mediaOptions: The media options to use for fetching the mediaEntry. See `OTTMediaOptions` for more details.
            * options: The preferred options for selection. See `OfflineSelectionOptions` for more details.
            * callback:
            * error: An `OfflineManagerError` if an error has occurred, otherwise nil. See `OfflineManagerError` for more details.
            * assetInfo: The asset info object, otherwise nil. See `AssetInfo` for more details.
            * mediaEntry: The `PKMediaEntry` retrieved, otherwise nil. See `PKMediaEntry` for more details.
     */
    @objc public func prepareAsset(mediaOptions: OTTMediaOptions, options: OfflineSelectionOptions, callback: @escaping (_ error: Error?, _ assetInfo: AssetInfo?, _ mediaEntry: PKMediaEntry?) -> Void) {
        
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
    
    /**
        Renew the asset DRM license.
    
        The function will retrieve the `PKMediaEntry` with the media options provided.
        In case of an error, an `OfflineManagerError.renewAssetDRMLicenseError` with the error message will be returned.
    
        * Parameters:
           * mediaOptions: The media options to use for fetching the mediaEntry. See `OTTMediaOptions` for more details.
           * callback:
           * error: An `OfflineManagerError` if an error has occurred, otherwise nil. See `OfflineManagerError` for more details.
    */
    public func renewAssetDRMLicense(mediaOptions: OTTMediaOptions, callback: @escaping (_ error: Error?) -> Void) {
        retrieveMediaEntry(mediaOptions: mediaOptions) { [weak self] (error, pkMediaEntry) in
            guard let self = self else { return }
            
            guard let mediaEntry = pkMediaEntry else {
                PKLog.error("The PKMediaEntry could not be retrieved, error: \(String(describing: error))")
                callback(OfflineManagerError.renewAssetDRMLicenseError(message: error.debugDescription))
                return
            }
            
            self.renewAssetDRMLicense(mediaEntry: mediaEntry) { (error) in
                callback(error)
            }
        }
    }
}
