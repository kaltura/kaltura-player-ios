//
//  BasicPlayerOptions.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 1/9/20.
//

import Foundation
import PlayKit

class BasicPlayerOptions: PlayerOptions {
    
    var id: String
    var contentUrl: URL
    var drmData: [DRMParams]?
    var mediaFormat: PKMediaSource.MediaFormat = .unknown
    
    init(id: String, contentUrl: URL) {
        self.id = id
        self.contentUrl = contentUrl
    }
}
