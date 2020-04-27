//
//  KalturaBasicPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 1/9/20.
//

import Foundation
import PlayKit
import KalturaNetKit

public class KalturaBasicPlayer: KalturaPlayer {

    private var basicPlayerOptions: BasicPlayerOptions
    
    public init(basicPlayerOptions: BasicPlayerOptions) {
        self.basicPlayerOptions = basicPlayerOptions
        super.init(playerOptions: self.basicPlayerOptions)
        sendKavaImpression()
    }
    
    // MARK: - Private Methods
    
    private func sendKavaImpression() {
        guard let request: KalturaRequestBuilder = KalturaRequestBuilder(url: DEFAULT_KAVA_BASE_URL, service: nil, action: nil) else { return }
        
        request.set(method: .get)
        request.add(headerKey: "User-Agent", headerValue: PlayKitManager.userAgent)
        
        request.setParam(key: "service", value: "analytics")
        request.setParam(key: "action", value: "trackEvent")
        request.setParam(key: "eventType", value: "1")
        request.setParam(key: "eventIndex", value: "1")
        request.setParam(key: "partnerId", value: String(DEFAULT_KAVA_PARTNER_ID))
        request.setParam(key: "entryId", value: DEFAULT_KAVA_ENTRY_ID)
        request.setParam(key: "sessionId", value: self.sessionId)
        
        var referrer: String = "app://"
        if let appId = Bundle.main.bundleIdentifier {
            referrer += appId
        } else {
            PKLog.warning("The app's bundle identifier is not set")
            referrer += "bundleIdentifier_is_empty"
        }
        request.setParam(key: "referrer", value: referrer)
        
        request.setParam(key: "deliveryType", value: "url")
        //request.setParam(key: "playbackType", value: "vod")
        request.setParam(key: "clientVer", value: "\(PlayKitManager.clientTag)")
        request.setParam(key: "position", value: "0")
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setParam(key: "application", value: "\(bundleId)")
        }
        
        request.set { (response: Response) in
            PKLog.debug("Response:\nStatus Code: \(response.statusCode)\nError: \(response.error?.localizedDescription ?? "")\nData: \(response.data ?? "")")
        }
        PKLog.debug("Sending Kava Event, Impression (1)")
        USRExecutor.shared.send(request: request.build())
    }
    
    // MARK: - Public Methods
    
    public func setupMediaEntry(from id: String, contentUrl: URL, drmData: [DRMParams]? = nil, mediaFormat: PKMediaSource.MediaFormat = .unknown, mediaType: MediaType = .unknown) {
        let source = PKMediaSource(id, contentUrl: contentUrl, drmData: drmData, mediaFormat: mediaFormat)
        // setup media entry
        let mediaEntry = PKMediaEntry(id, sources: [source], duration: -1)
        mediaEntry.mediaType = mediaType

        self.mediaEntry = mediaEntry
    }
    
    public func updatePlayerOptions(_ playerOptions: BasicPlayerOptions) {
        self.basicPlayerOptions = playerOptions
        super.updatePlayerOptions(playerOptions)
    }
}
