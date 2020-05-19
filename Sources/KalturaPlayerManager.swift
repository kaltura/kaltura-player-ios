//
//  KalturaPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/11/20.
//

import Foundation

public struct DMSConfigData {
    var analyticsUrl: String
    var ovpPartnerId: Int64
    var ovpServiceUrl: String
    var uiConfId: Int64
    var createdDate: Date
}

public class KalturaPlayerManager: NSObject {
    
    let domain = "com.kaltura.player"
    
    private let SOFT_EXPIRATION_SEC = 72 * 60 * 60 // Use the cashed data for 3 days.
    private let HARD_EXPIRATION_SEC = 148 * 60 * 60 // Between 72 and 148 hours use the cached data and request a new one from the server.
    
    internal private(set) var cachedDMSConfigData: DMSConfigData?
    
    internal override init() {
        super.init()
    }
    
    internal func fetchDMSConfiguration() {
        
        let cachedData = fetchCachedDMSConfigData()
        
        guard let cachedConfigData = cachedData else {
            requestDMSConfigData()
            return
        }
        
        let elapsedTime = Date().timeIntervalSince(cachedConfigData.createdDate)
        let secondsPassed = Int(elapsedTime)
        
        if secondsPassed < SOFT_EXPIRATION_SEC {
            cachedDMSConfigData = cachedConfigData
        } else if secondsPassed < HARD_EXPIRATION_SEC {
            cachedDMSConfigData = cachedConfigData
            requestDMSConfigData()
        } else {
            // Request and if there is no response use cached data
            requestDMSConfigData { [weak self] (dmsConfigData, error) in
                guard let self = self else { return }
                if let configData = dmsConfigData {
                    self.cachedDMSConfigData = configData
                } else {
                    self.cachedDMSConfigData = cachedConfigData
                }
            }
        }
    }
    
    private func requestDMSConfigData() {
        requestDMSConfigData { [weak self] (dmsConfigData, error) in
            guard let self = self else { return }
            if let configData = dmsConfigData {
                self.cachedDMSConfigData = configData
            } else {
                // TODO: retry 3 times
            }
        }
    }
    
    func fetchCachedDMSConfigData() -> DMSConfigData? {
        #if DEBUG
        fatalError("Function fetchCachedDMSConfigData not implemented in sub class")
        #else
        return nil
        #endif
    }
    
    func requestDMSConfigData(callback: @escaping (DMSConfigData?, Error?) -> Void) {
        #if DEBUG
        fatalError("Function requestDMSConfigData not implemented in sub class")
        #else
        return nil
        #endif
    }
}
