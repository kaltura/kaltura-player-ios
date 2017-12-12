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
import KalturaNetKit

public class UIConfService {
    public static func get(baseUrl: String, uiconfId: Int, partnerId: Int? = nil, ks: String? = nil) -> KalturaRequestBuilder? {
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseUrl, service: "uiconf", action: "get") {
             request
                .setParam(key: "id", value: "\(uiconfId)")
                .setParam(key: "format", value: "1")
                //.set(method: .get)
            if let partnerId = partnerId {
                request.setParam(key: "partnerId", value: "\(partnerId)")
            }
            if let ks = ks {
                request.setParam(key: "ks", value: ks)
            }
            return request
        } else {
            return nil
        }
    }
}
