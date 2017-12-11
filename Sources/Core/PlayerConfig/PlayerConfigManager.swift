//
//  UIConfManager.swift
//  KalturaPlayer
//
//  Created by Vadim Kononov on 10/12/2017.
//

import Foundation
import KalturaNetKit
import SwiftyJSON

public class PlayerConfigManager {
    
    public static let shared = PlayerConfigManager()
    
    private var data: [Int : PlayerConfigObject] = [:]
    
    public func retrieve(by id: Int, baseUrl: String, partnerId: Int64? = nil, ks: String? = nil, completion: @escaping (PlayerConfigObject?, PlayerConfigError?) -> Void) {
        if let conf = data[id] {
            completion(conf, nil)
        } else {
            if let request = UIConfService.get(baseUrl: baseUrl + "/api_v3", uiconfId: id, partnerId: partnerId, ks: ks) {
                request.setOVPBasicParams()
                request.set(completion: { (response) in
                    if let data = response.data {
                        let uiconf = UIConfResponseParser.parse(data: data)
                        if let error = uiconf as? PlayerConfigError {
                            completion(nil, error)
                        } else if let uiConfObj = uiconf as? PlayerConfigObject {
                            self.data[id] = uiConfObj
                            completion(uiConfObj, nil)
                        }
                    } else {
                        completion(nil, nil)
                    }
                })
                USRExecutor.shared.send(request: request.build())
            }
        }
    }
}
