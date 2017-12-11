//
//  UIConfService.swift
//  PlayKitOVP
//
//  Created by Vadim Kononov on 10/12/2017.
//

import Foundation
import SwiftyJSON

public class PlayerConfigObject : PlayerConfigBaseObject {
    var id: Int
    
    let idKey = "id"
    
    required public init?(json: Any) {
        
        let jsonObject = JSON(json)
        
        guard let id = jsonObject[idKey].int else {
            return nil
        }
        
        self.id = id
    }
}

