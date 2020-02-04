

import Foundation
import PlayKit
import PlayKitKava

class KalturaPlayer: NSObject {
    
    var player: Player!
    
    let DEFAULT_KAVA_PARTNER_ID: Int = 2504201
    let DEFAULT_KAVA_ENTRY_ID: String = "1_3bwzbc9o"
    
    init(pluginConfig: PluginConfig?) {
        super.init()
        
        addDefaultPlugins(to: pluginConfig)
        player = PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig)
    }
    
    func setPlayerView(_ playerView: PlayerView) {
        player.view = playerView
    }
    
    func prepare(mediaConfig: MediaConfig) {
        player.prepare(mediaConfig)
    }
    
    private func addDefaultPlugins(to pluginConfig: PluginConfig?) {
        if pluginConfig?.config[KavaPlugin.pluginName] == nil {
            pluginConfig?.config[KavaPlugin.pluginName] = KavaPluginConfig(partnerId: DEFAULT_KAVA_PARTNER_ID, entryId: DEFAULT_KAVA_ENTRY_ID)
        }
    }
}
