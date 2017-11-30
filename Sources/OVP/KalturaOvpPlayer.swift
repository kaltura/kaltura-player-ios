//
//  KalturaOvpPlayer.swift
//  KalturaPlayer
//
//  Created by Vadik on 21/11/2017.
//

import Foundation
import PlayKit
import PlayKitKava
import PlayKitOVP

public struct OVPMediaOptions {
    var entryId: String
    
    public init(entryId: String) {
        self.entryId = entryId
    }
}

public class KalturaOvpPlayer: KalturaPlayer<OVPMediaOptions> {
    let DEFAULT_SERVER_URL = "https://cdnapisec.kaltura.com/"
    
    static var pluginsRegistered: Bool = false

    var provider: OVPMediaProvider?
    
    override public init(partnerId: Int64, ks: String?, pluginConfig: PluginConfig?, options: KalturaPlayerOptions?) throws {
        try super.init(partnerId: partnerId, ks: ks, pluginConfig: pluginConfig, options: options)
    }
    
    override public func loadMedia(mediaOptions: OVPMediaOptions, callback: ((PKMediaEntry?, Error?) -> Void)? = nil) {
        provider = OVPMediaProvider()
        provider?
            .set(baseUrl: serverUrl)
            .set(ks: ks)
            .set(partnerId: partnerId)
            .set(entryId: mediaOptions.entryId)
        
        provider?.loadMedia { [weak self] (entry, error) in
            if let error = error {
                PKLog.error(error.localizedDescription)
            }
            self?.mediaLoadCompleted(entry: entry, error: error, callback: callback)
        }
    }
    
    override func getKalturaPluginConfigs() -> [String : Any]  {
        // FIXME temporarily disabled Kava
        //return [KavaPlugin.pluginName : getKavaAnalyticsConfig()]
        return [:]
    }
    
    override func getDefaultServerUrl() -> String {
        return DEFAULT_SERVER_URL
    }
    
    override func registerPlugins() {
        if !KalturaOvpPlayer.pluginsRegistered {
            PlayKitManager.shared.registerPlugin(KavaPlugin.self)
            KalturaOvpPlayer.pluginsRegistered = true
        }
    }
    
    override func updateKS(_ ks: String) {
        // FIXME temporarily disabled Kava
        //player.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: getKavaAnalyticsConfig())
    }
    
    override func initializeBackendComponents() {
    }
    
    func getKavaAnalyticsConfig() -> KavaPluginConfig {
        return KavaPluginConfig(partnerId: Int(partnerId), ks: ks, playbackContext: nil, referrer: referrer, customVar1: nil, customVar2: nil, customVar3: nil)
    }
}
