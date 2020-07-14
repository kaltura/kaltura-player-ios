//
//  DRMStatus.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/14/20.
//

import PlayKit

@objc public class DRMStatus: NSObject {

    private let fpsExpirationInfo: FPSExpirationInfo
    
    @objc public var expirationDate: Date {
        return fpsExpirationInfo.expirationDate
    }

    internal init(_ fpsExpirationInfo: FPSExpirationInfo) {
        self.fpsExpirationInfo = fpsExpirationInfo
    }
    
    @objc public func isValid() -> Bool {
        return self.fpsExpirationInfo.isValid()
    }
}
