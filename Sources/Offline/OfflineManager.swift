//
//  OfflineManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 6/23/20.
//

import Foundation
import DownloadToGo
import PlayKit

public typealias OfflineSelectionOptions = DTGSelectionOptions

/// Delegate that will receive download events.
public protocol OfflineManagerDelegate: class {
    /// Some data was downloaded for the item.
    func item(id: String, didDownloadData totalBytesDownloaded: Int64, totalBytesEstimated: Int64?)
    
    /// Item has changed state. in case state will be failed, the error will be provided (interupted state could also provide error).
    func item(id: String, didChangeToState newState: AssetDownloadState, error: Error?)
}

public enum OfflineManagerError: PKError {
    case noMediaSourceToDownload
    case itemCanNotBeAdded(message: String)
    case loadItemMetadataFailed(message: String)
    case mediaProviderNotRetrieved
    case mediaProviderError(code:String, message:String)
    case invalidPKMediaEntry
    case mediaProviderUnsupported
    
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
        }
    }
    
    public var userInfo: [String: Any] {
        switch self {
        default:
            return [String: Any]()
        }
    }
}

@objc public class OfflineManager: NSObject {
    
    @objc public static let shared = OfflineManager()
    @objc public var localAssetsManager = LocalAssetsManager.managerWithDefaultDataStore()
    
    public weak var offlineManagerDelegate: OfflineManagerDelegate?

    private override init() {
        super.init()
        ContentManager.shared.delegate = self
    }
    
    deinit {
        ContentManager.shared.delegate = nil
    }
    
    // MARK: - Public Methods
    
    public func setDefaultAudioBitrateEstimation(bitrate: Int) {
        ContentManager.shared.setDefaultAudioBitrateEstimation(bitrate: bitrate)
    }
    
    public func prepareAsset(mediaEntry: PKMediaEntry, options: OfflineSelectionOptions, callback: @escaping (Error?, AssetInfo?) -> Void) {
        
        let itemId = mediaEntry.id
        guard let mediaSource = localAssetsManager.getPreferredDownloadableMediaSource(for: mediaEntry) else {
            PKLog.error("No preferred downloadable media source available.")
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
    
        * Parameters:
            * assetId: The asset's id.
    */
    public func startAssetDownload(assetId: String) {
        do {
            try ContentManager.shared.startItem(id: assetId)
        } catch {
            PKLog.error(error.localizedDescription)
        }
    }
    
    /**
        Pause downloading the asset.
    
        * Parameters:
            * assetId: The asset's id.
    */
    public func pauseAssetDownload(assetId: String) {
        do {
            try ContentManager.shared.pauseItem(id: assetId)
        } catch {
            PKLog.error(error.localizedDescription)
        }
    }
    
    /**
        Remove the asset with all it's data.
    
        * Parameters:
            * assetId: The asset's id.
    */
    public func removeAssetDownload(assetId: String) {
        do {
            guard let url = try ContentManager.shared.itemPlaybackUrl(id: assetId) else {
                PKLog.error("Can't get the local url in order to remove the downloaded asset.")
                return
            }
            
            localAssetsManager.unregisterDownloadedAsset(location: url, callback: { (error) in
                PKLog.debug("Unregister complete.")
            })
            
            try? ContentManager.shared.removeItem(id: assetId)
            
        } catch {
            PKLog.error(error.localizedDescription)
        }
    }
    
    public func getAssetInfo(assetId: String) -> AssetInfo? {
        guard let dtgItem = try? ContentManager.shared.itemById(assetId) else { return nil }
        
        return AssetInfo(item: dtgItem)
    }
    
    public func getLocalPlaybackEntry(assetId: String) -> PKMediaEntry? {
        guard let playbackURL = try? ContentManager.shared.itemPlaybackUrl(id: assetId) else {
            PKLog.debug("Can't get local url for \(assetId)")
            return nil
        }
        
        return localAssetsManager.createLocalMediaEntry(for: assetId, localURL: playbackURL)
    }
}
    
// MARK: - DRM

extension OfflineManager {
    
    public func getDRMStatus(assetId: String) -> DRMStatus? {
        guard let url = try? ContentManager.shared.itemPlaybackUrl(id: assetId) else {
            PKLog.debug("Can't get local url for \(assetId)")
            return nil
        }
        
        guard let fpsExpirationInfo = localAssetsManager.getLicenseExpirationInfo(location: url) else { return nil }
        
        return DRMStatus(fpsExpirationInfo)
    }
    
    public func renewDrmAssetLicense(mediaEntry: PKMediaEntry) {
        do {
            guard let url = try ContentManager.shared.itemPlaybackUrl(id: mediaEntry.id) else {
                PKLog.error("Can't get local url to renew DRM License.")
                return
            }
            
            guard let source = localAssetsManager.getPreferredDownloadableMediaSource(for: mediaEntry) else {
                PKLog.error("No valid source in order to renew DRM License.")
                return
            }
                        
            localAssetsManager.renewDownloadedAsset(location: url, mediaSource: source) { (error) in
                if let error = error {
                    PKLog.error("Renew DRM License failed with error: \(error)")
                } else {
                    PKLog.debug("Renew DRM License completed.")
                }
            }
            
        } catch {
            PKLog.error(error.localizedDescription)
        }
    }
}

// MARK: - KalturaPlayerOffline

extension OfflineManager: KalturaPlayerOffline {

    static func setup() {
        do {
            // Setup the content manager.
            try ContentManager.shared.setup()
            PKLog.debug("Home dir: \(NSHomeDirectory())")
            
            try ContentManager.shared.start() {
                PKLog.debug("Offline server started")
            }
            
            // Resume all interrupted downloads that were stopped in progress
            try ContentManager.shared.startItems(inStates: .inProgress)
        } catch {
            // Handle error here
            PKLog.error(error.localizedDescription)
        }
    }
}

// MARK: - ContentManagerDelegate

extension OfflineManager: ContentManagerDelegate {
    
    public func item(id: String, didDownloadData totalBytesDownloaded: Int64, totalBytesEstimated: Int64?) {
        offlineManagerDelegate?.item(id: id, didDownloadData: totalBytesDownloaded, totalBytesEstimated: totalBytesEstimated)
    }
    
    public func item(id: String, didChangeToState newState: DTGItemState, error: Error?) {
        offlineManagerDelegate?.item(id: id, didChangeToState: AssetDownloadState.getState(dtgItemState: newState), error: error)
    }
}
