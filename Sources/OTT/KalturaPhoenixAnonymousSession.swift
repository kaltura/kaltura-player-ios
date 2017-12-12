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
import PlayKitOTT

public enum KalturaPhoenixAnonymousSessionError: PKError {
    case unableToParseData(data: Any)

    public static let domain = "com.kaltura.playkit.ott.error.KalturaPhoenixAnonymousSession"
    
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

@objc public class KalturaPhoenixAnonymousSession : NSObject {
    @objc public class func start(baseUrl: String, partnerId: Int, completion: @escaping (String?, Error?) -> Void) {
        if let b = OttUserService.anonymousLogin(baseURL: baseUrl, partnerId: partnerId) {
            b.set(completion: { (response) in
                if let error = response.error {
                   completion(nil, error)
                } else {
                    guard let responseData = response.data else { return }
                    do {
                        let loginSession = try OTTResponseParser.parse(data: responseData) as? OTTLoginSession
                        completion(loginSession?.ks, nil)
                    } catch {
                        completion(nil, KalturaPhoenixAnonymousSessionError.unableToParseData(data: responseData).asNSError)
                    }
                }
            })
            USRExecutor.shared.send(request: b.build())
        }
    }
}
