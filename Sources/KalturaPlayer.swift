

import Foundation
import PlayKit

public typealias KPPlayerEvent = PlayerEvent
public typealias KPTrack = Track
public typealias KPAdEvent = AdEvent

public enum KalturaPlayerError: PKError {
    case configurationMissing
    case mediaProviderError(code:String, message:String)
    case invalidPKMediaEntry
    
    public static let domain = "com.kaltura.player.error"
    public static let serverErrorCodeKey = "code"
    public static let serverErrorMessageKey = "message"
    
    public var code: Int {
        switch self {
        case .configurationMissing: return 8001
        case .mediaProviderError: return 8002
        case .invalidPKMediaEntry: return 8003
        }
    }
    
    public var errorDescription: String {
        switch self {
        case .configurationMissing: return "The Configuration has not been retrieved yet."
        case .mediaProviderError(let code, let message): return "Media Provider Error, code: \(code), \n message: \(message)"
        case .invalidPKMediaEntry: return "Load media on the provider returned with an empty PKMediaEntry."
        }
    }
    
    public var userInfo: [String: Any] {
        switch self {
        case .mediaProviderError(let code, let message):
            return [KalturaPlayerError.serverErrorCodeKey: code,
                    KalturaPlayerError.serverErrorMessageKey: message]
        default:
            return [String: Any]()
        }
    }
}

@objc public class KalturaPlayer: NSObject {
    
    internal var playerOptions: PlayerOptions
    internal var mediaOptions: MediaOptions?
    
    private var pkPlayer: Player!
    private var shouldPrepare: Bool = true
    
    internal var interceptors: [PKMediaEntryInterceptor]? {
        get {
            guard let player = pkPlayer as? PlayerPluginsDataSource else {
                return nil
            }
            
            return player.getLoadedPlugins(ofType: PKMediaEntryInterceptor.self)
        }
    }
    
    /// The player's view which the media will be displayed within.
    @objc public var view: KalturaPlayerView? {
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
    
    // MARK: - Public Methods
    
    /**
        Update the player's initialized options.
     
        * Parameters:
            * playerOptions: A new player options.
     */
    @objc public func updatePlayerOptions(_ playerOptions: PlayerOptions) {
        self.playerOptions = playerOptions
        
        self.playerOptions.pluginConfig.config.forEach { (name, config) in
            pkPlayer.updatePluginConfig(pluginName: name, config: config)
        }
    }
    
    /**
       Set the player's MediaEntry.
    
       * Parameters:
           * media: The media entry.
           * options: Additional media options. See `MediaOptions`.
    */
    @objc public func setMedia(_ media: PKMediaEntry, options: MediaOptions? = nil) {
        mediaOptions = options
        mediaEntry = media
    }
    
    /**
        Call in order to prepare the media on the player.
     
        * Note:
            When the PlayerOptions preload is set too true, this function will be called automatically.
     */
    @objc public func prepare() {
        guard let mediaEntry = self.mediaEntry else {
            PKLog.debug("MediaEntry is empty.")
            return
        }
        if !shouldPrepare { return }
        shouldPrepare = false
        // Create media config
        let mediaConfig: MediaConfig
        if let startTime = mediaOptions?.startTime, startTime != TimeInterval.nan {
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
    internal var mediaEntry: PKMediaEntry? {
        didSet {
            if mediaEntry == nil { return }
            shouldPrepare = true
            if playerOptions.autoPlay || playerOptions.preload {
                prepare()
            }
        }
    }
    
    /// The player's settings.
    @objc public var settings: PKPlayerSettings {
        get {
            return pkPlayer.settings
        }
    }
    
    /// The current media format.
    @objc public var mediaFormat: PKMediaSource.MediaFormat {
        get {
            return pkPlayer.mediaFormat
        }
    }
    
    /// The player's session id. The `sessionId` is initialized when the player loads.
    @objc public var sessionId: String {
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
    @objc public func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void) {
        pkPlayer.addObserver(observer, event: event, block: block)
    }
    
    /**
       Add an observation to relevant events.

       * Parameters:
           * observer: The object that will be the observer.
           * events: A list of `KPEvent`'s too observe.
           * block: The callback function that will be called.
    */
    @objc public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        pkPlayer.addObserver(observer, events: events, block: block)
    }
    
    /**
       Remove the observer for an event.

       * Parameters:
           * observer: The object that the observation will be removed from.
           * event: Which `KPEvent` to remove the observation from.
    */
    @objc public func removeObserver(_ observer: AnyObject, event: PKEvent.Type) {
        pkPlayer.removeObserver(observer, event: event)
    }
    
    /**
       Remove the observer from the events.

       * Parameters:
           * observer: The object that the observation will be removed from.
           * events: A list of `KPEvent`'s to remove the observation from.
    */
    @objc public func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        pkPlayer.removeObserver(observer, events: events)
    }
    
    /**
       Update a Plugin Config.

       * Parameters:
           * pluginName: The Plugin name.
           * config: The Plugin configuration object.
    */
    @objc public func updatePluginConfig(pluginName: String, config: Any) {
        playerOptions.pluginConfig.config[pluginName] = config
        pkPlayer.updatePluginConfig(pluginName: pluginName, config: config)
    }
    
    /// Updates the styling from the settings textTrackStyling object
    @objc public func updateTextTrackStyling() {
        pkPlayer.updateTextTrackStyling()
    }
    
    /**
        Indicates if current media is Live.
     
        * Returns: `true` if it's live, `false` otherwise.
     */
    @objc public func isLive() -> Bool {
        return pkPlayer.isLive()
    }
    
    /**
        Getter for a playkit controller.
     
        * Parameters:
            * type: The required `PKController` class type.
     
        * Returns: The relevant controller if exist, `nil` otherwise.
     */
    @objc public func getController(type: PKController.Type) -> PKController? {
        return pkPlayer.getController(type: type)
    }
    
    // MARK: - BasicPlayer
    
    /// The player's duration.
    @objc public var duration: TimeInterval {
        get {
            return pkPlayer.duration
        }
    }
    
    /// The player's currentState.
    @objc public var currentState: PlayerState {
        get {
            return pkPlayer.currentState
        }
    }
    
    /// Indicates if the player is playing.
    @objc public var isPlaying: Bool {
        get {
            return pkPlayer.isPlaying
        }
    }
    
    /// The current player's time.
    @objc public var currentTime: TimeInterval {
        get {
            return pkPlayer.currentTime
        }
        set {
            pkPlayer.currentTime = newValue
        }
    }
    
    /// The current program time (PROGRAM-DATE-TIME).
    @objc public var currentProgramTime: Date? {
        get {
            return pkPlayer.currentProgramTime
        }
    }
    
    /// Get the player's current audio track.
    @objc public var currentAudioTrack: String? {
        get {
            return pkPlayer.currentAudioTrack
        }
    }
    
    /// Get the player's current text track.
    @objc public var currentTextTrack: String? {
        get {
            return pkPlayer.currentTextTrack
        }
    }
    
    /**
        Indicates the desired rate of playback, 0.0 means "paused", 1.0 indicates a desire to play at the natural rate of the current item.
            
        * Important: Do not use the rate to indicate whether to play or pause! Use the isPlaying property.
     */
    @objc public var rate: Float {
        get {
            return pkPlayer.rate
        }
        set {
            pkPlayer.rate = newValue
        }
    }
    
    /// The audio playback volume for the player, ranging from 0.0 through 1.0 on a linear scale.
    @objc public var volume: Float {
        get {
            return pkPlayer.volume
        }
        set {
            pkPlayer.volume = newValue
        }
    }
    
    /// Provides a collection of time ranges for which the player has the media data readily available. The ranges provided might be discontinuous.
    @objc public var loadedTimeRanges: [PKTimeRange]? {
        get {
            return pkPlayer.loadedTimeRanges
        }
    }
    
    /// Send a play action for the player.
    @objc public func play() {
        pkPlayer.play()
    }
    
    /// Send a pause action for the player.
    @objc public func pause() {
        pkPlayer.pause()
    }
    
    /// Send a resume action for the player.
    @objc public func resume() {
        pkPlayer.resume()
    }
    
    /// Send a stop action for the player.
    @objc public func stop() {
        pkPlayer.stop()
    }
    
    /// Send a replay action for the player.
    @objc public func replay() {
        pkPlayer.replay()
    }
    
    /// Send a seek action for the player.
    @objc public func seek(to time: TimeInterval) {
        pkPlayer.seek(to: time)
    }
    
    /// Select a Track
    @objc public func selectTrack(trackId: String) {
        pkPlayer.selectTrack(trackId: trackId)
    }
    
    /// Release the player's resources.
    @objc public func destroy() {
        pkPlayer.destroy()
    }
    
    /**
        Starts buffering the entry.
     
        Call this function if the player's `settings.network.autoBuffer` is set too false. Otherwise it is done automatically.
     */
    @objc public func startBuffering() {
        pkPlayer.startBuffering()
    }
    
    internal func updateMediaEntryWithLoadedInterceptors(_ mediaEntry: PKMediaEntry, callback: @escaping (_ error: Error?) -> Void) {
        guard var interceptors = self.interceptors, !interceptors.isEmpty else {
            self.mediaEntry = mediaEntry
            callback(nil)
            return
        }
        
        func update(entry: PKMediaEntry, withInterceptor interceptor: PKMediaEntryInterceptor) {
            interceptor.apply(entry: entry) { [weak self] (error: Error?) in
                
                if let error = error {
                    // In case we get some error from Interceptor apply, we should ignore it and continue with next Interceptor.
                    PKLog.debug("MediaEntry Interceptor apply Error: \(error.localizedDescription)")
                }
                
                if interceptors.isEmpty {
                    PKLog.debug("KalturaPlayer finished with applying all interceptors for MediaEntry id: \(entry.id)")
                    self?.mediaEntry = entry
                    callback(nil)
                } else {
                    update(entry: entry, withInterceptor: interceptors.removeFirst())
                }
            }
        }
        
        update(entry: mediaEntry, withInterceptor: interceptors.removeFirst())
    }
    
}
