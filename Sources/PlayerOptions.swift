//
//  PlayerOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 8/5/19.
//

import Foundation
import PlayKit

public class PlayerOptions: NSObject {
    
    public var pluginConfigs: PluginConfig = PluginConfig(config: [:])
    
    public override init() {
        super.init()
    }
}
