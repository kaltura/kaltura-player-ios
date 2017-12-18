// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import PlayKit
import PlayKitOTT
import PlayKitKava

public class PhoenixMediaOptions: MediaOptions {
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
    
    public static func create(with options: KalturaPlayerOptions?) -> KalturaPhoenixPlayer? {
        do {
            return try KalturaPhoenixPlayer(options: options)
        } catch let e {
            print("error on player initializing:", e.localizedDescription)
        }
        return nil
    }
    
    public override func loadMedia(mediaOptions: PhoenixMediaOptions, callback: ((PKMediaEntry?, Error?) -> Void)? = nil) {
        if let mediaKS = mediaOptions.ks {
            setKS(mediaKS)
        }
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
        
        updatePluginConfig(pluginName: KalturaStatsPlugin.pluginName, config: getKalturaStatsConfig())
    }
    
    override func getKalturaPluginConfigs() -> [String : Any]  {
        return [KavaPlugin.pluginName : getKavaAnalyticsConfig(), PhoenixAnalyticsPlugin.pluginName : getPhoenixAnalyticsConfig(), KalturaStatsPlugin.pluginName : getKalturaStatsConfig()]
    }
    
    override func getDefaultServerUrl() -> String {
        return ""
    }
    
    override func updateKS(_ ks: String) {
        player.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: getKavaAnalyticsConfig())
        player.updatePluginConfig(pluginName: KalturaStatsPlugin.pluginName, config: getKalturaStatsConfig())
        player.updatePluginConfig(pluginName: PhoenixAnalyticsPlugin.pluginName, config: getPhoenixAnalyticsConfig())
    }
    
    override func registerPlugins() {
        if !KalturaPhoenixPlayer.pluginsRegistered {
            PlayKitManager.shared.registerPlugin(KavaPlugin.self)
            PlayKitManager.shared.registerPlugin(KalturaStatsPlugin.self)
            PlayKitManager.shared.registerPlugin(PhoenixAnalyticsPlugin.self)
            KalturaPhoenixPlayer.pluginsRegistered = true
        }
    }
    
    func getKavaAnalyticsConfig() -> KavaPluginConfig {
        return KavaPluginConfig(partnerId: partnerId, ks: nil, playbackContext: nil, referrer: referrer, customVar1: nil, customVar2: nil, customVar3: nil)
    }
    
    func getKalturaStatsConfig() -> KalturaStatsPluginConfig {
        return KalturaStatsPluginConfig(uiconfId: uiConf?.id ?? -1, partnerId: partnerId, entryId: mediaProvider?.assetId ?? "")
    }
    
    func getPhoenixAnalyticsConfig() -> PhoenixAnalyticsPluginConfig {
        return PhoenixAnalyticsPluginConfig(baseUrl: serverUrl, timerInterval: 30, ks: ks ?? "", partnerId: partnerId)
    }
}
