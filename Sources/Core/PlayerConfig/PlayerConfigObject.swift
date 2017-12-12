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

