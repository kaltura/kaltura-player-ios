//
//  DRMStatus.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/14/20.
//

import PlayKit

/// The DRM Status object includes the expiration date and a validation function.
@objc public class DRMStatus: NSObject {

    private let fpsExpirationInfo: FPSExpirationInfo
    
    /// The DRM expiration date.
    @objc public var expirationDate: Date {
        return fpsExpirationInfo.expirationDate
    }

    internal init(_ fpsExpirationInfo: FPSExpirationInfo) {
        self.fpsExpirationInfo = fpsExpirationInfo
    }
    
    /**
        Checks the DRM expiration status.
     
        * Returns: In case the expiration date has not passed, true is returned; otherwise returns false.
     */
    @objc public func isValid() -> Bool {
        return self.fpsExpirationInfo.isValid()
    }
}
