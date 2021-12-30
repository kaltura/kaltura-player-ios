//
//  CountDownOptions.swift
//  KalturaPlayer
//
//  Created by Sergey Chausov on 23.11.2021.
//

import Foundation

@objc public class CountdownOptions: NSObject {
    
    public var timeToShow: TimeInterval = 20.0
    public var duration: TimeInterval = 10.0
    
    internal var startEventSent: (Bool, atTime: NSNumber?) = (false, nil)
    
    @objc public override init() {
        super.init()
    }
}
