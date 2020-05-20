//
//  KalturaOTTPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 4/5/20.
//

import Foundation
import PlayKit
import PlayKitProviders
import PlayKitKava

public class KalturaOTTPlayer: KalturaPlayer {

    private var ottPlayerOptions: OTTPlayerOptions
    var ottMediaOptions: OTTMediaOptions? {
        didSet {
            mediaOptions = ottMediaOptions
        }
    }
    
    private var sessionProvider: SimpleSessionProvider
    private let PhoenixAnalyticsTimerInterval = 30.0
    
    /**
       A Kaltura Player for OTT Clients.
    
       Create the player options, `OTTPlayerOptions`, and pass it to the `KalturaOTTPlayer`.
       Check the `OTTPlayerOptions` for more info regarding the available options and defaults.
       Create a `KalturaPlayerView` in the code or in the xib and pass it to the `KalturaOTTPlayer`.
       
       **Example:**
    
           let ottPlayerOptions = OTTPlayerOptions()
           let kalturaOTTPlayer = KalturaOTTPlayer(options: ottPlayerOptions)
           kalturaOTTPlayer.view = kalturaPlayerView
    
       * Parameters:
           * options: The player's initialize options.
    */
    public init(options: OTTPlayerOptions) {
        ottPlayerOptions = options
        
        sessionProvider = SimpleSessionProvider(serverURL: KalturaOTTPlayerManager.shared.serverURL, partnerId: KalturaOTTPlayerManager.shared.partnerId, ks: ottPlayerOptions.ks)
        
        if let ovpPartnerId = KalturaOTTPlayerManager.shared.cachedDMSConfigData?.ovpPartnerId {
            options.pluginConfig.config[KavaPlugin.pluginName] = KavaPluginConfig(partnerId: Int(ovpPartnerId))
        }
        
        // Have to set the PhoenixAnalyticsPlugin even if the player KS is empty, cause an update is performed upon loadMedia without validating if the plugin was set. The request will not be sent upon an empty KS.
        let phoenixAnalyticsPluginConfig = PhoenixAnalyticsPluginConfig(baseUrl: KalturaOTTPlayerManager.shared.serverURL,
                                                                        timerInterval: PhoenixAnalyticsTimerInterval,
                                                                        ks: options.ks ?? "",
                                                                        partnerId: Int(KalturaOTTPlayerManager.shared.partnerId))
        
        options.pluginConfig.config[PhoenixAnalyticsPlugin.pluginName] = phoenixAnalyticsPluginConfig
        
        super.init(playerOptions: ottPlayerOptions)
    }
    
    // MARK: - Private Methods
    
    func updateKavaPlugin(ovpPartnerId: Int64, ovpEntryId: String, mediaOptions: OTTMediaOptions) {
        
        let ks = mediaOptions.ks?.isEmpty == false ? mediaOptions.ks : ottPlayerOptions.ks
        
        // TODO: Add a function to the Utils
        var referrer = ottPlayerOptions.referrer ?? ""
        if referrer.isEmpty == true {
            referrer = "app://"
            if let appId = Bundle.main.bundleIdentifier {
                referrer += appId
            } else {
                PKLog.warning("The app's bundle identifier is not set")
                referrer += "bundleIdentifier_is_empty"
            }
        }
            
        let clientAppVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "BundleVersionMissing"
        let kavaPluginConfig = KavaPluginConfig(partnerId: Int(ovpPartnerId),
                                                entryId: ovpEntryId,
                                                ks: ks,
                                                userId: nil, // TODO: userId is missing to be sent to kava
                                                playbackContext: mediaOptions.playbackContextType.description,
                                                referrer: referrer,
                                                applicationVersion: clientAppVersion,
                                                playlistId: nil, // We currently don't have in iOS.
                                                customVar1: nil, // TODO: customVar's are missing to be sent to kava
                                                customVar2: nil,
                                                customVar3: nil)
        
        if var analyticsUrl = KalturaOTTPlayerManager.shared.cachedDMSConfigData?.analyticsUrl {
            // TODO: Add a function to the Utils
            if analyticsUrl.hasSuffix("/api_v3/index.php") {
                // Do nothing, the url is correct
            } else if analyticsUrl.hasSuffix("/api_v3/") {
                analyticsUrl += "index.php"
            } else if analyticsUrl.hasSuffix("/api_v3") {
                analyticsUrl += "/index.php"
            } else if analyticsUrl.hasSuffix("/") {
                analyticsUrl += "api_v3/index.php"
            } else {
                analyticsUrl += "/api_v3/index.php"
            }
            
            kavaPluginConfig.baseUrl = analyticsUrl
        }
        
        self.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: kavaPluginConfig)
    }
    
    func updatePhoenixAnalyticsPlugin() {
        var ks = ""
        if let mediaKS = ottMediaOptions?.ks {
            ks = mediaKS
        } else if let playerKS = ottPlayerOptions.ks {
            ks = playerKS
        }
        
        let phoenixAnalyticsPluginConfig = PhoenixAnalyticsPluginConfig(baseUrl: KalturaOTTPlayerManager.shared.serverURL,
                                                                  timerInterval: PhoenixAnalyticsTimerInterval,
                                                                  ks: ks,
                                                                  partnerId: Int(KalturaOTTPlayerManager.shared.partnerId))
        
        self.updatePluginConfig(pluginName: PhoenixAnalyticsPlugin.pluginName, config: phoenixAnalyticsPluginConfig)
    }
    
    // MARK: - Public Methods
    
    /**
        Loads the media with the provided media options.
        
        Will set the MediaEntry and automatically prepare the media in case the `PlayerOptions` autoPlay or preload is set to true, which is the default value.
        
        In case an error occurred retrieving the media from the provider, the error will return in the callback function.
        
        * Parameters:
            * options: The media options. See `OTTMediaOptions` for more details.
            * callback: A callback function to observe if an error has occurred, or in case prepare needs to be called manually.
     */
    public func loadMedia(options: OTTMediaOptions, callback: @escaping (Error?) -> Void) {
        ottMediaOptions = options
        
        if options.ks?.isEmpty == false {
            sessionProvider.ks = options.ks
        } else {
            sessionProvider.ks = ottPlayerOptions.ks
        }
        
        let phoenixMediaProvider = PhoenixMediaProvider()
        phoenixMediaProvider.set(assetId: options.assetId)
        phoenixMediaProvider.set(type: options.assetType)
        phoenixMediaProvider.set(refType: options.assetReferenceType)
        phoenixMediaProvider.set(playbackContextType: options.playbackContextType)
        phoenixMediaProvider.set(formats: options.formats)
        phoenixMediaProvider.set(fileIds: options.fileIds)
        phoenixMediaProvider.set(networkProtocol: options.networkProtocol)
        phoenixMediaProvider.set(referrer: ottPlayerOptions.referrer)
        phoenixMediaProvider.set(sessionProvider: sessionProvider)
        
        phoenixMediaProvider.loadMedia { [weak self] (pkMediaEntry, error) in
            guard let self = self else { return }
            
            guard let mediaEntry = pkMediaEntry else {
                if let error = error {
                    switch error {
                    case let nsError as NSError:
                        callback(KalturaPlayerError.mediaProviderError(code: String(nsError.code), message: nsError.description))
                    case let pkError as PKError:
                        callback(KalturaPlayerError.mediaProviderError(code: String(pkError.code), message: pkError.errorDescription))
                    default:
                        callback(KalturaPlayerError.mediaProviderError(code: "LoadMediaError", message: error.localizedDescription))
                    }
                } else {
                    callback(KalturaPlayerError.invalidPKMediaEntry)
                }
                
                return
            }
            
            guard let ovpPartnerId = KalturaOTTPlayerManager.shared.cachedDMSConfigData?.ovpPartnerId else {
                callback(KalturaPlayerError.dmsConfigurationMissing)
                return
            }
            
            let ovpEntryId = mediaEntry.metadata?["entryId"] ?? options.assetId ?? ""
            self.updateKavaPlugin(ovpPartnerId: ovpPartnerId, ovpEntryId: ovpEntryId, mediaOptions: options)
            self.updatePhoenixAnalyticsPlugin()
            
            self.mediaEntry = mediaEntry
            callback(nil)
        }
    }
    
    /**
        Update the player's initialized options.
     
        * Parameters:
            * playerOptions: A new player options.
     */
    public func updatePlayerOptions(_ playerOptions: OTTPlayerOptions) {
        self.ottPlayerOptions = playerOptions
        super.updatePlayerOptions(playerOptions)
    }
}
