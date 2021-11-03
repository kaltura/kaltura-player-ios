//
//  PKPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergii Chausov on 01.09.2021.
//

import Foundation
import PlayKit

@objc public class PKPlaylistController: NSObject, PlaylistController {
    
    public var currentMediaIndex: Int {
        return currentPlayingIndex
    }
    
    public var loop: Bool = false
    public var autoContinue: Bool = true
    private var currentPlayingIndex: Int = -1
    private var recoverOnError: Bool = true
    
    public var playlist: PKPlaylist
    private weak var player: KalturaPlayer?
    
    // private var playlistType: PKPlaylistType
    // private var playlistOptions: PlaylistOptions
    // private var playlistCountDownOptions: CountDownOptions
    
    // TODO: remove originalPlaylistEntries and use self.playlist.medias instead
    private let originalPlaylistEntries: [PKMediaEntry]
    private var entries: [PKMediaEntry]
    
    // private var loadedMediasMap: (String, PKMediaEntry)
    private var preloadingInProgressForMediasId: [String] = []
    
    required init(playlistConfig: Any?, playlist: PKPlaylist, player: KalturaPlayer) {
        self.originalPlaylistEntries = playlist.medias ?? []
        self.loop = true
        self.playlist = playlist
        self.entries = originalPlaylistEntries
        self.player = player
        
        super.init()
        
        self.subscribeToPlayerEvents()
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
                            }
                        }
                    }
                case is KPPlayerEvent.PlayheadUpdate:
                    guard let currentTime = event.currentTime,
                          let player = self.player else { return }
                    
                    let preloadTime: TimeInterval = 20
                    
                    if (player.duration - currentTime.doubleValue) < preloadTime {
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
        
        guard currentPlayingIndex < self.entries.count else {
            // handle error
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
        let preloadMediaIndex = currentPlayingIndex + 1
        guard self.entries.indices.contains(preloadMediaIndex) else {
            // TODO: Handle error
            return
        }
        
        self.preloadMedia(atIndex: preloadMediaIndex)
    }
    
    private func preloadMedia(atIndex index: Int) {
        let entry = self.entries[index]
        guard self.preloadingInProgressForMediasId.contains(entry.id) == false else {
            // TODO: Handle error
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
        PKLog.debug("playItem index = \(index)")
        self.player?.stop()
        guard self.entries.indices.contains(index) else {
            // TODO: Handle error
            return
        }
        
        currentPlayingIndex = index
        
        let currentEntry = self.entries[currentPlayingIndex]
        
        if let sources = currentEntry.sources, !sources.isEmpty {
            self.player?.mediaEntry = currentEntry
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
                currentEntry.sources = entry?.sources
                
                self?.player?.mediaEntry = currentEntry
                
//                self?.player?.post(event: PlayerEvent.Playing())
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
        //log("reset");
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
