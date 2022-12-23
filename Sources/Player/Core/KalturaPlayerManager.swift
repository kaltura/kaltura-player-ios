//
//  KalturaPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/11/20.
//

import Foundation
import PlayKitUtils

protocol KalturaPlayerOffline {
    static func setup()
}

public struct ConfigData {
    public var analyticsUrl: String
    public var ovpPartnerId: Int64
    public var createdDate: Date
    
    public init(analyticsUrl: String,
                ovpPartnerId: Int64,
                createdDate: Date) {
        self.analyticsUrl = analyticsUrl
        self.ovpPartnerId = ovpPartnerId
        self.createdDate = createdDate
    }
}

open class KalturaPlayerManager: NSObject {
    
    let domain = "com.kaltura.player"
    public var referrer: String
    
    public override init() {
        referrer = PKUtils.referrer
        super.init()
        
        registerKnownPlugins()
        setupOfflineIfExists()
    }
    
    // MARK: - Configuration Data

    private let SOFT_EXPIRATION_SEC = 72 * 60 * 60 // Use the cached data for 3 days.
    private let HARD_EXPIRATION_SEC = 148 * 60 * 60 // Between 72 and 148 hours use the cached data and request a new one from the server.
    
    private var retryCount = 0
    private let maxRetries = 3
    
    open private(set) var cachedConfigData: ConfigData?
    
    open func fetchConfiguration() {
        retryCount = 0
        let cachedData = fetchCachedConfigData()
        
        guard let cachedConfigData = cachedData else {
            requestConfigData()
            return
        }
        
        let elapsedTime = Date().timeIntervalSince(cachedConfigData.createdDate)
        let secondsPassed = Int(elapsedTime)
        
        if secondsPassed < SOFT_EXPIRATION_SEC {
            self.cachedConfigData = cachedConfigData
        } else if secondsPassed < HARD_EXPIRATION_SEC {
            self.cachedConfigData = cachedConfigData
            requestConfigData()
        } else {
            // Request and if there is no response use cached data
            requestConfigData { [weak self] (configData, error) in
                guard let self = self else { return }
                if let configData = configData {
                    self.cachedConfigData = configData
                } else {
                    self.cachedConfigData = cachedConfigData
                }
            }
        }
    }
    
    open func requestConfigData() {
        requestConfigData { [weak self] (configData, error) in
            guard let self = self else { return }
            if let configData = configData {
                self.cachedConfigData = configData
            } else {
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.requestConfigData()
                }
            }
        }
    }
    
    open func fetchCachedConfigData() -> ConfigData? {
        fatalError("Function fetchCachedConfigData not implemented in sub class")
    }
    
    open func requestConfigData(callback: @escaping (ConfigData?, Error?) -> Void) {
        fatalError("Function requestConfigData not implemented in sub class")
    }
    
    // MARK: - Known Plugins
    
    private func registerKnownPlugins() {
        KnownPlugins.registerAllPlugins()
    }
    
    // MARK: - Offline
    
    private func setupOfflineIfExists() {
        if let offlineManagerClass = NSClassFromString("KalturaPlayer.OfflineManager") as? KalturaPlayerOffline.Type {
            offlineManagerClass.setup()
        }
    }
}
