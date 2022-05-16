//
//  MediaOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/5/20.
//

import Foundation
import PlayKit

@objc public class MediaOptions: NSObject {
    
    /**
        Sets the media with a start time if set with a value.
     
        If not set, the media will start from the default value per media type:
        * In case of vod, 0.
        * In case of live, the live edge.
     */
    @objc public var startTime: TimeInterval = .nan
    
    @objc public var ks: String?
    
    @discardableResult
    @nonobjc public func set(ks: String?) -> Self {
        self.ks = ks
        return self
    }
    
    @discardableResult
    @nonobjc public func set(startTime: TimeInterval) -> Self {
        self.startTime = startTime
        return self
    }
    
    @objc public var externalSubtitles: [PKExternalSubtitle]?
    
    @nonobjc public func set(externalSubtitles: [PKExternalSubtitle]) -> Self {
        self.externalSubtitles = externalSubtitles
        return self
    }
    
}
