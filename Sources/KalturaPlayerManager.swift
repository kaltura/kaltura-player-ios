//
//  KalturaPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/11/20.
//

import Foundation

struct ConfigData {
    var analyticsUrl: String
    var ovpPartnerId: Int64
    var ovpServiceUrl: String
    var uiConfId: Int64
    var createdDate: Date
}

class KalturaPlayerManager: NSObject {
    
    let domain = "com.kaltura.player"
    
    internal override init() {
        super.init()
        
        registerKnownPlugins()
    }
    
    // MARK: - Configuration Data

    private let SOFT_EXPIRATION_SEC = 72 * 60 * 60 // Use the cached data for 3 days.
    private let HARD_EXPIRATION_SEC = 148 * 60 * 60 // Between 72 and 148 hours use the cached data and request a new one from the server.
    
    private var retryCount = 0
    private let maxRetries = 3
    
    internal private(set) var cachedConfigData: ConfigData?
    
    internal func fetchConfiguration() {
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
    
    private func requestConfigData() {
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
    
    internal func fetchCachedConfigData() -> ConfigData? {
        #if DEBUG
        fatalError("Function fetchCachedConfigData not implemented in sub class")
        #else
        return nil
        #endif
    }
    
    internal func requestConfigData(callback: @escaping (ConfigData?, Error?) -> Void) {
        #if DEBUG
        fatalError("Function requestConfigData not implemented in sub class")
        #else
        return nil
        #endif
    }
    
    // MARK: - Known Plugins
    
    private func registerKnownPlugins() {
        KnownPlugins.registerAllPlugins()
    }
}
