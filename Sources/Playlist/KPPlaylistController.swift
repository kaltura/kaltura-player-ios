//
//  PKPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergii Chausov on 01.09.2021.
//

import Foundation
import PlayKit

@objc public class KPPlaylistController: NSObject, PlaylistController {
    
    public weak var delegate: PlaylistControllerDelegate?
    
    public var playlist: PKPlaylist
    public var recoverOnError: Bool = true
    public var preloadTime: TimeInterval = 10
    public var currentMediaIndex: Int {
        return currentPlayingIndex
    }
    public var loop: Bool = false {
        didSet {
            self.messageBus?.post(PlaylistEvent.PlaylistLoopStateChanged())
        }
    }
    public var autoContinue: Bool = true {
        didSet {
            self.messageBus?.post(PlaylistEvent.PlaylistAutoContinueStateChanged())
        }
    }
    
    internal weak var player: KalturaPlayer?
    private var entries: [PKMediaEntry]
    private var currentPlayingIndex: Int = -1
    private var messageBus: MessageBus?
    private var currentItemCountdownOptions: CountdownOptions?
    private var preloadingInProgressForMediasId: [String] = []
    private var shuffled: Bool = false
    private var shuffledOrder: [Int] = []
    
    enum PlaylistNavigationDirection {
        case forward
        case backward
    }
    
    private var navigationDirection: PlaylistNavigationDirection = .forward
    
    required init(playlistConfig: Any?, playlist: PKPlaylist, player: KalturaPlayer) {
        self.playlist = playlist
        self.entries = playlist.medias ?? []
        self.player = player
        
        self.messageBus = player.getMessageBus()
            
        super.init()
        
        self.subscribeToPlayerEvents()
        
        self.messageBus?.post(PlaylistEvent.PlaylistLoaded())
    }
    
    deinit {
        self.player?.removeObserver(self, events: KPPlayerEvent.allEventTypes)
    }
    
    private var allAdsFinished: Bool = true
    private var playbackEnded: Bool = false
    
    func subscribeToPlayerEvents() {
        
        func continueWithNextMediaIfNeeded() {
            
            if self.autoContinue && self.allAdsFinished {
                if self.isNextItemAvailable() {
                    self.playNext()
                } else {
                    if self.loop == true {
                        self.replay()
                    } else {
                        self.messageBus?.post(PlaylistEvent.PlaylistEnded())
                    }
                }
            }
        }
        
        let playerEvents = [KPPlayerEvent.ended,
                            KPPlayerEvent.playheadUpdate,
                            KPPlayerEvent.seeking,
                            KPPlayerEvent.seeked,
                            KPPlayerEvent.error]
        
        self.player?.addObserver(self, events: playerEvents) { [weak self] event in
            guard let self = self,
                  let player = self.player else { return }
            
            DispatchQueue.main.async {
                switch event {
                case is KPPlayerEvent.Ended:
                    self.resetCountdown()
                    self.playbackEnded = true
                    continueWithNextMediaIfNeeded()
                case is KPPlayerEvent.Seeking:
                    self.seeking = true
                    if let seekingTime = event.targetSeekPosition?.doubleValue {
                        if let countdownOptions = self.currentItemCountdownOptions {
                            if seekingTime > (player.duration - countdownOptions.timeToShow) {
                                self.resetCountdown()
                            } else {
                                self.cancelCountdownIfNeeded()
                            }
                        }
                    }
                    
                case is KPPlayerEvent.Seeked:
                    self.seeking = false
                case is KPPlayerEvent.PlayheadUpdate:
                    if let event = event as? KPPlayerEvent.PlayheadUpdate {
                        self.handlePlayheadUpdateEvent(event: event)
                    }
                case is PlayerEvent.Error:
                    PKLog.error("Failed with playing playlist item: \(self.currentPlayingIndex)")
                    PKLog.error(event.error?.description)
                    
                    if let error = event.error {
                        let currentEntry = self.entries[self.currentPlayingIndex]
                        self.messageBus?.post(PlaylistEvent.PlaylistLoadMediaError(entryId: currentEntry.id, nsError: error))
                    }
                    
                    if self.recoverOnError {
                        self.recoverPlayback()
                    }
                default: break
                    
                }
            }
        }
        
        self.player?.addObserver(self, events: [AdEvent.allAdsCompleted, AdEvent.adLoaded], block: { [weak self] event in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch event {
                case is AdEvent.AllAdsCompleted:
                    self.allAdsFinished = true
                    if self.playbackEnded {
                        continueWithNextMediaIfNeeded()
                    }
                case is AdEvent.AdLoaded:
                    self.allAdsFinished = false
                default: break
                }
            }
        })
        
    }
    
    // MARK: - PlaylistController. Public
    
    public func playNext() {
        if currentPlayingIndex == -1 {
            currentPlayingIndex = 0
        } else {
            if self.entries.indices.contains(currentPlayingIndex + 1) {
                currentPlayingIndex += 1
            } else {
                PKLog.error("Next item is out of range")
                
                // Try to replay playlist or show ended event if next item index higher or equal to number of entries.
                if isNextItemAvailable() {
                    replay()
                } else {
                    self.messageBus?.post(PlaylistEvent.PlaylistEnded())
                }
                return
            }
        }
        
        self.navigationDirection = .forward
        self.playItem(index: currentPlayingIndex)
    }
    
    public func playPrev() {
        if currentPlayingIndex == -1 {
            currentPlayingIndex = 0
        } else {
            if currentPlayingIndex > 0 {
                currentPlayingIndex -= 1
            } else {
                if loop == true {
                    currentPlayingIndex = self.entries.endIndex - 1
                } else {
                    PKLog.error("Previous item should be 0 or higher")
                    return
                }
            }
        }
        
        self.navigationDirection = .backward
        self.playItem(index: currentPlayingIndex)
    }
    
    public func isNextItemAvailable() -> Bool {
        if loop == true {
            return true
        }
        
        let nextItemIndex = currentPlayingIndex + 1
        if loop == true && self.entries.count == nextItemIndex {
            return true
        }
        
        return self.entries.indices.contains(nextItemIndex)
    }
    
    public func isPreviousItemAvailable() -> Bool {
        if loop == true {
            return true
        }
        
        return self.entries.indices.contains(currentPlayingIndex - 1)
    }
    
    public func preloadNext() {
        if let interceptors = self.player?.interceptors, !interceptors.isEmpty {
            PKLog.error("It is not possible to pleload next playlist item with loaded interceptor plugins.")
            return
        }
        
        let preloadMediaIndex = currentPlayingIndex + 1
        guard self.entries.indices.contains(preloadMediaIndex) else {
            PKLog.error("There is no next media to preload.")
            return
        }
        
        self.preloadMedia(atIndex: preloadMediaIndex)
    }
    
    public func replay() {
        currentPlayingIndex = -1
        playNext()
    }
    
    /*
    public func removeItemFromPlaylist(index: Int) {
        
    }
    */
    
    /*
    public func addItemToPlayList(index: Int, item: PKMediaEntry) {
        
    }
    */
    
    public func disableCountdownForCurrentItem() {
        self.resetCountdown()
    }
    
    public func playItem(index: Int) {
        guard self.entries.indices.contains(index) else {
            PKLog.error("playItem index is out of range.")
            return
        }
        
        PKLog.debug("Play Item with index = \(index)")
        
        self.player?.stop()
        self.resetCountdown()
        self.allAdsFinished = true
        self.playbackEnded = false
        
        currentPlayingIndex = index
        let currentEntry = self.entries[currentPlayingIndex]
        
        if let sources = currentEntry.sources, !sources.isEmpty {
            var pluginConfig: PluginConfig? = nil
            
            if let delegate = self.delegate {
               
                if delegate.playlistController(self, updatePluginConfigForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex) == true {
                    pluginConfig = delegate.playlistController(self, pluginConfigForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex)
                }
                
                if delegate.playlistController(self, enableCountdownForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex) == true {
                    let countdown = delegate.playlistController(self, countdownOptionsForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex)
                    self.currentItemCountdownOptions = countdown
                }
            }
            
            self.player?.setMediaAndUpdatePlugins(mediaEntry: currentEntry, mediaOptions: nil, pluginConfig: pluginConfig, callback: { error in
                self.messageBus?.post(PlaylistEvent.PlaylistCurrentPlayingItemChanged())
            })
        } else {
            // Entry is not loaded.
            guard let loader = self.player as? EntryLoader else { return }
            
            guard let options = self.prepareMediaOptions(forMediaEntry: currentEntry) else {
                PKLog.error("Cannot create proper options to load media: \(currentEntry.description)")
                if self.recoverOnError {
                    self.recoverPlayback()
                }
                return
            }
            
            loader.loadMedia(options: options) { [weak self] (entry: PKMediaEntry?, error: NSError?) in
                guard let self = self else { return }
                
                if let error = error {
                    PKLog.error("Failed with playing playlist item: \(self.currentPlayingIndex)")
                    PKLog.error(error.description)
                    self.messageBus?.post(PlaylistEvent.PlaylistLoadMediaError(entryId: currentEntry.id, nsError: error))
                    
                    if self.recoverOnError {
                        self.recoverPlayback()
                    }
                    return
                }
                
                currentEntry.sources = entry?.sources
                
                var pluginConfig: PluginConfig? = nil
                
                if let delegate = self.delegate {
                    
                    if delegate.playlistController(self, updatePluginConfigForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex) == true {
                        pluginConfig = delegate.playlistController(self, pluginConfigForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex)
                    }
                    
                    if delegate.playlistController(self, enableCountdownForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex) == true {
                        let countdown = delegate.playlistController(self, countdownOptionsForMediaEntry: currentEntry, atIndex: self.currentPlayingIndex)
                        self.currentItemCountdownOptions = countdown
                    }
                }
                
                self.player?.setMediaAndUpdatePlugins(mediaEntry: currentEntry, mediaOptions: nil, pluginConfig: pluginConfig, callback: { error in
                    self.messageBus?.post(PlaylistEvent.PlaylistCurrentPlayingItemChanged())
                })
            }
        }
    }
    
    public func isMediaLoaded(index: Int) -> Bool {
        let entry = self.entries[index]
        if let sources = entry.sources, !sources.isEmpty {
            return true
        }
        return false
    }
    
    public func reset() {
        currentPlayingIndex = -1
        loop = false
        autoContinue = true
        recoverOnError = true
        shuffled = false
        
        entries.removeAll()
        entries = playlist.medias ?? []
        self.resetCountdown()
    }
    
    func shuffle() {
        PKLog.error("Not implemented")
    }
    
    // MARK: - PlaylistController. Private
    
    private func preloadMedia(atIndex index: Int) {
        let entry = self.entries[index]
        
        guard self.preloadingInProgressForMediasId.contains(entry.id) == false else {
            PKLog.error("Media :\(entry.id) is loading already.")
            return
        }
        
        if !self.isMediaLoaded(index: index) {
            guard let loader = self.player as? EntryLoader else { return }
            guard let options = self.prepareMediaOptions(forMediaEntry: entry) else {
                PKLog.error("Cannot create proper options to load media: \(entry.description)")
                return
            }
            
            self.preloadingInProgressForMediasId.append(entry.id)
            
            loader.loadMedia(options: options) { [weak self] (loadedEntry: PKMediaEntry?, error: NSError?) in
                guard let self = self else { return }
                
                if let error = error {
                    PKLog.error("Media entry preloading failed with Error: \(error.localizedDescription)")
                    return
                }
                
                self.preloadingInProgressForMediasId.removeAll { $0 == entry.id }
                entry.sources = loadedEntry?.sources
            }
        }
    }
    
    internal func prepareMediaOptions(forMediaEntry entry: PKMediaEntry) -> MediaOptions? {
        return MediaOptions()
    }
    
    private func resetCountdown() {
        cancelCountdownIfNeeded()
        self.currentItemCountdownOptions = nil
    }
    
    private func cancelCountdownIfNeeded() {
        guard let countdownOptions = currentItemCountdownOptions else { return }
        if countdownOptions.startEventSent.0 {
            PKLog.debug("Send PlaylistCountdownEnd event, canceled");
            messageBus?.post(PlaylistEvent.PlaylistCountdownEnd())
            countdownOptions.startEventSent = (false, nil)
        }
    }
    
    var seeking = false
    
    private func handlePlayheadUpdateEvent(event: KPPlayerEvent.PlayheadUpdate) {
        guard let currentTime = event.currentTime,
              let player = self.player else { return }
        
        if let countdownOptions = self.currentItemCountdownOptions {
            
            // Countdown should work only with autoContinue enabled.
            if !self.autoContinue {
                cancelCountdownIfNeeded()
                return
            }
            
            // Countdown Events disabled while seeking.
            if self.seeking {
                return
            }
            
            // Countdown event start time should be less then playback time.
            if countdownOptions.timeToShow >= player.duration {
                self.resetCountdown()
                return
            }
            
            let timeLeft = player.duration - currentTime.doubleValue
            if timeLeft <= countdownOptions.timeToShow {
                if countdownOptions.startEventSent.0 == false {
                    if timeLeft >= countdownOptions.duration {
                        PKLog.debug("Send PlaylistCountdownStart event, position = \(currentTime)")
                        self.messageBus?.post(PlaylistEvent.PlaylistCountdownStart(countDownDuration: countdownOptions.duration))
                        countdownOptions.startEventSent = (true, currentTime)
                        self.preloadNext()
                    }
                } else if let startEventSentAtTime = countdownOptions.startEventSent.atTime,
                            (currentTime.doubleValue - startEventSentAtTime.doubleValue) >= countdownOptions.duration {
                    PKLog.debug("Send PlaylistCountdownEnd event, position = \(currentTime)");
                    self.messageBus?.post(PlaylistEvent.PlaylistCountdownEnd())
                    countdownOptions.startEventSent = (false, nil)
                    self.resetCountdown()
                    self.playNext()
                }
            }
        } else {
            if (player.duration - currentTime.doubleValue) < self.preloadTime {
                self.preloadNext()
            }
        }
    }
    
    private func recoverPlayback() {
        switch self.navigationDirection {
        case .backward:
            PKLog.error("Trying to play previous media")
            self.playPrev()
        default:
            PKLog.error("Trying to play next media")
            self.playNext()
        }
    }
}
