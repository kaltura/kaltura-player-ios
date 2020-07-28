//
//  AssetInfo.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/5/20.
//

import DownloadToGo

/**
    Represents the asset's download state.
 
    *Available Values:*
    * new
    * prepared
    * started
    * paused
    * completed
    * failed
    * outOfSpace
*/
@objc public enum AssetDownloadState: Int, CustomStringConvertible {
    case new, prepared, started, paused, completed, failed, outOfSpace
    
    public var description: String {
        switch self {
        case .new: return "New"
        case .prepared: return "Prepared"
        case .started: return "Started"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .outOfSpace: return "Out Of Space"
        }
    }
    
    /**
        Retrieves the asset's download state depending on the `DTGItemState`.
     
        * Parameters:
            * dtgItemState: The dtg item state to convert.
     
        * Returns: The asset's download state. See `AssetDownloadState` values.
     */
    internal static func getState(dtgItemState: DTGItemState) -> AssetDownloadState {
        switch dtgItemState {
        case .new, .removed:
            return AssetDownloadState.new
        case .metadataLoaded:
            return AssetDownloadState.prepared
        case .inProgress:
            return AssetDownloadState.started
        case .paused, .interrupted:
            return AssetDownloadState.paused
        case .completed:
            return AssetDownloadState.completed
        case .failed:
            return AssetDownloadState.failed
        case .dbFailure:
            return AssetDownloadState.outOfSpace
        }
    }
}


/// An `AssetInfo` object that provides information regarding the asset that is being downloaded.
@objc public class AssetInfo: NSObject {
    
    /// The asset's id.
    @objc public var itemId: String {
        return downloadItem.id
    }
    
    /// The asset's state. See `AssetDownloadState` for more info.
    @objc public var state: AssetDownloadState {
        get {
            return AssetDownloadState.getState(dtgItemState: downloadItem.state)
        }
    }
    
    /// The asset's estimated size.
    @objc public var estimatedSize: Int64 {
        return downloadItem.estimatedSize ?? 0
    }
    
    /// The asset's downloaded size.
    @objc public var downloadedSize: Int64 {
        return downloadItem.downloadedSize
    }
    
    /// The asset's progress. A value between 0 and 1.
    @objc public var progress: Float {
        return downloadItem.completedFraction
    }
    
    private var downloadItem: DTGItem
    
    internal init(item: DTGItem) {
        downloadItem = item
    }
    
    @objc public override var description: String {
        return super.description + " itemId: \(itemId) state: \(state.description) estimatedSize: \(estimatedSize) downloadedSize: \(downloadedSize)"
    }
}
