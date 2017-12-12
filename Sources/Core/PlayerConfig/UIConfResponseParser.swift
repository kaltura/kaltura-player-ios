//
//  OVPResponseParser.swift
//  PlayKitOVP
//
//  Created by Vadim Kononov on 10/12/2017.
//

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
