//
//  KalturaOVPPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 7/30/20.
//

import Foundation
import PlayKit
import PlayKitKava
import PlayKitProviders

@objc public class KalturaOVPPlayer: KalturaPlayer {
    
    private var ovpMediaOptions: OVPMediaOptions? {
        didSet {
            mediaOptions = ovpMediaOptions
        }
    }
    
    private var sessionProvider: SimpleSessionProvider

    /**
        Set up the Kaltura OVP Player with the Partner ID.

        The setup will request the DMS Configuration required for the player and register the `KavaPlugin`.
     
        In addition the setup will register any Kaltura's plugin which will be added in the pod file.
        Supporting `PlayKit_IMA` and `PlayKitYoubora` pods.

        * Parameters:
            * partnerId: The OVP Partner ID.
            * serverURL: A custom OVP Server URL. Default value, "https://cdnapisec.kaltura.com/".
            * referrer:  A custom referrer. Default value, the application bundle id.
    */
    @objc public static func setup(partnerId: Int64, serverURL: String? = nil, referrer: String? = nil) {
        KalturaOVPPlayerManager.shared.partnerId = partnerId
        
        if let serverURL = serverURL, !serverURL.isEmpty {
            KalturaOVPPlayerManager.shared.serverURL = serverURL
        }
        if let referrer = referrer, !referrer.isEmpty {
            KalturaOVPPlayerManager.shared.referrer = referrer
        }
        
        KalturaOVPPlayerManager.shared.fetchConfiguration()
        
        PlayKitManager.shared.registerPlugin(KavaPlugin.self)
    }
    
    /**
       A Kaltura Player for OVP Clients. Kava embeded.
    
       Create the player options, `PlayerOptions`, and pass it to the `KalturaOVPPlayer`.
       Check the `PlayerOptions` for more info regarding the available options and defaults.
       Create a `KalturaPlayerView` in the code or in the xib and pass it to the `KalturaOVPPlayer`.
       
       **Example:**
    
           let playerOptions = PlayerOptions()
           let kalturaOVPPlayer = KalturaOVPPlayer(options: playerOptions)
           kalturaOVPPlayer.view = kalturaPlayerView
    
       * Parameters:
           * options: The player's initialize options.
    */
    @objc public init(options: PlayerOptions) {
        sessionProvider = SimpleSessionProvider(serverURL: KalturaOVPPlayerManager.shared.serverURL,
                                                partnerId: KalturaOVPPlayerManager.shared.partnerId,
                                                ks: options.ks)
        
        if (options.pluginConfig.config[KavaPlugin.pluginName] == nil) {
            // In case the Partner Configuration won't be available yet, setting the KavaPluginConfig with a placeholder cause an update is performed upon loadMedia without validating if the plugin was set.
            let partnerId = KalturaOVPPlayerManager.shared.cachedConfigData?.ovpPartnerId ?? KalturaOVPPlayerManager.shared.partnerId
            options.pluginConfig.config[KavaPlugin.pluginName] = KavaPluginConfig(partnerId: Int(partnerId))
        }
        
        super.init(playerOptions: options)
    }
    
    // MARK: - Private Methods
    // Set media and update plugins if needed.
    internal override func setMediaAndUpdatePlugins(mediaEntry: PKMediaEntry,
                                                    mediaOptions: MediaOptions?,
                                                    pluginConfig: PluginConfig?,
                                                    callback: @escaping (_ error: NSError?) -> Void) {
        
        if let options = mediaOptions as? OVPMediaOptions {
            ovpMediaOptions = options
        }
        
        // The Configuration is needed in order to continue.
        guard let ovpPartnerId = KalturaOVPPlayerManager.shared.cachedConfigData?.ovpPartnerId else {
            callback(KalturaPlayerError.configurationMissing.asNSError)
            return
        }
        
        if !self.isPluginLoaded(pluginName: KavaPlugin.pluginName) {
            // Update KavaPlugin if it was not set explicitly for specific Media.
            self.updateKavaPlugin(partnerId: ovpPartnerId, entryId: mediaEntry.id, mediaOptions: mediaOptions as? OVPMediaOptions)
        }
        
        // If any custom plugin config has been sent use it instead.
        if let pluginConfig = pluginConfig {
            pluginConfig.config.forEach { (name, config) in
                updatePluginConfig(pluginName: name, config: config)
            }
        }
        
        self.mediaEntry = mediaEntry
        callback(nil)
    }
    
    func updateKavaPlugin(partnerId: Int64, entryId: String, mediaOptions: OVPMediaOptions?) {
        let kavaPluginConfig = KavaHelper.getPluginConfig(ovpPartnerId: partnerId,
                                                          ovpEntryId: entryId,
                                                          ks: playerOptions.ks,
                                                          referrer: KalturaOVPPlayerManager.shared.referrer,
                                                          playbackContext: nil,
                                                          analyticsUrl: KalturaOVPPlayerManager.shared.cachedConfigData?.analyticsUrl,
                                                          playlistId: self.playlistController?.playlist.id)
        
        self.updatePluginConfig(pluginName: KavaPlugin.pluginName, config: kavaPluginConfig)
    }
    
    // MARK: - Public Methods
    
    /**
        Loads the media with the provided media options.
        
        Will set the MediaEntry and automatically prepare the media in case the `PlayerOptions` autoPlay or preload is set to true, which is the default value. Call prepare manually in case the autoPlay and preload was set to false.
        
        In case an error occurred retrieving the media from the provider, the error will return in the callback function.
     
        Kava is updated automatically.
        
        * Parameters:
            * options: The media options. See `OVPMediaOptions` for more details.
            * callback:
            * error: A `KalturaPlayerError` in case of an issue. See `KalturaPlayerError` for more details.
     */
    @objc public func loadMedia(options: OVPMediaOptions, callback: @escaping (_ error: NSError?) -> Void) {
        self.loadMedia(options: options) { [weak self] (pkMediaEntry: PKMediaEntry?, error: NSError?) in
            guard let self = self else { return }
            guard let mediaEntry = pkMediaEntry else {
                if let error = error {
                    callback(error)
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

extension KalturaOVPPlayer {
    
    /**
        Call this function in case the BE environment has not been set up yet with the config data.
     
        This function needs to be called before the `setup` function.
     
        * Parameters:
            * partnerId:                    The OVP Partner ID.
            * analyticsUrl:                 The Analytics Url used for Kava.
            * analyticsPersistentSessionId: Whether to set a persistent session id.
    */
    @objc public static func bypassConfigFetching(partnerId: Int64, analyticsUrl: String, analyticsPersistentSessionId: Bool) {
        
        KPOVPConfigModel.shared.addPartnerConfig(partnerId: partnerId, analyticsUrl: analyticsUrl, analyticsPersistentSessionId: analyticsPersistentSessionId)
    }
}

// MARK: - Playlists

extension KalturaOVPPlayer {
    
    @objc public func loadPlaylistById(options: OVPPlaylistOptions, callback: @escaping (_ error: NSError?) -> Void) {
        self.playlistController = nil
        
        if let newKS = options.ks, !newKS.isEmpty {
            updatePlayerOptionsKS(newKS)
        }
        
        sessionProvider.ks = playerOptions.ks
        
        let ovpPlaylistProvider = options.playlistProvider()
        ovpPlaylistProvider.set(referrer: KalturaOVPPlayerManager.shared.referrer)
        ovpPlaylistProvider.set(sessionProvider: sessionProvider)
        
        ovpPlaylistProvider.loadPlaylist { [weak self] (playList: PKPlaylist?, error: Error?) in
            guard let self = self else { return }
            guard let playList = playList else {
                if let error = error as? OVPMediaProviderError {
                    callback(error.asNSError)
                    return
                }
                callback(KalturaPlayerError.playlistProviderError.asNSError)
                return
            }
            
            let controller = KPOVPPlaylistController(playlistConfig: nil,
                                                  playlist: playList,
                                                  player: self)
            
            self.playlistController = controller
            
            callback(nil)
        }
    }
    
    @objc public func loadPlaylist(options: [OVPMediaOptions], callback: @escaping (_ error: NSError?) -> Void) {
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
        
        let assets: [OVPMediaAsset] = options.map { OVPMediaAsset(id: $0.entryId, referenceId: $0.referenceId) }
        
        let ovpPlaylistProvider = OVPPlaylistProvider()
        ovpPlaylistProvider.set(referrer: KalturaOVPPlayerManager.shared.referrer)
        ovpPlaylistProvider.set(sessionProvider: sessionProvider)
        ovpPlaylistProvider.set(mediaAssets: assets)
        
        ovpPlaylistProvider.loadPlaylist { [weak self] (playList: PKPlaylist?, error: Error?) in
            guard let self = self else { return }
            guard let playList = playList else {
                if let error = error as? PKError {
                    callback(KalturaPlayerError.mediaProviderError(code: "\(error.code)", message: error.errorDescription).asNSError)
                }
                return
            }
            
            let controller = KPOVPPlaylistController(playlistConfig: nil,
                                                  playlist: playList,
                                                  player: self)
            
            controller.originalOVPMediaOptions = options
            self.playlistController = controller
            
            callback(nil)
        }
    }
    
}

extension KalturaOVPPlayer: EntryLoader {
    
    internal func loadMedia(options: MediaOptions, callback: @escaping (_ entry: PKMediaEntry?, _ error: NSError?) -> Void) {
        guard let mediaOptions = options as? OVPMediaOptions else {
            callback(nil, KalturaPlayerError.invalidMediaOptions.asNSError)
            return
        }
        
        ovpMediaOptions = mediaOptions
        sessionProvider.ks = playerOptions.ks
        
        let ovpMediaProvider = mediaOptions.mediaProvider()
        ovpMediaProvider.set(referrer: KalturaOVPPlayerManager.shared.referrer)
        ovpMediaProvider.set(sessionProvider: sessionProvider)
        
        ovpMediaProvider.loadMedia { (pkMediaEntry, error) in
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
