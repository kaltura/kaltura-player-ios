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

public class OVPMediaOptions: MediaOptions {
    var entryId: String
    
    public init(entryId: String) {
        self.entryId = entryId
    }
}

public class KalturaOvpPlayer: KalturaPlayer<OVPMediaOptions> {
    let DEFAULT_SERVER_URL = "https://cdnapisec.kaltura.com"
    
    static var pluginsRegistered: Bool = false

    var provider: OVPMediaProvider?
    
    public static func create(with options: KalturaPlayerOptions?) -> KalturaOvpPlayer? {
        do {
            return try KalturaOvpPlayer(options: options)
        } catch let e {
            print("error on player initializing:", e.localizedDescription)
        }
        return nil
    }
    
    override public func loadMedia(mediaOptions: OVPMediaOptions, callback: ((PKMediaEntry?, Error?) -> Void)? = nil) {
        if let mediaKS = mediaOptions.ks {
            setKS(mediaKS)
        }
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
        return [KavaPlugin.pluginName : getKavaAnalyticsConfig()]
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
        player.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: getKavaAnalyticsConfig())
    }
    
    func getKavaAnalyticsConfig() -> KavaPluginConfig {
        return KavaPluginConfig(partnerId: Int(partnerId), ks: ks, playbackContext: nil, referrer: referrer, customVar1: nil, customVar2: nil, customVar3: nil)
    }
}
