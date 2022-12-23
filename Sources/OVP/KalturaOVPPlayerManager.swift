//
//  KalturaOVPPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/30/20.
//

import Foundation
import KalturaNetKit
import PlayKit
import KalturaPlayer

class KalturaOVPPlayerManager: KalturaPlayerManager {

    internal static let shared = KalturaOVPPlayerManager()
    
    var partnerId: Int64
    var serverURL: String
    
    private override init() {
        partnerId = 0
        serverURL = "https://cdnapisec.kaltura.com/"
        super.init()
    }
    
    // MARK: - Private Methods
    
    override internal func fetchCachedConfigData() -> ConfigData? {
        let cachedOVPConfig = KPOVPConfigModel.shared.fetchPartnerConfig(partnerId)
        
        guard let cachedConfig = cachedOVPConfig else { return nil }
        
        return ConfigData(analyticsUrl: cachedConfig.analyticsUrl,
                          ovpPartnerId: cachedConfig.partnerId,
                          createdDate: cachedConfig.createdDate)
    }
    
    override internal func requestConfigData(callback: @escaping (ConfigData?, Error?) -> Void) {
        
        // Fix the serverURL provided if needed, for the request.
        var url = serverURL
        if serverURL.hasSuffix("/api_v3/") {
            // Nothing to change
        } else if serverURL.hasSuffix("/api_v3") {
            url += "/"
        } else if serverURL.hasSuffix("/") {
            url += "api_v3/"
        } else {
            url += "/api_v3/"
        }
        
        guard let request = KalturaRequestBuilder(url: url, service: "partner", action: "getPublicInfo") else { return }
        
        request.setParam(key: "id", value: String(partnerId))
        request.setParam(key: "format", value:"1")
        
        request.set { [weak self] (response: Response) in
            PKLog.debug("Response: Status Code: \(response.statusCode) Error: \(response.error?.localizedDescription ?? "") Data: \(response.data ?? "")")
            guard let self = self else { return }
            
            guard let responseData = response.data else {
                PKLog.error("Configuration response is empty.")
                callback(nil, response.error)
                return
            }
            
            if !JSONSerialization.isValidJSONObject(responseData) {
                PKLog.error("Configuration response is not a valid JSON object.")
                callback(nil, response.error)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: responseData, options: .prettyPrinted)
                let decodedConfig = try JSONDecoder().decode(KalturaPartnerPublicInfo.self, from: data)
                
                let analyticsUrl = decodedConfig.analyticsUrl
                let analyticsPersistentSessionId = decodedConfig.analyticsPersistentSessionId

                KPOVPConfigModel.shared.addPartnerConfig(partnerId: self.partnerId,
                                                         analyticsUrl: analyticsUrl,
                                                         analyticsPersistentSessionId: analyticsPersistentSessionId)
                
                let configData = ConfigData(analyticsUrl: analyticsUrl, ovpPartnerId: self.partnerId, createdDate: Date())
                
                callback(configData, nil)
                
            } catch let error as NSError {
                PKLog.error("Couldn't parse data into DMSConfiguration error: \(error)")
                callback(nil, error)
            }
        }
        
        PKLog.debug("Sending request for the DMS Configuration.")
        KNKRequestExecutor.shared.send(request: request.build())
    }
}
