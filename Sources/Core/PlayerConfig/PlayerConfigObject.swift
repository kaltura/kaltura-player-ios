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
import SwiftyJSON
import PlayKit

public class PlayerConfigObject : PlayerConfigBaseObject {
    var id: Int
    public var pluginConfig: PluginConfig?
    
    static let idKey = "id"
    static let configKey = "config"
    static let playerKey = "player"
    static let pluginsKey = "plugins"

    required public init?(json: Any) {
        let jsonObject = JSON(json)
        
        guard let id = jsonObject[PlayerConfigObject.idKey].int else { return nil }
        
        self.id = id
        if let confStr = jsonObject[PlayerConfigObject.configKey].string {
            if let data = confStr.data(using: .utf8) {
                let fixedJsonObject = JSON.init(data: data)
                if let player = fixedJsonObject[PlayerConfigObject.playerKey].dictionary {
                    if let plugins = player[PlayerConfigObject.pluginsKey]?.dictionary {
                        pluginConfig = PluginConfig(config: plugins)
                    }
                }
            }
        }
    }
}
