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
        if let data = data, let objectType = classByJsonObject(json: data) {
            return objectType.init(json: data)
        } else {
            return nil
        }
    }
    
    static let classNameKey = "objectType"
    
    static func classByJsonObject(json: Any?) -> PlayerConfigBaseObject.Type? {
        
        guard let js = json else {
            return nil
        }
        
        let jsonObject = JSON(js)
        let className = jsonObject[classNameKey].string
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
