//
//  PKPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergii Chausov on 01.09.2021.
//

import Foundation
import PlayKit

@objc public class PKPlaylistController: NSObject, PlaylistController {
    
    public var playlist: PKPlaylist
    public weak var delegate: PlaylistControllerDelegate?
    
    internal var originalOTTMediaOptions: [OTTMediaOptions]?
    
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
    
    private var currentPlayingIndex: Int = -1
    public var recoverOnError: Bool = true
    private weak var player: KalturaPlayer?
    private var messageBus: MessageBus?
    private var entries: [PKMediaEntry]
    
    private var currentItemCoundownOptions: CountdownOptions?
    
    private var preloadingInProgressForMediasId: [String] = []
    
    
    private var shuffled: Bool = false
    private var shuffledOrder: [Int] = []
    
    required init(playlistConfig: Any?, playlist: PKPlaylist, player: KalturaPlayer) {
        self.playlist = playlist
        self.entries = playlist.medias ?? []
        self.player = player
        
        self.messageBus = player.getMessageBus()
            
        super.init()
        
        self.subscribeToPlayerEvents()
        
        self.messageBus?.post(PlaylistEvent.PlayListLoaded())
    }
    
    deinit {
        self.player?.removeObserver(self, events: KPPlayerEvent.allEventTypes)
    }
    
    func subscribeToPlayerEvents() {
        
        let playerEvents = [KPPlayerEvent.ended,
                            KPPlayerEvent.playheadUpdate,
                            KPPlayerEvent.seeking,
                            KPPlayerEvent.seeked,
                            PlayerEvent.error]
        
        self.player?.addObserver(self, events: playerEvents) { [weak self] event in
            guard let self = self,
                  let player = self.player else { return }
            
            DispatchQueue.main.async {
                switch event {
                case is KPPlayerEvent.Ended:
                    self.resetCountdown()
                    
                    if self.autoContinue {
                        if self.isNextItemAvailable() {
                            self.playNext()
                        } else {
                            if self.loop == true {
                                self.replay()
                            } else {
                                self.messageBus?.post(PlaylistEvent.PlayListEnded())
                            }
                        }
                    }
                case is KPPlayerEvent.Seeking:
                    self.seeking = true
                    
                    if let seekingTime = event.targetSeekPosition?.doubleValue {
                        if let countDownOptions = self.currentItemCoundownOptions {
                            if seekingTime > (player.duration - countDownOptions.timeToShow) {
                                self.resetCountdown()
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
                    if self.recoverOnError == true {
                        PKLog.error("Trying to play next media")
                        self.playNext()
                    }
                default: break
                    
                }
            }
        }
        
        self.player?.addObserver(self, events: [AdEvent.allAdsCompleted, AdEvent.adLoaded], block: { [weak self] event in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch event {
                case is AdEvent.AllAdsCompleted: print("All Ads ended!")
                case is AdEvent.AdLoaded: print("AD LOADED")
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
            if self.entries.count >= currentPlayingIndex + 1 {
                currentPlayingIndex += 1
            } else {
                PKLog.error("Next item is out of range")
            }
        }
        
        guard currentPlayingIndex < self.entries.count else {
            if isNextItemAvailable() {
                replay()
            }
            return
        }
        
        self.playItem(index: currentPlayingIndex)
    }
    
    public func playPrev() {
        if currentPlayingIndex == -1 {
            currentPlayingIndex = 0
        } else {
            if currentPlayingIndex > 0 {
                currentPlayingIndex -= 1
            } else {
                PKLog.error("Previous item should be 0 or higher")
            }
        }
        
        guard self.entries.indices.contains(currentPlayingIndex) else {
            PKLog.error("playItem index is out of range.")
            return
        }
        
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
        return self.entries.indices.contains(currentPlayingIndex - 1)
    }
    
    public func preloadNext() {
        if let interceptors = self.player?.interceptors, !interceptors.isEmpty {
            PKLog.error("It is not possible to pleload next playlist item with loaded interceptor plugins.")
            return
        }
        
        let preloadMediaIndex = currentPlayingIndex + 1
        guard self.entries.indices.contains(preloadMediaIndex) else {
            PKLog.error("Trere is no next media to preload.")
            return
        }
        
        self.preloadMedia(atIndex: preloadMediaIndex)
    }
    
    public func replay() {
        currentPlayingIndex = -1
        playNext()
    }
    
    public func removeItemFromPlaylist(index: Int) {
        
    }
    
    public func addItemToPlayList(index: Int, item: PKMediaEntry) {
        
    }
    
    public func resetCountdownForCurrentItem() {
        self.resetCountdown()
    }
    
    public func playItem(index: Int) {
        PKLog.debug("Play Item with index = \(index)")
        
        self.player?.stop()
        
        self.resetCountdown()
        
        guard self.entries.indices.contains(index) else {
            PKLog.error("playItem index is out of range.")
            return
        }
        
        currentPlayingIndex = index
        let currentEntry = self.entries[currentPlayingIndex]
        self.messageBus?.post(PlaylistEvent.PlayListCurrentPlayingItemChanged())
        
        if let sources = currentEntry.sources, !sources.isEmpty {
            var pluginConfig: PluginConfig? = nil
            
            if let delegate = self.delegate {
               
                if delegate.playlistController(self, needsUpdatePluginConfigForMediaItemAtIndex: self.currentPlayingIndex) == true {
                    pluginConfig = delegate.playlistController(self, pluginConfigForMediaItemAtIndex: self.currentPlayingIndex)
                }
            
                if delegate.playlistController(self, enableCountdownForMediaItemAtIndex: self.currentPlayingIndex) == true {
                    let countdown = delegate.playlistController(self, countdownOptionsForMediaItemAtIndex: self.currentPlayingIndex)
                    self.currentItemCoundownOptions = countdown
                }
            }
            
            self.player?.setMediaAndUpdatePlugins(mediaEntry: currentEntry, mediaOptions: nil, pluginConfig: pluginConfig, callback: { error in
                
            })
        } else {
            // Entry is not loaded.
            guard let loader = self.player as? EntryLoader else { return }
            
            guard let options = self.prepareMediaOptions(forMediaEntry: currentEntry) else {
                PKLog.error("Cannot create proper options to load media: \(currentEntry.description)")
                return
            }
            
            loader.loadMedia(options: options) { [weak self] (entry: PKMediaEntry?, error: NSError?) in
                guard let self = self else { return }
                
                if let error = error {
                    PKLog.error(error.description)
                    self.messageBus?.post(PlaylistEvent.PlayListLoadMediaError(nsError: error))
                    
                    if self.recoverOnError == true {
                        PKLog.error("Trying to play next media")
                        self.playNext()
                    }
                    return
                }
                
                currentEntry.sources = entry?.sources
                
                var pluginConfig: PluginConfig? = nil
                
                if let delegate = self.delegate {
                    
                    if delegate.playlistController(self, needsUpdatePluginConfigForMediaItemAtIndex: self.currentPlayingIndex) == true {
                        pluginConfig = delegate.playlistController(self, pluginConfigForMediaItemAtIndex: self.currentPlayingIndex)
                    }
                    
                    if delegate.playlistController(self, enableCountdownForMediaItemAtIndex: self.currentPlayingIndex) == true {
                        let countdown = delegate.playlistController(self, countdownOptionsForMediaItemAtIndex: self.currentPlayingIndex)
                        self.currentItemCoundownOptions = countdown
                    }
                }
                
                self.player?.setMediaAndUpdatePlugins(mediaEntry: currentEntry, mediaOptions: nil, pluginConfig: pluginConfig, callback: { error in
                    
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
    
    public func shuffle() {
        PKLog.error("Not implemented")
    }
    
    //
    
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
                
                self.preloadingInProgressForMediasId.removeAll { $0 == entry.id }
                entry.sources = loadedEntry?.sources
            }
        }
    }
    
    private func prepareMediaOptions(forMediaEntry entry: PKMediaEntry) -> MediaOptions? {
        let options: MediaOptions
        
        if self.player is KalturaOTTPlayer {
            if let ottOptions = self.originalOTTMediaOptions?.first(where: { $0.assetId == entry.id }) {
                options = ottOptions
            } else {
                PKLog.error("Media :\(entry.id) is missing in playlist OTT media options.")
                return nil
            }
        } else if self.player is KalturaOVPPlayer {
            let ovpOptions = OVPMediaOptions()
            ovpOptions.ks = self.player?.playerOptions.ks
            ovpOptions.entryId = entry.id
            options = ovpOptions
        } else {
            options = MediaOptions()
        }
        
        return options
    }
    
    private func resetCountdown() {
        self.currentItemCoundownOptions = nil
    }
    
    var seeking = false
    
    private func handlePlayheadUpdateEvent(event: KPPlayerEvent.PlayheadUpdate) {
        guard let currentTime = event.currentTime,
              let player = self.player else { return }
        
        if let countDownOptions = self.currentItemCoundownOptions {
            
            if self.seeking == true {
                return
            }
            
            // Countdown event start time should be less then playback time.
            if countDownOptions.timeToShow >= player.duration {
                self.resetCountdown()
            }
            
            if player.duration <= countDownOptions.timeToShow {
                self.resetCountdown()
                return
            }
            
            if (player.duration - currentTime.doubleValue) < countDownOptions.timeToShow {
                if countDownOptions.eventSent != true {
                    PKLog.debug("send count down event position = \(currentTime)")
                    self.messageBus?.post(PlaylistEvent.PlaylistCountDownStart())
                    countDownOptions.eventSent = true
                    self.preloadNext()
                    
                } else if (player.duration - currentTime.doubleValue) < (countDownOptions.timeToShow - countDownOptions.duration) {
                    PKLog.debug("playhead updated handlePlaylistMediaEnded");
                    self.messageBus?.post(PlaylistEvent.PlaylistCountDownEnd())
                    
                    self.resetCountdown()
                    
                    if self.autoContinue {
                        if self.isNextItemAvailable() {
                            self.playNext()
                        } else {
                            if self.loop == true {
                                self.replay()
                            } else {
                                self.messageBus?.post(PlaylistEvent.PlayListEnded())
                            }
                        }
                    }
                }
            }
            
        } else {
            if (player.duration - currentTime.doubleValue) < self.preloadTime {
                self.preloadNext()
            }
        }
    }
    
}
