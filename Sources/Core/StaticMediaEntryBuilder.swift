//
//  StaticMediaEntryBuilder.swift
//  KalturaPlayer
//
//  Created by Vadik on 22/11/2017.
//

import Foundation
import PlayKit

class StaticMediaEntryBuilder {
    public static func provider(partnerId: Int64, ks: String?, serverUrl: String, entryId: String, format: PKMediaSource.MediaFormat) -> MediaEntryProvider {
        let entry = buildEntry(serverUrl: serverUrl, partnerId: partnerId, entryId: entryId, ks: ks, format: format)
        return StaticMediaEntryProvider(mediaEntry: entry)
    }
    
    public static func buildEntry(serverUrl: String, partnerId: Int64, entryId: String, ks: String?, format: PKMediaSource.MediaFormat) -> PKMediaEntry {
        let formatName: String = format == .hls ? "applehttp" : "url"
        var url = URL(string: serverUrl)?
            .appendingPathComponent("p").appendingPathComponent("\(partnerId)")
            .appendingPathComponent("entryId").appendingPathComponent(entryId)
            .appendingPathComponent("format").appendingPathComponent(formatName)
            .appendingPathComponent("protocol").appendingPathComponent("")
        
        if let _ = ks {
            url = url?.appendingPathComponent("ks").appendingPathComponent(ks!)
        }
        
        url = url?.appendingPathComponent("a." + format.fileExtension)
        
        return PKMediaEntry(entryId, sources: [PKMediaSource(entryId, contentUrl: url, mimeType: nil, drmData: nil, mediaFormat: format)])
    }
}

class StaticMediaEntryProvider: MediaEntryProvider {
    var mediaEntry: PKMediaEntry
    
    init(mediaEntry: PKMediaEntry) {
        self.mediaEntry = mediaEntry
    }
    
    func loadMedia(callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        callback(mediaEntry, nil)
    }
    
    func cancel() {
        
    }
}
