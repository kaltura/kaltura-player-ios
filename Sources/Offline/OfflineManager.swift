//
//  OfflineManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 6/23/20.
//

import Foundation
import DownloadToGo
import PlayKit

/**
    Selection options for the specific media to prepare for the download process.
 
    The default behavior is as following:
     - **Video -** Select the track most suitable for the current device (codec, width, height).
     - **Audio -** Select the default, as specified by the HLS playlist.
     - **Subtitles -** Select nothing.
 */
public typealias OfflineSelectionOptions = DTGSelectionOptions

/// Delegate that will receive download events.
@objc public protocol OfflineManagerDelegate: class {
    /**
        Some data was downloaded for the item.
     
        * Parameters:
            * id: The item's id.
            * totalBytesDownloaded: The total bytes downloaded for that item.
            * totalBytesEstimated: The total bytes estimated for that item.
            * completedFraction: The completed fraction for that item, a value from 0 to 1.
     */
    @objc func item(id: String, didDownloadData totalBytesDownloaded: Int64, totalBytesEstimated: Int64, completedFraction: Float)
    
    /**
        The item has changed state.
     
        In case of a failed state, the error will be provided.
     
        * Parameters:
            * id: The item's id.
            * newState: The new state of the item. See `AssetDownloadState` for more details.
            * error: An `Error` if an error has occurred, otherwise nil.
    */
    @objc func item(id: String, didChangeToState newState: AssetDownloadState, error: Error?)
}

/**
    Errors that can occur in the `OfflineManager` in various places will be represented as an `OfflineManagerError`.

    Each error has a `code` and an `errorDescription`.
    
    *Available errors:*
    * noMediaSourceToDownload
    * itemCanNotBeAdded
    * loadItemMetadataFailed
    * mediaProviderNotRetrieved
    * mediaProviderError
    * invalidPKMediaEntry
    * mediaProviderUnsupported
    * startAssetError
    * pauseAssetError
    * removeAssetError
    * renewAssetDRMLicenseError
 */
public enum OfflineManagerError: PKError {
    case noMediaSourceToDownload
    case itemCanNotBeAdded(message: String)
    case loadItemMetadataFailed(message: String)
    case mediaProviderNotRetrieved
    case mediaProviderError(code:String, message:String)
    case invalidPKMediaEntry
    case mediaProviderUnsupported
    case startAssetError(message: String)
    case pauseAssetError(message: String)
    case removeAssetError(message: String)
    case renewAssetDRMLicenseError(message: String)
    
    public static let domain = "com.kaltura.player.offline.error"
    public static let serverErrorCodeKey = "code"
    public static let serverErrorMessageKey = "message"
    
    public var code: Int {
        switch self {
        case .noMediaSourceToDownload: return 8801
        case .itemCanNotBeAdded: return 8802
        case .loadItemMetadataFailed: return 8803
        case .mediaProviderNotRetrieved: return 8804
        case .mediaProviderError: return 8805
        case .invalidPKMediaEntry: return 8806
        case .mediaProviderUnsupported: return 8807
        case .startAssetError: return 8808
        case .pauseAssetError: return 8809
        case .removeAssetError: return 8810
        case .renewAssetDRMLicenseError: return 8811
        }
    }
    
    public var errorDescription: String {
        switch self {
        case .noMediaSourceToDownload: return "No preferred downloadable media source available."
        case .itemCanNotBeAdded(let message): return "The item can't be added: \(message)"
        case .loadItemMetadataFailed(let message): return "Load item metadata failed: \(message)"
        case .mediaProviderNotRetrieved: return "Fetching the Media Provider from the media options returned with an empty provider."
        case .mediaProviderError(let code, let message): return "Media Provider Error, code: \(code), \n message: \(message)"
        case .invalidPKMediaEntry: return "Load media on the provider returned with an empty PKMediaEntry."
        case .mediaProviderUnsupported: return "The retrieved Media Provider from the media options is not supported."
        case .startAssetError(let message): return "Attempt to start the asset failed with the following: \(message)"
        case .pauseAssetError(let message): return "Attempt to pause the asset failed with the following: \(message)"
        case .removeAssetError(let message): return "Attempt to remove the asset failed with the following: \(message)"
        case .renewAssetDRMLicenseError(let message): return "Attempt to renew the asset DRM License failed with the following: \(message)"
        }
    }
    
    public var userInfo: [String: Any] {
        switch self {
        case .mediaProviderError(let code, let message):
            return [OfflineManagerError.serverErrorCodeKey: code,
                    OfflineManagerError.serverErrorMessageKey: message]
        default:
            return [String: Any]()
        }
    }
}

/**
    The `OfflineManager` provides you with a way to download medias and play them locally.
    It provides a shared instance in order to perform all actions needed on the media asset.
 
     **Example:**
 
         try? OfflineManager.shared.startAssetDownload(assetId: "123456")
 */
@objc public class OfflineManager: NSObject {
    
    /// This is the shared instance of the `OfflineManager` that should be used.
    @objc public static let shared = OfflineManager()
    /// This is the `LocalAssetsManager`, a default Data Store is used.
    @objc public var localAssetsManager = LocalAssetsManager.managerWithDefaultDataStore()
    
    /// The delegate to receive the download events. See `OfflineManagerDelegate` for more info.
    @objc public weak var offlineManagerDelegate: OfflineManagerDelegate?

    private override init() {
        super.init()
        ContentManager.shared.delegate = self
    }
    
    deinit {
        ContentManager.shared.delegate = nil
    }
    
    // MARK: - Public Methods
    
    /**
        Set the default audio bitrate for size-estimation purposes. Defaults to 64000.
     
        * Parameters:
            * bitrate: A desired bitrate.
     */
    @objc public func setDefaultAudioBitrateEstimation(bitrate: Int) {
        ContentManager.shared.setDefaultAudioBitrateEstimation(bitrate: bitrate)
    }
    
    /**
        Call this function to prepare the asset in order to start downloading the media.
            
        The function will fetch the preferred `PKMediaSource` for download purposes, taking into account the capabilities of the device. If a media source was not retrieved, an `OfflineManagerError.noMediaSourceToDownload` is returned.
     
        The item will be added to the ContentManager, in case of an error, an `OfflineManagerError.itemCanNotBeAdded` with the error message will be returned.
     
        The item metadata will be loaded with the `OfflineSelectionOptions` provided. In case of an error an `OfflineManagerError.loadItemMetadataFailed` with the error message will be returned.
     
        If all has been successful, an `AssetInfo` object will be returned.
     
        If it's a DRM media the license will be registered automatically.
     
        * Parameters:
            * mediaEntry: The `PKMediaEntry` in order to retrieve the media source. See `PKMediaEntry` for more details.
            * options: The preferred options for selection. See `OfflineSelectionOptions` for more details.
            * callback:
            * error: An `OfflineManagerError` if an error has occurred, otherwise nil. See `OfflineManagerError` for more details.
            * assetInfo: The asset info object, otherwise nil. See `AssetInfo` for more details.
     */
    public func prepareAsset(mediaEntry: PKMediaEntry, options: OfflineSelectionOptions, callback: @escaping (_ error: Error?, _ assetInfo: AssetInfo?) -> Void) {
        
        let itemId = mediaEntry.id
        guard let mediaSource = localAssetsManager.getPreferredDownloadableMediaSource(for: mediaEntry) else {
            PKLog.error("No downloadable media source available.")
            callback(OfflineManagerError.noMediaSourceToDownload, nil)
            return
        }
        
        PKLog.debug("Media source selected to download: \(String(describing: mediaSource.contentUrl))")
        
        var item: DTGItem?
        do {
            item = try ContentManager.shared.itemById(itemId)
            if item?.state == .new {
                // In case the item is still in the new state then something happened, shouldn't be an item with this state, remove it and create a new one.
                try ContentManager.shared.removeItem(id: itemId)
                item = nil
            }
            
            if item == nil {
                item = try ContentManager.shared.addItem(id: itemId, url: mediaSource.contentUrl!)
            }
        } catch {
            PKLog.error("The item can't be added: " + error.localizedDescription)
            callback(OfflineManagerError.itemCanNotBeAdded(message: error.localizedDescription), nil)
            return
        }

        guard let dtgItem = item else {
            PKLog.error("The item can't be added: ContentManager - Empty item returned.")
            callback(OfflineManagerError.itemCanNotBeAdded(message: "ContentManager - Empty item returned."), nil)
            return
        }
        
        let assetInfo = AssetInfo(item: dtgItem)
        
        DispatchQueue.global().async {
            do {
                try ContentManager.shared.loadItemMetadata(id: itemId, options: options)
                
                // Register the DRM License if exists.
                if let url = try? ContentManager.shared.itemPlaybackUrl(id: itemId) {
                    self.localAssetsManager.renewDownloadedAsset(location: url, mediaSource: mediaSource) { (error) in
                        if let error = error {
                            PKLog.error("Renew DRM License failed with error: \(error.localizedDescription)")
                        }
                    }
                }
                
                PKLog.debug("Item Metadata Loaded")
                callback(nil, assetInfo)
            } catch {
                DispatchQueue.main.async {
                    PKLog.error("Load item metadata failed: " + error.localizedDescription)
                    callback(OfflineManagerError.loadItemMetadataFailed(message: error.localizedDescription), nil)
                }
            }
        }
    }
    
    /**
        Start or resume downloading the asset.
     
        In case of an error, an `OfflineManagerError.startAssetError` with the error message will be thrown.
    
        * Parameters:
            * assetId: The asset's id.
    */
    @objc public func startAssetDownload(assetId: String) throws {
        do {
            try ContentManager.shared.startItem(id: assetId)
        } catch {
            PKLog.error(error.localizedDescription)
            throw OfflineManagerError.startAssetError(message: error.localizedDescription)
        }
    }
    
    /**
        Pause downloading the asset.
     
        In case of an error, an `OfflineManagerError.pauseAssetError` with the error message will be thrown.
    
        * Parameters:
            * assetId: The asset's id.
    */
    @objc public func pauseAssetDownload(assetId: String) throws {
        do {
            try ContentManager.shared.pauseItem(id: assetId)
        } catch {
            PKLog.error(error.localizedDescription)
            throw OfflineManagerError.pauseAssetError(message: error.localizedDescription)
        }
    }
    
    /**
        Remove the asset with all it's data.
     
        In case of an error, an `OfflineManagerError.removeAssetError` with the error message will be thrown.
    
        * Parameters:
            * assetId: The asset's id.
    */
    @objc public func removeAssetDownload(assetId: String) throws {
        do {
            guard let url = try? ContentManager.shared.itemPlaybackUrl(id: assetId) else {
                PKLog.error("Can't get the local url in order to remove the downloaded asset.")
                throw OfflineManagerError.removeAssetError(message: "Can't get the local url in order to remove the downloaded asset.")
            }
            
            localAssetsManager.unregisterDownloadedAsset(location: url, callback: { (error) in
                PKLog.debug("Unregister complete.")
            })
            
            try ContentManager.shared.removeItem(id: assetId)
            
        } catch {
            PKLog.error(error.localizedDescription)
            throw OfflineManagerError.removeAssetError(message: error.localizedDescription)
        }
    }
    
    /**
        This function will fetch for the item by the given id and return an `AssetInfo` object.
     
        * Parameters:
            * assetId: The asset's id.
     
        * Returns: An `AssetInfo` if the item was found, nil otherwise.
     */
    @objc public func getAssetInfo(assetId: String) -> AssetInfo? {
        guard let dtgItem = try? ContentManager.shared.itemById(assetId) else { return nil }
        
        return AssetInfo(item: dtgItem)
    }
    
    /**
        This function will fetch for the item by the given id and return the local `PKMediaEntry`.
     
        * Parameters:
            * assetId: The asset's id.
     
        * Returns: A `PKMediaEntry` if the local item was found, nil otherwise.
     */
    @objc public func getLocalPlaybackEntry(assetId: String) -> PKMediaEntry? {
        guard let playbackURL = try? ContentManager.shared.itemPlaybackUrl(id: assetId) else {
            PKLog.debug("Can't get local url for \(assetId)")
            return nil
        }
        
        return localAssetsManager.createLocalMediaEntry(for: assetId, localURL: playbackURL)
    }
}
    
// MARK: - DRM

extension OfflineManager {
    
    /**
        This function will fetch for the item by the given id and return its `DRMStatus` if available.
     
        * Parameters:
            * assetId: The asset's id.
     
        * Returns: A `DRMStatus` if the item was found and has DRM data, nil otherwise.
     */
    @objc public func getDRMStatus(assetId: String) -> DRMStatus? {
        guard let url = try? ContentManager.shared.itemPlaybackUrl(id: assetId) else {
            PKLog.debug("Can't get local url for \(assetId)")
            return nil
        }
        
        guard let fpsExpirationInfo = localAssetsManager.getLicenseExpirationInfo(location: url) else { return nil }
        
        return DRMStatus(fpsExpirationInfo)
    }
    
    /**
        Renew the asset DRM license.
     
        In case of an error, an `OfflineManagerError.renewAssetDRMLicenseError` with the error message will be returned.
     
        * Parameters:
            * mediaEntry: The mediaEntry in order to renew the DRM License.
            * callback:
            * error: An `OfflineManagerError` if an error has occurred, otherwise nil. See `OfflineManagerError` for more details.
     */
    @objc public func renewAssetDRMLicense(mediaEntry: PKMediaEntry, callback: @escaping (_ error: Error?) -> Void) {
        do {
            guard let url = try ContentManager.shared.itemPlaybackUrl(id: mediaEntry.id) else {
                let message = "Can't get local url to renew DRM License."
                PKLog.error(message)
                callback(OfflineManagerError.renewAssetDRMLicenseError(message: message))
                return
            }
            
            guard let source = localAssetsManager.getPreferredDownloadableMediaSource(for: mediaEntry) else {
                let message = "No valid source in order to renew DRM License."
                PKLog.error(message)
                callback(OfflineManagerError.renewAssetDRMLicenseError(message: message))
                return
            }
                        
            localAssetsManager.renewDownloadedAsset(location: url, mediaSource: source) { (error) in
                if let error = error {
                    PKLog.error("Renew DRM License failed with error: \(error.localizedDescription)")
                    callback(OfflineManagerError.renewAssetDRMLicenseError(message: error.localizedDescription))
                } else {
                    PKLog.debug("Renew DRM License completed.")
                    callback(nil)
                }
            }
            
        } catch {
            PKLog.error(error.localizedDescription)
            callback(OfflineManagerError.renewAssetDRMLicenseError(message: error.localizedDescription))
        }
    }
}

// MARK: - KalturaPlayerOffline

extension OfflineManager: KalturaPlayerOffline {
    
    /**
        This function will be called automatically upon creation of the KalturaPlayerManager.
     
        It calls the `ContentManager` for setup and then start.
        After that a call to resume the `inProgress` and `interrupted` tasks is performed.
     */
    internal static func setup() {
        do {
            // Setup the content manager.
            try ContentManager.shared.setup()
            PKLog.debug("Home dir: \(NSHomeDirectory())")
            
            try ContentManager.shared.start() {
                PKLog.debug("Offline server started")
            }
            
            // Resume all interrupted downloads that were stopped in progress
            try ContentManager.shared.startItems(inStates: .inProgress, .interrupted)
        } catch {
            // Handle error here
            PKLog.error(error.localizedDescription)
        }
    }
}

// MARK: - ContentManagerDelegate

extension OfflineManager: ContentManagerDelegate {
    
    public func item(id: String, didDownloadData totalBytesDownloaded: Int64, totalBytesEstimated: Int64?, completedFraction: Float) {
        offlineManagerDelegate?.item(id: id, didDownloadData: totalBytesDownloaded, totalBytesEstimated: totalBytesEstimated ?? 0, completedFraction: completedFraction)
    }
    
    public func item(id: String, didChangeToState newState: DTGItemState, error: Error?) {
        offlineManagerDelegate?.item(id: id, didChangeToState: AssetDownloadState.getState(dtgItemState: newState), error: error)
    }
}
