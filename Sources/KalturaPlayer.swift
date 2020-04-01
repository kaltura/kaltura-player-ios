

import Foundation
import PlayKit
import PlayKitKava

public typealias KPEvent = PlayerEvent
public typealias KPTrack = Track

protocol IKalturaPlayer {
    func prepare()
}

public class KalturaPlayer: NSObject {
    
    private var player: Player!
    
    let DEFAULT_KAVA_PARTNER_ID: Int = 2504201
    let DEFAULT_KAVA_ENTRY_ID: String = "1_3bwzbc9o"
    
    internal init(pluginConfig: PluginConfig) {
        super.init()
        
        addDefaultPlugins(to: pluginConfig)
        player = PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig)
    }
    
    private func addDefaultPlugins(to pluginConfig: PluginConfig) {
        if pluginConfig.config[KavaPlugin.pluginName] == nil {
            PlayKitManager.shared.registerPlugin(KavaPlugin.self)
            pluginConfig.config[KavaPlugin.pluginName] = KavaPluginConfig(partnerId: DEFAULT_KAVA_PARTNER_ID, entryId: DEFAULT_KAVA_ENTRY_ID)
        }
    }
    
    func prepareMediaConfig(_ mediaConfig: MediaConfig) {
        player.prepare(mediaConfig)
    }
    
    // MARK: - Public Methods
    
    public func setPlayerView(_ kalturaPlayerView: KalturaPlayerView) {
        kalturaPlayerView.playerView = PlayerView.createPlayerView(forPlayer: player)
    }
    
    // MARK: - Player
    
    /// The player's associated media entry.
    public var mediaEntry: PKMediaEntry? {
        get {
            return player.mediaEntry
        }
    }
    
    /// The player's settings.
    public var settings: PKPlayerSettings {
        get {
            return player.settings
        }
    }
    
    /// The current media format.
    public var mediaFormat: PKMediaSource.MediaFormat {
        get {
            return player.mediaFormat
        }
    }
    
    /// The player's session id. the `sessionId` is initialized when the player loads.
    public var sessionId: String {
        get {
            return player.sessionId
        }
    }
    
    /// Add Observation to relevant event.
    public func addObserver(_ observer: AnyObject, event: KPEvent.Type, block: @escaping (PKEvent) -> Void) {
        player.addObserver(observer, event: event, block: block)
    }
    
    /// Add Observation to relevant events.
    public func addObserver(_ observer: AnyObject, events: [KPEvent.Type], block: @escaping (PKEvent) -> Void) {
        player.addObserver(observer, events: events, block: block)
    }
    
    /// Remove Observer for single event.
    public func removeObserver(_ observer: AnyObject, event: KPEvent.Type) {
        player.removeObserver(observer, event: event)
    }
    
    /// Remove Observer for several events.
    public func removeObserver(_ observer: AnyObject, events: [KPEvent.Type]) {
        player.removeObserver(observer, events: events)
    }
    
    /// Update Plugin Config.
    public func updatePluginConfig(pluginName: String, config: Any) {
        player.updatePluginConfig(pluginName: pluginName, config: config)
    }
    
    /// Updates the styling from the settings textTrackStyling object
    public func updateTextTrackStyling() {
        player.updateTextTrackStyling()
    }
    
    /// Indicates if current media is Live.
    ///
    /// - Returns: returns true if it's live.
    public func isLive() -> Bool {
        return player.isLive()
    }
    
    /// Getter for playkit controllers.
    ///
    /// - Parameter type: Required class type.
    /// - Returns: Relevant controller if exist.
    public func getController(type: PKController.Type) -> PKController? {
        return player.getController(type: type)
    }
    
    // MARK: - BasicPlayer
    
    /// The player's duration.
    public var duration: TimeInterval {
        get {
            return player.duration
        }
    }
    
    /// The player's currentState.
    public var currentState: PlayerState {
        get {
            return player.currentState
        }
    }
    
    /// Indicates if the player is playing.
    public var isPlaying: Bool {
        get {
            return player.isPlaying
        }
    }
    
    /// The current player's time.
    public var currentTime: TimeInterval {
        get {
            return player.currentTime
        }
        set {
            player.currentTime = newValue
        }
    }
    
    /// The current program time (PROGRAM-DATE-TIME).
    public var currentProgramTime: Date? {
        get {
            return player.currentProgramTime
        }
    }
    
    /// Get the player's current audio track.
    public var currentAudioTrack: String? {
        get {
            return player.currentAudioTrack
        }
    }
    
    /// Get the player's current text track.
    public var currentTextTrack: String? {
        get {
            return player.currentTextTrack
        }
    }
    
    /// Indicates the desired rate of playback, 0.0 means "paused", 1.0 indicates a desire to play at the natural rate of the current item.
    /// Note: Do not use the rate to indicate whether to play or pause! Use the isPlaying property.
    public var rate: Float {
        get {
            return player.rate
        }
        set {
            player.rate = newValue
        }
    }
    
    /// The audio playback volume for the player, ranging from 0.0 through 1.0 on a linear scale.
    public var volume: Float {
        get {
            return player.volume
        }
        set {
            player.volume = newValue
        }
    }
    
    /// Provides a collection of time ranges for which the player has the media data readily available. The ranges provided might be discontinuous.
    public var loadedTimeRanges: [PKTimeRange]? {
        get {
            return player.loadedTimeRanges
        }
    }
    
    /// Send a play action for the player.
    public func play() {
        player.play()
    }
    
    /// Send a pause action for the player.
    public func pause() {
        player.pause()
    }
    
    /// Send a resume action for the player.
    public func resume() {
        player.resume()
    }
    
    /// Send a stop action for the player.
    public func stop() {
        player.stop()
    }
    
    /// Send a replay action for the player.
    public func replay() {
        player.replay()
    }
    
    /// Send a seek action for the player.
    public func seek(to time: TimeInterval) {
        player.seek(to: time)
    }
    
    /// Select a Track
    public func selectTrack(trackId: String) {
        player.selectTrack(trackId: trackId)
    }
    
    /// Release the player's resources.
    public func destroy() {
        player.destroy()
    }
    
    /// Starts buffering the entry.
    @objc func startBuffering() {
        player.startBuffering()
    }
}
