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
import KalturaNetKit
import PlayKit
import PlayKitOVP
import SwiftyJSON

public enum KalturaOVpAnonymousSessionError: PKError {
    case unableToParseData(data: Any)
    
    public static let domain = "com.kaltura.playkit.ovp.error.KalturaOVpAnonymousSession"
    
    public var userInfo: [String : Any] {
        return [:]
    }
    
    public var code: Int {
        return 0
    }
    
    public var errorDescription: String {
        switch self {
        case .unableToParseData(let data):
            return "Unable to parse object (data: \(String(describing: data)))"
        }
    }
}

@objc public class KalturaOVpAnonymousSession : NSObject {
    @objc public class func start(baseUrl: String, partnerId: Int, completion: @escaping (String?, Error?) -> Void) {
        if let b = OVPSessionService.startWidgetSession(baseURL: baseUrl + "/api_v3", partnerId: partnerId) {
            b.setOVPBasicParams()
            b.set(completion: { (response) in
                if let error = response.error {
                    completion(nil, error)
                } else {
                    guard let responseData = response.data else { return }
                    if let widgetSession = OVPResponseParser.parse(data: responseData) as? OVPStartWidgetSessionResponse {
                        completion(widgetSession.ks, nil)
                    } else {
                        completion(nil, KalturaOVpAnonymousSessionError.unableToParseData(data: responseData).asNSError)
                    }
                }
            })
            USRExecutor.shared.send(request: b.build())
        }
    }
}

