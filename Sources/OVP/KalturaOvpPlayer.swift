//
//  KalturaOvpPlayer.swift
//  KalturaPlayer
//
//  Created by Vadik on 21/11/2017.
//

import Foundation
import PlayKit
import PlayKitKava

public class KalturaOvpPlayer: KalturaPlayer {
    let DEFAULT_SERVER_URL = "https://cdnapisec.kaltura.com/"
    
    static var pluginsRegistered: Bool = false
    
    var sessionProvider: SimpleOVPSessionProvider?
    
    override public init(partnerId: Int64, ks: String?, pluginConfig: PluginConfig?, options: KalturaPlayerOptions?) throws {
        try super.init(partnerId: partnerId, ks: ks, pluginConfig: pluginConfig, options: options)
    }
    
    override public func loadMedia(entryId: String, callback: ((PKMediaEntry?, Error?) -> Void)? = nil) {
        if let _ = sessionProvider {
            let provider = OVPMediaProvider(sessionProvider!)
            provider.set(entryId: entryId)
            
            provider.loadMedia { [weak self] (entry, error) in
                self?.mediaLoadCompleted(entry: entry, error: error, callback: callback)
            }
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
        sessionProvider?.ks = ks
        // FIXME temporarily disabled Kava
        //player.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: getKavaAnalyticsConfig())
    }
    
    override func initializeBackendComponents() {
        sessionProvider = SimpleOVPSessionProvider(serverURL: serverUrl, partnerId: partnerId, ks: ks)
    }
    
    func getKavaAnalyticsConfig() -> KavaPluginConfig {
        return KavaPluginConfig(partnerId: Int(partnerId), ks: ks, playbackContext: nil, referrer: referrer, customVar1: nil, customVar2: nil, customVar3: nil)
    }
}
