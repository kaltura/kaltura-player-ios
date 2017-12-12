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

public class UIConfResponseParser: NSObject {
    public static func parse(data: Any?) -> PlayerConfigBaseObject? {
        if let data = data, let objectType = classByJsonObject(data) {
            return objectType.init(json: data)
        } else {
            return nil
        }
    }
    
    static let classNameKey = "objectType"
    
    static func classByJsonObject(_ jsonObject: Any?) -> PlayerConfigBaseObject.Type? {
        
        guard let jsObj = jsonObject else {
            return nil
        }
        
        let json = JSON(jsObj)
        let className = json[classNameKey].string
        if let name = className{
            switch name {
            case "KalturaUiConf":
                return PlayerConfigObject.self
            case "KalturaAPIException":
                return PlayerConfigError.self
            default:
                return nil
            }
        }
        return nil
        
    }
}
