//
//  KalturaOvpPlayer.swift
//  KalturaPlayer
//
//  Created by Vadik on 21/11/2017.
//

import Foundation
import PlayKit
import PlayKitOTT
import PlayKitKava

public struct PhoenixMediaOptions {
    var assetId: String
    var fileIds: [String]
    
    var assetType: AssetType = .media
    var playbackContextType: PlaybackContextType = .playback
    var networkProtocol: String = "https"
    
    public init(assetId: String, fileIds: [String]) {
        self.assetId = assetId
        self.fileIds = fileIds
    }
}

public class KalturaPhoenixPlayer: KalturaPlayer<PhoenixMediaOptions> {
   
    static var pluginsRegistered: Bool = false
    
    var mediaProvider: PhoenixMediaProvider?
    
    public override init(partnerId: Int64, ks: String?, pluginConfig: PluginConfig?, options: KalturaPlayerOptions?) throws {
        try super.init(partnerId: partnerId, ks: ks, pluginConfig: pluginConfig, options: options)
    }
    
    override public func loadMedia(mediaOptions: PhoenixMediaOptions, callback: ((PKMediaEntry?, Error?) -> Void)? = nil) {
        mediaProvider = PhoenixMediaProvider()
            .set(ks: ks)
            .set(baseUrl: serverUrl)
            .set(partnerId: partnerId)
            .set(type: mediaOptions.assetType)
            .set(assetId: mediaOptions.assetId)
            .set(fileIds: mediaOptions.fileIds)
            .set(networkProtocol: mediaOptions.networkProtocol)
            .set(playbackContextType: mediaOptions.playbackContextType)
        
        mediaProvider?.loadMedia(callback: { [weak self] (entry, error) in
            if let error = error {
                PKLog.error(error.localizedDescription)
            }
            self?.mediaLoadCompleted(entry: entry, error: error, callback: callback)
        })
    }
    
    override func getKalturaPluginConfigs() -> [String : Any]  {
        // FIXME temporarily disabled analytics
        //return [KavaPlugin.pluginName : getKavaAnalyticsConfig(), PhoenixAnalyticsPlugin.pluginName : getPhoenixAnalyticsConfig()]
        return [PhoenixAnalyticsPlugin.pluginName : getPhoenixAnalyticsConfig()]
    }
    
    override func getDefaultServerUrl() -> String {
        return ""
    }
    
    override func updateKS(_ ks: String) {
        // FIXME temporarily disabled analytics
        //player.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: getKavaAnalyticsConfig())
        player.updatePluginConfig(pluginName: PhoenixAnalyticsPlugin.pluginName, config: getPhoenixAnalyticsConfig())
    }
    
    override func registerPlugins() {
        if !KalturaPhoenixPlayer.pluginsRegistered {
            PlayKitManager.shared.registerPlugin(KavaPlugin.self)
            PlayKitManager.shared.registerPlugin(PhoenixAnalyticsPlugin.self)
            KalturaPhoenixPlayer.pluginsRegistered = true
        }
    }
    
    override func initializeBackendComponents() {
    }
    
    func getKavaAnalyticsConfig() -> KavaPluginConfig {
        return KavaPluginConfig(partnerId: Int(partnerId), ks: nil, playbackContext: nil, referrer: referrer, customVar1: nil, customVar2: nil, customVar3: nil)
    }
    
    func getPhoenixAnalyticsConfig() -> PhoenixAnalyticsPluginConfig {
        return PhoenixAnalyticsPluginConfig(baseUrl: serverUrl, timerInterval: 30, ks: ks ?? "", partnerId: Int(partnerId))
    }
}
