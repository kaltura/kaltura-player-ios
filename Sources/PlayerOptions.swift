//
//  PlayerOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 8/5/19.
//

import Foundation
import PlayKit

public class PlayerOptions: NSObject {
    
    /**
        Performs prepare on the player once the MediaEntry is set with a new value.
        
        **Default: true**
     
        If set too false and autoPlay is also set too false, the prepare will not be called automatically and will need to be called separately.
     */
    public var preload: Bool = true
    
    /**
        Performs play on the player once the media has been prepared.
     
        **Default: true**
     
        If set too false, the play will not be called automatically and will need to be called separately.
        The value of autoPlay effects preload; Refer to preload for more details.
     */
    public var autoPlay: Bool = true
    
    /**
        Sets up the player with the Plugins provided.
     
        The PluginConfig object is initialized with a dictionary of plugins.
                
            [String: Any]
     
        **Example:**
     
            let kavaPluginConfig = KavaPluginConfig(partnerId: 1091)
            let pluginConfig = PluginConfig(config: [KavaPlugin.pluginName: kavaPluginConfig])
     */
    public var pluginConfig: PluginConfig = PluginConfig(config: [:])
    
    public override init() {
        super.init()
    }
}
