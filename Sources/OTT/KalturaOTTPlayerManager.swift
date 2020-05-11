//
//  KalturaOTTPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/11/20.
//

import Foundation

public class KalturaOTTPlayerManager: KalturaPlayerManager {
    
    public static let shared = KalturaOTTPlayerManager()
    
    private(set) var partnerId: Int64 = 0
    private(set) var serverURL: String = ""
    
    private override init() {
        super.init()
    }
    
    public static func setup(partnerId: Int64, serverURL: String) {
        KalturaOTTPlayerManager.shared.partnerId = partnerId
        KalturaOTTPlayerManager.shared.serverURL = serverURL
    }
    
}
