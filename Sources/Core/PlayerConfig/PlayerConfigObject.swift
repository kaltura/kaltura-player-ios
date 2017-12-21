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
    static let pluginsKey = "plugins"

    required public init?(json: Any) {
        let jsonObject = JSON(json)
        
        guard let id = jsonObject[PlayerConfigObject.idKey].int else { return nil }
        
        self.id = id
        
        if let plugins = jsonObject[PlayerConfigObject.pluginsKey].array {
            var config = [String : JSON]()
            for json in plugins {
                if let dictionary = json.dictionary, let pluginName = dictionary["pluginName"]?.string {
                    config[pluginName] = dictionary["params"]
                }
            }
            pluginConfig = PluginConfig(config: config)
        }
    }
}
