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
    private var recoverOnError: Bool = true
    private weak var player: KalturaPlayer?
    private var messageBus: MessageBus?
    private var entries: [PKMediaEntry]
    
    private var preloadingInProgressForMediasId: [String] = []
    
    required init(playlistConfig: Any?, playlist: PKPlaylist, player: KalturaPlayer) {
        self.loop = true
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
        self.player?.addObserver(self, events: [KPPlayerEvent.ended, KPPlayerEvent.playheadUpdate]) { [weak self] event in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch event {
                case is KPPlayerEvent.Ended:
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
                case is KPPlayerEvent.PlayheadUpdate:
                    guard let currentTime = event.currentTime,
                          let player = self.player else { return }
                    
                    if (player.duration - currentTime.doubleValue) < self.preloadTime {
                        self.preloadNext()
                    }
                default: break
                    
                }
            }
        }
    }
    
    // MARK: - PlaylistController
    
    public func playNext() {
        if currentPlayingIndex == -1 {
            currentPlayingIndex = 0
        } else {
            currentPlayingIndex += 1
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
            currentPlayingIndex -= 1
        }
        
        guard self.entries.indices.contains(currentPlayingIndex) else {
            PKLog.error("playItem index is out of range.")
            return
        }
        
        self.playItem(index: currentPlayingIndex)
    }
    
    public func isNextItemAvailable() -> Bool {
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
    
    private func preloadMedia(atIndex index: Int) {
        let entry = self.entries[index]
        guard self.preloadingInProgressForMediasId.contains(entry.id) == false else {
            PKLog.error("Media :\(entry.id) is loading already.")
            return
        }
        
        if !self.isMediaLoaded(index: index) {
            guard let loader = self.player as? EntryLoader else { return }
            
            self.preloadingInProgressForMediasId.append(entry.id)
            
            let options: OVPMediaOptions = OVPMediaOptions()
            options.ks = self.player?.playerOptions.ks
            options.entryId = entry.id
            
            loader.loadMedia(options: options) { [weak self] (loadedEntry: PKMediaEntry?, error: NSError?) in
                guard let self = self else { return }
                
                self.preloadingInProgressForMediasId.removeAll { $0 == entry.id }
                entry.sources = loadedEntry?.sources
            }
        }
    }
    
    public func replay() {
        currentPlayingIndex = -1
        playNext()
    }
    
    public func removeItemFromPlaylist(index: Int) {
        
    }
    
    public func addItemToPlayList(index: Int, item: PKMediaEntry) {
        
    }
    
    public func playItem(index: Int) {
        PKLog.debug("Play Item with index = \(index)")
        self.player?.stop()
        guard self.entries.indices.contains(index) else {
            PKLog.error("playItem index is out of range.")
            return
        }
        
        currentPlayingIndex = index
        
        let currentEntry = self.entries[currentPlayingIndex]
        
        self.messageBus?.post(PlaylistEvent.PlayListCurrentPlayingItemChanged())
        
        if let sources = currentEntry.sources, !sources.isEmpty {
            var pluginConfig: PluginConfig? = nil
            
            if let delegate = self.delegate,
               delegate.playlistController(self, needsUpdatePluginConfigForMediaItemAtIndex: self.currentPlayingIndex) == true {
                pluginConfig = delegate.playlistController(self, pluginConfigForMediaItemAtIndex: self.currentPlayingIndex)
            }
            
            self.player?.setMediaAndUpdatePlugins(mediaEntry: currentEntry, mediaOptions: nil, pluginConfig: pluginConfig, callback: { error in
                
            })
        } else {
            // Entry is not loaded.
            
            guard let loader = self.player as? EntryLoader else {
                return
            }
            
            let options: MediaOptions
            
            if self.player is KalturaOTTPlayer {
                let ottOptions = OTTMediaOptions()
                ottOptions.ks = self.player?.playerOptions.ks
                ottOptions.assetId = currentEntry.id
                options = ottOptions
            } else if self.player is KalturaOVPPlayer {
                let ovpOptions = OVPMediaOptions()
                ovpOptions.ks = self.player?.playerOptions.ks
                ovpOptions.entryId = currentEntry.id
                options = ovpOptions
            } else {
                options = MediaOptions()
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
                
                if let delegate = self.delegate,
                   delegate.playlistController(self, needsUpdatePluginConfigForMediaItemAtIndex: self.currentPlayingIndex) == true {
                    pluginConfig = delegate.playlistController(self, pluginConfigForMediaItemAtIndex: self.currentPlayingIndex)
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
        
        entries.removeAll()
        entries = playlist.medias ?? []
    }
    
    public func shuffle() {
        self.player?.stop()
        self.entries.shuffle()
        currentPlayingIndex = -1
    }
    
}
