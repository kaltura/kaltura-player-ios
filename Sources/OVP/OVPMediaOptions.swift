//
//  OVPMediaOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 8/2/20.
//

import Foundation
import PlayKitProviders
import KalturaPlayer

@objc public class OVPMediaOptions: MediaOptions {
    
    @objc public var entryId: String?
    @objc public var referenceId: String?
    @objc public var uiconfId: NSNumber?
    
    @objc public var redirectFromEntryId: Bool = true
    
    @discardableResult
    @nonobjc public func set(entryId: String?) -> Self {
        self.entryId = entryId
        return self
    }
    
    @discardableResult
    @nonobjc public func set(referenceId: String?) -> Self {
        self.referenceId = referenceId
        return self
    }
    
    @discardableResult
    @nonobjc public func set(redirectFromEntryId: Bool) -> Self {
        self.redirectFromEntryId = redirectFromEntryId
        return self
    }
    
    internal func mediaProvider() -> OVPMediaProvider {
        let ovpMediaProvider = OVPMediaProvider()
        ovpMediaProvider.set(entryId: entryId)
        ovpMediaProvider.set(referenceId: referenceId)
        ovpMediaProvider.set(uiconfId: uiconfId)
        ovpMediaProvider.set(redirectFromEntryId: redirectFromEntryId)
        
        return ovpMediaProvider
    }
    
}
