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
}

@objc public class AssetInfo: NSObject {
    
    @objc public var itemId: String {
        return downloadItem.id
    }
    
    @objc public var state: AssetDownloadState {
        get {
            switch (downloadItem.state) {
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
    
    @objc public var estimatedSize: Int64 {
        return downloadItem.estimatedSize ?? 0
    }
    
    @objc public var downloadedSize: Int64 {
        return downloadItem.downloadedSize
    }
    
    private var downloadItem: DTGItem
    
    init(item: DTGItem) {
        downloadItem = item
    }
}
