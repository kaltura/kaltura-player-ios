//
//  KalturaPlayer.swift
//  KalturaPlayer
//
//  Created by Vadik on 21/11/2017.
//

import Foundation
import PlayKit

public class KalturaPlayer {
    var partnerId: Int64
    var ks: String?
    
    var player: Player!
    var autoPlay: Bool = false
    var autoPrepare: Bool = false
    var startPosition: Double = 0.0
    var mediaEntry: PKMediaEntry?
    
    var preferredFormat: PKMediaSource.MediaFormat = .unknown
    var referrer: String = ""
    var serverUrl: String = ""
    
    internal init(partnerId: Int64, ks: String?, pluginConfig: PluginConfig?, options: KalturaPlayerOptions?) {
        self.partnerId = partnerId
        self.ks = ks
        
        if let options = options {
            self.autoPlay = options.autoPlay
            self.autoPrepare = options.autoPrepare
            self.preferredFormat = options.preferredFormat
            self.serverUrl = options.serverUrl + (options.serverUrl.hasSuffix("/") ? "" : "/")
        } else {
            self.serverUrl = getDefaultServerUrl()
        }
        
        self.referrer = buildReferrer(appReferrer: options?.referrer)
        
        initializeBackendComponents()
        registerPlugins()
        loadPlayer(pluginConfig: pluginConfig)
    }
    
    public func setMedia(_ mediaEntry: PKMediaEntry) {
        self.mediaEntry = mediaEntry
        
        if autoPrepare {
            prepare()
        }
    }
    
    public func prepare() {
        if let _ = mediaEntry {
            let config = MediaConfig(mediaEntry: mediaEntry!, startTime: startPosition)
            prepare(config)
            
            if autoPlay {
                play()
            }
        }
    }
    
    public func getKS() -> String? {
        return ks
    }
    
    public func setKS(_ ks: String) {
        self.ks = ks
        updateKS(ks)
    }
    
    func buildReferrer(appReferrer: String?) -> String {
        if let url = appReferrer, verifyUrl(url) {
            return url
        }
        
        return "app://\(Bundle.main.bundleIdentifier ?? "")"
    }
    
    func verifyUrl(_ urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    func loadPlayer(pluginConfig: PluginConfig?) {
        let kalturaConfigs = getKalturaPluginConfigs()
        for (key, value) in kalturaConfigs {
            pluginConfig?.config[key] = value
        }
        do {
            self.player = try PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig)
        } catch {
            fatalError("player isn't initilized")
        }
        
        KalturaPlaybackRequestAdapter.install(in: player, withReferrer: referrer)
    }
    
    func mediaLoadCompleted(entry: PKMediaEntry?, error: Error?, callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        if let _ = entry {
            removeUnpreferredFormatsIfNeeded(entry: entry!)
        }
        DispatchQueue.main.async {
            callback(entry, error)
        }
    }
    
    func removeUnpreferredFormatsIfNeeded(entry: PKMediaEntry) {
        if preferredFormat != .unknown, let entrySources = entry.sources {
            var preferredSources = [PKMediaSource]()
            for s in entrySources {
                if s.mediaFormat == preferredFormat {
                    preferredSources.append(s)
                }
            }
            
            if preferredSources.count > 0 {
                entry.sources = preferredSources
            }
        }
    }
    
    // Player controls
    @objc var duration: TimeInterval {
        return player.duration
    }
    
    @objc var currentState: PlayerState {
        return player.currentState
    }
    
    @objc var isPlaying: Bool {
        return player.isPlaying
    }
    
    @objc weak var view: PlayerView? {
        get {
            return player.view
        }
        set {
            player.view = newValue
        }
    }
    
    @objc var currentTime: TimeInterval {
        get {
            return player.currentTime
        }
        set {
            player.currentTime = newValue
        }
    }
    
    @objc var currentAudioTrack: String? {
        return player.currentAudioTrack
    }
    
    @objc var currentTextTrack: String? {
        return player.currentTextTrack
    }
    
    @objc var rate: Float {
        return player.rate
    }
    
    @objc var loadedTimeRanges: [PKTimeRange]? {
        return player.loadedTimeRanges
    }
    
    @objc func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void) {
        player.addObserver(observer, event: event, block: block)
    }
    
    @objc func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        player.addObserver(observer, events: events, block: block)
    }
    
    @objc func removeObserver(_ observer: AnyObject, event: PKEvent.Type) {
        player.removeObserver(observer, event: event)
    }
    
    @objc func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        player.removeObserver(observer, events: events)
    }
    
    @objc func updatePluginConfig(pluginName: String, config: Any) {
        player.updatePluginConfig(pluginName: pluginName, config: config)
    }
    
    @objc func getController(type: PKController.Type) -> PKController? {
        return player.getController(type: type)
    }

    @objc func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval) -> Void) -> UUID {
        return player.addPeriodicObserver(interval: interval, observeOn: dispatchQueue, using: block)
    }
    
    
    @objc func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval, Double) -> Void) -> UUID {
        return player.addBoundaryObserver(boundaries: boundaries, observeOn: dispatchQueue, using: block)
    }
    
    @objc func removePeriodicObserver(_ token: UUID) {
        player.removePeriodicObserver(token)
    }
    
    @objc func removeBoundaryObserver(_ token: UUID) {
        player.removeBoundaryObserver(token)
    }
    
    @objc public func play() {
        player.play()
    }
    
    @objc public func pause() {
        player.pause()
    }
    
    @objc public func resume() {
        player.resume()
    }
    
    @objc public func stop() {
        player.stop()
    }
    
    @objc public func seek(to time: TimeInterval) {
        player.seek(to: time)
    }
    
    @objc public func selectTrack(trackId: String) {
        player.selectTrack(trackId: trackId)
    }
    
    @objc public func destroy() {
        player.destroy()
    }
    
    @objc func prepare(_ config: MediaConfig) {
        player.prepare(config)
    }
    
    //abstract methods
    func getDefaultServerUrl() -> String {
        fatalError("must be implemented in subclass")
    }
    
    func loadMedia(entryId: String, callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        fatalError("must be implemented in subclass")
    }
    
    func getKalturaPluginConfigs() -> [String : Any] {
        fatalError("must be implemented in subclass")
    }
    
    func registerPlugins() {
        fatalError("must be implemented in subclass")
    }
    
    func initializeBackendComponents() {
        fatalError("must be implemented in subclass")
    }
    
    func updateKS(_ ks: String) {
        fatalError("must be implemented in subclass")
    }
}

public struct KalturaPlayerOptions {
    var autoPlay: Bool
    var autoPrepare: Bool
    var preferredFormat: PKMediaSource.MediaFormat
    var serverUrl: String
    var referrer: String
}
