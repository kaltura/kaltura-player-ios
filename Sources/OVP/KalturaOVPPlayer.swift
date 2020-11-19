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
        
        // In case the Partner Configuration won't be available yet, setting the KavaPluginConfig with a placeholder cause an update is performed upon loadMedia without validating if the plugin was set.
        let partnerId = KalturaOVPPlayerManager.shared.cachedConfigData?.ovpPartnerId ?? KalturaOVPPlayerManager.shared.partnerId
        options.pluginConfig.config[KavaPlugin.pluginName] = KavaPluginConfig(partnerId: Int(partnerId))
        
        super.init(playerOptions: options)
    }
    
    // MARK: - Private Methods
    
    func updateKavaPlugin(partnerId: Int64, entryId: String, mediaOptions: OVPMediaOptions) {
        
        let ks = mediaOptions.ks?.isEmpty == false ? mediaOptions.ks : playerOptions.ks
        
        let kavaPluginConfig = KavaHelper.getPluginConfig(ovpPartnerId: partnerId,
                                                          ovpEntryId: entryId,
                                                          ks: ks,
                                                          referrer: KalturaOVPPlayerManager.shared.referrer,
                                                          playbackContext: nil,
                                                          analyticsUrl: KalturaOVPPlayerManager.shared.cachedConfigData?.analyticsUrl)
        
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
    @objc public func loadMedia(options: OVPMediaOptions, callback: @escaping (_ error: Error?) -> Void) {
        ovpMediaOptions = options
        
        if options.ks?.isEmpty == false {
            sessionProvider.ks = options.ks
        } else {
            sessionProvider.ks = playerOptions.ks
        }
        
        let ovpMediaProvider = options.mediaProvider()
        ovpMediaProvider.set(referrer: KalturaOVPPlayerManager.shared.referrer)
        ovpMediaProvider.set(sessionProvider: sessionProvider)
        
        ovpMediaProvider.loadMedia { [weak self] (pkMediaEntry, error) in
            guard let self = self else { return }
            
            guard let mediaEntry = pkMediaEntry else {
                if let error = error {
                    switch error {
                    case let pkError as PKError:
                        callback(KalturaPlayerError.mediaProviderError(code: String(pkError.code), message: pkError.errorDescription))
                    case let nsError as NSError:
                        var code = String(nsError.code)
                        if let serverErrorCode = nsError.userInfo[ProviderServerErrorCodeKey] as? String, !serverErrorCode.isEmpty {
                            code = serverErrorCode
                        }
                        var message = nsError.description
                        if let serverErrorMessage = nsError.userInfo[ProviderServerErrorMessageKey] as? String, !serverErrorMessage.isEmpty {
                            message = serverErrorMessage
                        }
                        callback(KalturaPlayerError.mediaProviderError(code: code, message: message))
                    default:
                        callback(KalturaPlayerError.mediaProviderError(code: "LoadMediaError", message: error.localizedDescription))
                    }
                } else {
                    callback(KalturaPlayerError.invalidPKMediaEntry)
                }
                
                return
            }
            
            // The Configuration is needed in order to continue.
            guard let ovpPartnerId = KalturaOVPPlayerManager.shared.cachedConfigData?.ovpPartnerId else {
                callback(KalturaPlayerError.configurationMissing)
                return
            }
            
            self.updateKavaPlugin(partnerId: ovpPartnerId, entryId: mediaEntry.id, mediaOptions: options)
            
            self.mediaEntry = mediaEntry
            callback(nil)
        }
    }
}
