//
//  UIConfService.swift
//  PlayKitOVP
//
//  Created by Vadim Kononov on 10/12/2017.
//

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
