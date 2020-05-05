

import Foundation
import PlayKit

public typealias KPEvent = PlayerEvent
public typealias KPTrack = Track

public class KalturaPlayer: NSObject {
    
    private var playerOptions: PlayerOptions
    private var pkPlayer: Player!
    private var shouldPrepare: Bool = true
    
    /// The player's view which the media will be displayed within.
    public var view: KalturaPlayerView? {
        didSet {
            guard let kalturaPlayerView = view else {
                return
            }
            kalturaPlayerView.playerView = PlayerView.createPlayerView(forPlayer: pkPlayer)
        }
    }
    
    let DEFAULT_KAVA_BASE_URL: String = "https://analytics.kaltura.com/api_v3/index.php"
    let DEFAULT_KAVA_PARTNER_ID: Int = 2504201
    let DEFAULT_KAVA_ENTRY_ID: String = "1_3bwzbc9o"
    
    internal init(playerOptions: PlayerOptions) {
        self.playerOptions = playerOptions
        pkPlayer = PlayKitManager.shared.loadPlayer(pluginConfig: self.playerOptions.pluginConfig)
        super.init()
    }
    
    internal func updatePlayerOptions(_ playerOptions: PlayerOptions) {
        self.playerOptions = playerOptions
        
        self.playerOptions.pluginConfig.config.forEach { (name, config) in
            pkPlayer.updatePluginConfig(pluginName: name, config: config)
        }
    }
    
    // MARK: - Public Methods
    
    /**
        Call in order to prepare the media on the player.
     
        * Note:
            When the PlayerOptions preload is set too true, this function will be called automatically.
     */
    public func prepare() {
        guard let mediaEntry = self.mediaEntry else {
            PKLog.debug("MediaEntry is empty.")
            return
        }
        if !shouldPrepare { return }
        shouldPrepare = false
        // create media config
        let mediaConfig: MediaConfig
        if let startTime = playerOptions.startTime {
            mediaConfig = MediaConfig(mediaEntry: mediaEntry, startTime: startTime)
        } else {
            mediaConfig = MediaConfig(mediaEntry: mediaEntry)
        }

        pkPlayer.prepare(mediaConfig)
        
        if playerOptions.autoPlay {
            self.play()
        }
    }
    
    // MARK: - Player
    
    /**
        The player's associated media entry.

        Upon setting to a new value, if the PlayerOption autoPlay or preload is set too true, prepare on the player will be automatically called.
     */
    public var mediaEntry: PKMediaEntry? {
        didSet {
            if mediaEntry == nil { return }
            shouldPrepare = true
            if playerOptions.autoPlay || playerOptions.preload {
                prepare()
            }
        }
    }
    
    /// The player's settings.
    public var settings: PKPlayerSettings {
        get {
            return pkPlayer.settings
        }
    }
    
    /// The current media format.
    public var mediaFormat: PKMediaSource.MediaFormat {
        get {
            return pkPlayer.mediaFormat
        }
    }
    
    /// The player's session id. The `sessionId` is initialized when the player loads.
    public var sessionId: String {
        get {
            return pkPlayer.sessionId
        }
    }
    
    /**
        Add an observation to a relevant event.

        * Parameters:
            * observer: The object that will be the observer.
            * event: Which `KPEvent` to observe.
            * block: The callback function that will be called.
     */
    public func addObserver(_ observer: AnyObject, event: KPEvent.Type, block: @escaping (PKEvent) -> Void) {
        pkPlayer.addObserver(observer, event: event, block: block)
    }
    
    /**
       Add an observation to relevant events.

       * Parameters:
           * observer: The object that will be the observer.
           * events: A list of `KPEvent`'s too observe.
           * block: The callback function that will be called.
    */
    public func addObserver(_ observer: AnyObject, events: [KPEvent.Type], block: @escaping (PKEvent) -> Void) {
        pkPlayer.addObserver(observer, events: events, block: block)
    }
    
    /**
       Remove the observer for an event.

       * Parameters:
           * observer: The object that the observation will be removed from.
           * event: Which `KPEvent` to remove the observation from.
    */
    public func removeObserver(_ observer: AnyObject, event: KPEvent.Type) {
        pkPlayer.removeObserver(observer, event: event)
    }
    
    /**
       Remove the observer from the events.

       * Parameters:
           * observer: The object that the observation will be removed from.
           * events: A list of `KPEvent`'s to remove the observation from.
    */
    public func removeObserver(_ observer: AnyObject, events: [KPEvent.Type]) {
        pkPlayer.removeObserver(observer, events: events)
    }
    
    /**
       Update a Plugin Config.

       * Parameters:
           * pluginName: The Plugin name.
           * config: The Plugin configuration object.
    */
    public func updatePluginConfig(pluginName: String, config: Any) {
        pkPlayer.updatePluginConfig(pluginName: pluginName, config: config)
    }
    
    /// Updates the styling from the settings textTrackStyling object
    public func updateTextTrackStyling() {
        pkPlayer.updateTextTrackStyling()
    }
    
    /**
        Indicates if current media is Live.
     
        * Returns: `true` if it's live, `false` otherwise.
     */
    public func isLive() -> Bool {
        return pkPlayer.isLive()
    }
    
    /**
        Getter for a playkit controller.
     
        * Parameters:
            * type: The required `PKController` class type.
     
        * Returns: The relevant controller if exist, `nil` otherwise.
     */
    public func getController(type: PKController.Type) -> PKController? {
        return pkPlayer.getController(type: type)
    }
    
    // MARK: - BasicPlayer
    
    /// The player's duration.
    public var duration: TimeInterval {
        get {
            return pkPlayer.duration
        }
    }
    
    /// The player's currentState.
    public var currentState: PlayerState {
        get {
            return pkPlayer.currentState
        }
    }
    
    /// Indicates if the player is playing.
    public var isPlaying: Bool {
        get {
            return pkPlayer.isPlaying
        }
    }
    
    /// The current player's time.
    public var currentTime: TimeInterval {
        get {
            return pkPlayer.currentTime
        }
        set {
            pkPlayer.currentTime = newValue
        }
    }
    
    /// The current program time (PROGRAM-DATE-TIME).
    public var currentProgramTime: Date? {
        get {
            return pkPlayer.currentProgramTime
        }
    }
    
    /// Get the player's current audio track.
    public var currentAudioTrack: String? {
        get {
            return pkPlayer.currentAudioTrack
        }
    }
    
    /// Get the player's current text track.
    public var currentTextTrack: String? {
        get {
            return pkPlayer.currentTextTrack
        }
    }
    
    /**
        Indicates the desired rate of playback, 0.0 means "paused", 1.0 indicates a desire to play at the natural rate of the current item.
            
        * Important: Do not use the rate to indicate whether to play or pause! Use the isPlaying property.
     */
    public var rate: Float {
        get {
            return pkPlayer.rate
        }
        set {
            pkPlayer.rate = newValue
        }
    }
    
    /// The audio playback volume for the player, ranging from 0.0 through 1.0 on a linear scale.
    public var volume: Float {
        get {
            return pkPlayer.volume
        }
        set {
            pkPlayer.volume = newValue
        }
    }
    
    /// Provides a collection of time ranges for which the player has the media data readily available. The ranges provided might be discontinuous.
    public var loadedTimeRanges: [PKTimeRange]? {
        get {
            return pkPlayer.loadedTimeRanges
        }
    }
    
    /// Send a play action for the player.
    public func play() {
        pkPlayer.play()
    }
    
    /// Send a pause action for the player.
    public func pause() {
        pkPlayer.pause()
    }
    
    /// Send a resume action for the player.
    public func resume() {
        pkPlayer.resume()
    }
    
    /// Send a stop action for the player.
    public func stop() {
        pkPlayer.stop()
    }
    
    /// Send a replay action for the player.
    public func replay() {
        pkPlayer.replay()
    }
    
    /// Send a seek action for the player.
    public func seek(to time: TimeInterval) {
        pkPlayer.seek(to: time)
    }
    
    /// Select a Track
    public func selectTrack(trackId: String) {
        pkPlayer.selectTrack(trackId: trackId)
    }
    
    /// Release the player's resources.
    public func destroy() {
        pkPlayer.destroy()
    }
    
    /**
        Starts buffering the entry.
     
        Call this function if the player's `settings.network.autoBuffer` is set too false. Otherwise it is done automatically.
     */
    public func startBuffering() {
        pkPlayer.startBuffering()
    }
}
