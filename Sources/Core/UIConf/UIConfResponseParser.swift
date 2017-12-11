//
//  OVPResponseParser.swift
//  PlayKitOVP
//
//  Created by Vadim Kononov on 10/12/2017.
//

import Foundation
import SwiftyJSON

public class UIConfResponseParser: NSObject {
    public static func parse(data: Any?) -> UIConfBaseObject? {
        if let data = data, let objectType = classByJsonObject(json: data) {
            return objectType.init(json: data)
        } else {
            return nil
        }
    }
    
    static let classNameKey = "objectType"
    
    static func classByJsonObject(json: Any?) -> UIConfBaseObject.Type? {
        
        guard let js = json else {
            return nil
        }
        
        let jsonObject = JSON(js)
        let className = jsonObject[classNameKey].string
        if let name = className{
            switch name {
            case "KalturaUiConf":
                return UIConfObject.self
            case "KalturaAPIException":
                return UIConfError.self
            default:
                return nil
            }
        }
        return nil
        
    }
}
