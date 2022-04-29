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

@objc public class KalturaOTTPlayer: KalturaPlayer {

    private var ottMediaOptions: OTTMediaOptions? {
        didSet {
            mediaOptions = ottMediaOptions
        }
    }
    
    private var sessionProvider: SimpleSessionProvider
    private let PhoenixAnalyticsTimerInterval = 30.0
    
    /**
        Set up the Kaltura OTT Player with the Partner ID and the Server URL.

        The setup will request the DMS Configuration required for the player, register the `KavaPlugin` and the `PhoenixAnalyticsPlugin`.
     
        In addition the setup will register any Kaltura's plugin which will be added in the pod file.
        Supporting `PlayKit_IMA` and `PlayKitYoubora` pods.

        * Parameters:
            * partnerId: The OTT Partner ID.
            * serverURL: The OTT Server URL.
            * referrer:  A custom referrer. Default value, the application bundle id.
    */
    @objc public static func setup(partnerId: Int64, serverURL: String, referrer: String? = nil) {
        KalturaOTTPlayerManager.shared.partnerId = partnerId
        KalturaOTTPlayerManager.shared.serverURL = serverURL
        if let referrer = referrer, !referrer.isEmpty {
            KalturaOTTPlayerManager.shared.referrer = referrer
        }
        
        KalturaOTTPlayerManager.shared.fetchConfiguration()
        
        PlayKitManager.shared.registerPlugin(KavaPlugin.self)
        PlayKitManager.shared.registerPlugin(PhoenixAnalyticsPlugin.self)
    }
    
    /**
       A Kaltura Player for OTT Clients. Kava and Phoenix Analytics embeded.
    
       Create the player options, `PlayerOptions`, and pass it to the `KalturaOTTPlayer`.
       Check the `PlayerOptions` for more info regarding the available options and defaults.
       Create a `KalturaPlayerView` in the code or in the xib and pass it to the `KalturaOTTPlayer`.
       
       **Example:**
    
           let playerOptions = PlayerOptions()
           let kalturaOTTPlayer = KalturaOTTPlayer(options: playerOptions)
           kalturaOTTPlayer.view = kalturaPlayerView
    
       * Parameters:
           * options: The player's initialize options.
    */
    @objc public init(options: PlayerOptions) {
        sessionProvider = SimpleSessionProvider(serverURL: KalturaOTTPlayerManager.shared.serverURL,
                                                partnerId: KalturaOTTPlayerManager.shared.partnerId,
                                                ks: options.ks)
        
        if (options.pluginConfig.config[KavaPlugin.pluginName] == nil) {
            // In case the DMS Configuration won't be available yet, setting the KavaPluginConfig with a placeholder cause an update is performed upon loadMedia without validating if the plugin was set.
            let partnerId = KalturaOTTPlayerManager.shared.cachedConfigData?.ovpPartnerId ?? KalturaOTTPlayerManager.shared.partnerId
            options.pluginConfig.config[KavaPlugin.pluginName] = KavaPluginConfig(partnerId: Int(partnerId))
        }
        
        if (options.pluginConfig.config[PhoenixAnalyticsPlugin.pluginName] == nil) {
            // Have to set the PhoenixAnalyticsPlugin even if the player KS is empty, cause an update is performed upon loadMedia without validating if the plugin was set. The request will not be sent upon an empty KS.
            let phoenixAnalyticsPluginConfig = PhoenixAnalyticsPluginConfig(baseUrl: KalturaOTTPlayerManager.shared.serverURL,
                                                                            timerInterval: PhoenixAnalyticsTimerInterval,
                                                                            ks: options.ks ?? "",
                                                                            partnerId: Int(KalturaOTTPlayerManager.shared.partnerId))
            
            options.pluginConfig.config[PhoenixAnalyticsPlugin.pluginName] = phoenixAnalyticsPluginConfig
        }
        
        super.init(playerOptions: options)
    }
    
    // MARK: - Private Methods
    
    internal override func setMediaAndUpdatePlugins(mediaEntry: PKMediaEntry,
                                                    mediaOptions: MediaOptions?,
                                                    pluginConfig: PluginConfig?,
                                                    callback: @escaping (_ error: NSError?) -> Void) {
        
        if let options = mediaOptions as? OTTMediaOptions {
            ottMediaOptions = options
        }
        
        // The DMS Configuration is needed in order to continue.
        guard let ovpPartnerId = KalturaOTTPlayerManager.shared.cachedConfigData?.ovpPartnerId else {
            callback(KalturaPlayerError.configurationMissing.asNSError)
            return
        }
        
        var ovpEntryId = ""
        
        if let entryId = mediaEntry.metadata?["entryId"] {
            ovpEntryId = entryId
        } else if let options = mediaOptions as? OTTMediaOptions, let entryId = options.assetId {
            ovpEntryId = entryId
        }
        
        if !self.isPluginLoaded(pluginName: KavaPlugin.pluginName) {
            // Update KavaPlugin if it was not set explicitly for specific Media.
            self.updateKavaPlugin(ovpPartnerId: ovpPartnerId, ovpEntryId: ovpEntryId, mediaOptions: mediaOptions as? OTTMediaOptions)
        }
        
        if !self.isPluginLoaded(pluginName: PhoenixAnalyticsPlugin.pluginName) {
            // Update PhoenixAnalyticsPlugin if it was not set explicitly for specific Media.
            self.updatePhoenixAnalyticsPlugin()
        }
        
        // If any custom plugin config has been sent use it instead.
        if let pluginConfig = pluginConfig {
            pluginConfig.config.forEach { (name, config) in
                updatePluginConfig(pluginName: name, config: config)
            }
        }
        
        self.updateMediaEntryWithLoadedInterceptors(mediaEntry) {
            callback(nil)
        }
    }
    
    
    func updateKavaPlugin(ovpPartnerId: Int64, ovpEntryId: String, mediaOptions: OTTMediaOptions?) {
        let kavaPluginConfig = KavaHelper.getPluginConfig(ovpPartnerId: ovpPartnerId,
                                                          ovpEntryId: ovpEntryId,
                                                          ks: playerOptions.ks,
                                                          referrer: KalturaOTTPlayerManager.shared.referrer,
                                                          playbackContext: mediaOptions?.playbackContextType.description,
                                                          analyticsUrl: KalturaOTTPlayerManager.shared.cachedConfigData?.analyticsUrl,
                                                          playlistId: nil)
        
        self.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: kavaPluginConfig)
    }
    
    func updatePhoenixAnalyticsPlugin() {
        let phoenixAnalyticsPluginConfig = PhoenixAnalyticsPluginConfig(baseUrl: KalturaOTTPlayerManager.shared.serverURL,
                                                                        timerInterval: PhoenixAnalyticsTimerInterval,
                                                                        ks: playerOptions.ks ?? "",
                                                                        partnerId: Int(KalturaOTTPlayerManager.shared.partnerId),
                                                                        disableMediaHit: ottMediaOptions?.disableMediaHit ?? false,
                                                                        disableMediaMark: ottMediaOptions?.disableMediaMark ?? false,
                                                                        isExperimentalLiveMediaHit: ottMediaOptions?.isExperimentalLiveMediaHit ?? false)
        
        self.updatePluginConfig(pluginName: PhoenixAnalyticsPlugin.pluginName, config: phoenixAnalyticsPluginConfig)
    }
    
    // MARK: - Public Methods
    
    /**
        Loads the media with the provided media options.
        
        Will set the MediaEntry and automatically prepare the media in case the `PlayerOptions` autoPlay or preload is set to true, which is the default value. Call prepare manually in case the autoPlay and preload was set to false.
        
        In case an error occurred retrieving the media from the provider, the error will return in the callback function.
     
        Kava and Phoenix Analytics is updated automatically.
        
        * Parameters:
            * options: The media options. See `OTTMediaOptions` for more details.
            * callback:
            * error: A `KalturaPlayerError` in case of an issue. See `KalturaPlayerError` for more details.
     */
    @objc public func loadMedia(options: OTTMediaOptions, callback: @escaping (_ error: NSError?) -> Void) {
        self.loadMedia(options: options) { [weak self] (pkMediaEntry: PKMediaEntry?, error: NSError?) in
            guard let self = self else { return }
            
            guard let mediaEntry = pkMediaEntry else {
                if let error = error {
                    var code = String(error.code)
                    if let serverErrorCode = error.userInfo[ProviderServerErrorCodeKey] as? String, !serverErrorCode.isEmpty {
                        code = serverErrorCode
                    }
                    var message = error.description
                    if let serverErrorMessage = error.userInfo[ProviderServerErrorMessageKey] as? String, !serverErrorMessage.isEmpty {
                        message = serverErrorMessage
                    }
                    callback(KalturaPlayerError.mediaProviderError(code: code, message: message).asNSError)
                } else {
                    callback(KalturaPlayerError.invalidPKMediaEntry.asNSError)
                }
                
                return
            }
            
            self.setMediaAndUpdatePlugins(mediaEntry: mediaEntry, mediaOptions: options, pluginConfig: nil, callback: callback)
        }
    }
    
}

// MARK: - Bypass Config Fetching

extension KalturaOTTPlayer {
    
    /**
        Call this function in case the BE environment has not been set up yet with the config data.
     
        This function needs to be called before the `setup` function.
     
        * Parameters:
            * partnerId:     The OTT Partner ID.
            * ovpPartnerId:  The OVP Partner ID.
            * analyticsUrl:  The Analytics Url used for Kava.
            * ovpServiceUrl: The OVP Service Url.
            * uiConfId:      The UI Conf ID.
    */
    @objc public static func bypassConfigFetching(partnerId: Int64, ovpPartnerId: Int64, analyticsUrl: String, ovpServiceUrl: String, uiConfId: Int64) {
        
        KPOTTDMSConfigModel.shared.addPartnerConfig(partnerId: partnerId, ovpPartnerId: ovpPartnerId, analyticsUrl: analyticsUrl, ovpServiceUrl: ovpServiceUrl, uiConfId: uiConfId)
    }
}

// MARK: - Playlists

extension KalturaOTTPlayer {
    
    @objc public func loadPlaylist(options: [OTTMediaOptions], callback: @escaping (_ error: NSError?) -> Void) {
        self.playlistController = nil
        
        // Fetch for first available media ks
        let mediaOptions = options.first { mediaOptions in
            if let ks = mediaOptions.ks, !ks.isEmpty {
                return true
            }
            return false
        }
        
        if let newKS = mediaOptions?.ks, !newKS.isEmpty {
            updatePlayerOptionsKS(newKS)
        }
        
        sessionProvider.ks = playerOptions.ks
        
        let assets: [OTTPlaylistAsset] = options.map { OTTPlaylistAsset(id: $0.assetId,
                                                                        assetReferenceType: $0.assetReferenceType) }
        
        let phoenixPlaylistProvider = PhoenixPlaylistProvider()
        phoenixPlaylistProvider.set(referrer: KalturaOTTPlayerManager.shared.referrer)
        phoenixPlaylistProvider.set(sessionProvider: sessionProvider)
        phoenixPlaylistProvider.set(mediaAssets: assets)
        
        phoenixPlaylistProvider.loadPlaylist { [weak self] (playList: PKPlaylist?, error: Error?) in
            guard let self = self else { return }
            guard let playList = playList else {
                if let error = error as? PhoenixMediaProviderError {
                    callback(error.asNSError)
                    return
                }
                callback(KalturaPlayerError.playlistProviderError.asNSError)
                return
            }
            
            let controller = KPOTTPlaylistController(playlistConfig: nil,
                                                     playlist: playList,
                                                     player: self)
            
            controller.originalOTTMediaOptions = options
            self.playlistController = controller
            callback(nil)
        }
    }
    
}

extension KalturaOTTPlayer: EntryLoader {
    
    internal func loadMedia(options: MediaOptions, callback: @escaping (_ entry: PKMediaEntry?, _ error: NSError?) -> Void) {
        guard let mediaOptions = options as? OTTMediaOptions else {
            callback(nil, KalturaPlayerError.invalidMediaOptions.asNSError)
            return
        }
        
        ottMediaOptions = mediaOptions
        sessionProvider.ks = playerOptions.ks
        
        let phoenixMediaProvider = mediaOptions.mediaProvider()
        phoenixMediaProvider.set(referrer: KalturaOTTPlayerManager.shared.referrer)
        phoenixMediaProvider.set(sessionProvider: sessionProvider)
        
        phoenixMediaProvider.loadMedia { (pkMediaEntry, error) in
            guard let mediaEntry = pkMediaEntry else {
                if let error = error {
                    switch error {
                    case let pkError as PKError:
                        callback(nil, KalturaPlayerError.mediaProviderError(code: String(pkError.code), message: pkError.errorDescription).asNSError)
                    case let nsError as NSError:
                        var code = String(nsError.code)
                        if let serverErrorCode = nsError.userInfo[ProviderServerErrorCodeKey] as? String, !serverErrorCode.isEmpty {
                            code = serverErrorCode
                        }
                        var message = nsError.description
                        if let serverErrorMessage = nsError.userInfo[ProviderServerErrorMessageKey] as? String, !serverErrorMessage.isEmpty {
                            message = serverErrorMessage
                        }
                        callback(nil, KalturaPlayerError.mediaProviderError(code: code, message: message).asNSError)
                    default:
                        callback(nil, KalturaPlayerError.mediaProviderError(code: "LoadMediaError", message: error.localizedDescription).asNSError)
                    }
                } else {
                    callback(nil, KalturaPlayerError.invalidPKMediaEntry.asNSError)
                }
                
                return
            }
            
            callback(mediaEntry, nil)
        }
    }
    
}
