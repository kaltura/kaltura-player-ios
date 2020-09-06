//
//  KalturaOTTPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/11/20.
//

import Foundation
import KalturaNetKit
import PlayKit
import PlayKitKava
import PlayKitProviders

class KalturaOTTPlayerManager: KalturaPlayerManager {
    
    internal static let shared = KalturaOTTPlayerManager()
    
    var partnerId: Int64
    var serverURL: String
    
    private override init() {
        partnerId = 0
        serverURL = ""
        super.init()
    }
    
    // MARK: - Private Methods
    
    override internal func fetchCachedConfigData() -> ConfigData? {
        let cachedOTTDMSConfig = KPOTTDMSConfigModel.shared.fetchPartnerConfig(partnerId)
        
        guard let cachedConfig = cachedOTTDMSConfig else { return nil }
        
        return ConfigData(analyticsUrl: cachedConfig.analyticsUrl,
                          ovpPartnerId: cachedConfig.ovpPartnerId,
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
        
        guard let request = KalturaRequestBuilder(url: url, service: "Configurations", action: "serveByDevice") else { return }
        
        request.set(method: .get)
        
        let ApplicationName = "com.kaltura.player." + String(partnerId)
        let ClientVersion = "4"
        let Platform = "iOS"
        let Tag = "1"
        let UDID = "kaltura-player-ios/4.0.0"
        
        request.setParam(key: "partnerId", value: String(partnerId))
        request.setParam(key: "applicationName", value: ApplicationName)
        request.setParam(key: "clientVersion", value: ClientVersion)
        request.setParam(key: "platform", value: Platform)
        request.setParam(key: "tag", value: Tag)
        request.setParam(key: "udid", value: UDID)

        request.set { [weak self] (response: Response) in
            PKLog.debug("Response: Status Code: \(response.statusCode) Error: \(response.error?.localizedDescription ?? "") Data: \(response.data ?? "")")
            guard let self = self else { return }
            
            guard let responseData = response.data else {
                PKLog.error("DMS Configuration response is empty.")
                callback(nil, response.error)
                return
            }
            
            if !JSONSerialization.isValidJSONObject(responseData) {
                PKLog.error("DMS Configuration response is not a valid JSON object.")
                callback(nil, response.error)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: responseData, options: .prettyPrinted)
                let decodedDMSConfig = try JSONDecoder().decode(DMSConfiguration.self, from: data)
                
                let analyticsUrl = decodedDMSConfig.params.analyticsUrl
                let ovpPartnerId = decodedDMSConfig.params.ovpPartnerId
                let ovpServiceUrl = decodedDMSConfig.params.ovpServiceUrl
                let uiConfId = decodedDMSConfig.params.uiConfId
                KPOTTDMSConfigModel.shared.addPartnerConfig(partnerId: self.partnerId,
                                                            ovpPartnerId: ovpPartnerId,
                                                            analyticsUrl: analyticsUrl,
                                                            ovpServiceUrl: ovpServiceUrl,
                                                            uiConfId: uiConfId)
                
                let configData = ConfigData(analyticsUrl: analyticsUrl,
                                            ovpPartnerId: ovpPartnerId,
                                            createdDate: Date())
                callback(configData, nil)
                
            } catch let error as NSError {
                PKLog.error("Couldn't parse data into DMSConfiguration error: \(error)")
                callback(nil, error)
            }
        }
        
        PKLog.debug("Sending request for the DMS Configuration.")
        USRExecutor.shared.send(request: request.build())
    }
}
