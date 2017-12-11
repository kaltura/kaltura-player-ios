// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import SwiftyJSON

public class PlayerConfigError : PlayerConfigBaseObject {
    
    var code: String?
    var message: String?
    var args:[String: Any]?
    
    var codeKey = "code"
    var messageKey = "message"
    var argsKey = "args"
    
    required public init?(json: Any) {
        let jsonObject = JSON(json)
        self.code = jsonObject[codeKey].string
        self.message = jsonObject[messageKey].string
        if let args = jsonObject[argsKey].object as? [String:Any] {
           self.args = args
        }
    }
}
