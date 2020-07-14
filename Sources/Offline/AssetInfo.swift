//
//  AssetInfo.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/5/20.
//

import DownloadToGo

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

@objc public class AssetInfo: NSObject {
    
    @objc public var itemId: String {
        return downloadItem.id
    }
    
    @objc public var state: AssetDownloadState {
        get {
            return AssetDownloadState.getState(dtgItemState: downloadItem.state)
        }
    }
    
    @objc public var estimatedSize: Int64 {
        return downloadItem.estimatedSize ?? 0
    }
    
    @objc public var downloadedSize: Int64 {
        return downloadItem.downloadedSize
    }
    
    @objc public var progress: Float {
        if estimatedSize <= 0 { return 0.0 }
        
        if estimatedSize > downloadedSize {
            return Float(downloadedSize) / Float(estimatedSize)
        } else {
            return 1.0
        }
    }
    
    private var downloadItem: DTGItem
    
    internal init(item: DTGItem) {
        downloadItem = item
    }
    
    public override var description: String {
        return super.description + " itemId: \(itemId) state: \(state.description) estimatedSize: \(estimatedSize) downloadedSize: \(downloadedSize)"
    }
}
