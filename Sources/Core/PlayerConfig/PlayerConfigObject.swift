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
    public var autoPlay: Bool?
    public var preload: Bool?
    public var trackSelection: PKTrackSelectionSettings?
    
    static let idKey = "id"
    static let configKey = "config"
    static let playerKey = "player"
    static let playbackKey = "playback"
    static let pluginsKey = "plugins"
    static let autoPlayKey = "autoplay"
    static let preloadKey = "preload"
    static let audioLanguageKey = "audioLanguage"
    static let textLanguageKey = "textLanguage"
    
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
                    if let playback = player[PlayerConfigObject.playbackKey]?.dictionary {
                        if let autoPlay = playback[PlayerConfigObject.autoPlayKey]?.bool {
                            self.autoPlay = autoPlay
                        }
                        if playback[PlayerConfigObject.preloadKey]?.string == "auto" {
                            self.preload = true
                        }
                        
                        trackSelection = PKTrackSelectionSettings()
                        if let audioLang = playback[PlayerConfigObject.audioLanguageKey]?.string {
                            if audioLang == "auto" {
                                trackSelection?.audioSelectionMode = .auto
                            } else if audioLang != "" {
                                trackSelection?.audioSelectionMode = .selection
                                trackSelection?.audioSelectionLanguage = audioLang
                            }
                        }
                        if let textLang = playback[PlayerConfigObject.textLanguageKey]?.string {
                            if textLang == "off" {
                                trackSelection?.textSelectionMode = .off
                            } else if textLang == "auto" {
                                trackSelection?.audioSelectionMode = .auto
                            } else if textLang != "" {
                                trackSelection?.audioSelectionMode = .selection
                                trackSelection?.textSelectionLanguage = textLang
                            }
                        }
                    }
                }
            }
        }
    }
}
