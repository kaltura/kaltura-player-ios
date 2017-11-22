//
//  PlayManifestRequestAdapter.swift
//  KalturaPlayer
//
//  Created by Vadik on 22/11/2017.
//

import Foundation
import PlayKit

class PlayManifestRequestAdapter: PKRequestParamsAdapter {
    var playSessionId: String!
    var referrer: String
    
    static func install(player: Player, referrer: String) {
        let adapter = PlayManifestRequestAdapter(player: player, referrer: referrer)
        player.settings.contentRequestAdapter = adapter
    }
    
    init(player: Player, referrer: String) {
        self.referrer = referrer
        updateRequestAdapter(with: player)
    }
    
    func updateRequestAdapter(with player: Player) {
        playSessionId = player.sessionId
    }
    
    func adapt(requestParams: PKRequestParams) -> PKRequestParams {
        if requestParams.url.path.contains("/playManifest/") {
            if var components = URLComponents(string: requestParams.url.absoluteString) {
                var queryItems = [URLQueryItem]()
                
                queryItems.append(URLQueryItem(name: "clientTag", value: PlayKitManager.clientTag))
                queryItems.append(URLQueryItem(name: "referrer", value: referrer.data(using: .utf8)!.base64EncodedString()))
                queryItems.append(URLQueryItem(name: "playSessionId", value: playSessionId))
                
                if requestParams.url.lastPathComponent.hasSuffix(".wvm") {
                    queryItems.append(URLQueryItem(name: "name", value: requestParams.url.lastPathComponent))
                }
                
                components.queryItems = queryItems
                
                if let newUrl = components.url {
                    return PKRequestParams(url: newUrl, headers: requestParams.headers)
                }
            }
        }
        
        return requestParams
    }
    
    
}
