//
//  OTTPlayerOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 4/5/20.
//

import Foundation

public class OTTPlayerOptions: PlayerOptions {
    
    var ks: String?
    var referrer: String?
    
    public init(ks: String? = nil, referrer: String? = nil) {
        self.ks = ks
        self.referrer = referrer
        
        super.init()
    }
}
