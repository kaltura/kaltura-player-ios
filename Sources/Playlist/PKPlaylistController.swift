//
//  PKPlaylistController.swift
//  KalturaPlayer
//
//  Created by Sergii Chausov on 01.09.2021.
//

import Foundation
import PlayKit

@objc public class PKPlaylistController: NSObject, PlaylistController {
    
    public var loop: Bool
    public var autoContinue: Bool = true
    
    public var playlist: PKPlaylist
    
    //
    //
    private weak var player: KalturaPlayer? {
        didSet {
            self.subscribeToPlayerEvents()
        }
    }
    private var currentPlayingIndex: Int = -1
    private var recoverOnError: Bool = true
    // private var playlistType: PKPlaylistType
    // private var playlistOptions: PlaylistOptions
    // private var playlistCountDownOptions: CountDownOptions
    
    private let origlPlaylistEntries: [PKMediaEntry]
    private var entries: [PKMediaEntry]
    
    // private var loadedMediasMap: (String, PKMediaEntry)
    
    required init(playlistConfig: Any?, playlist: PKPlaylist, player: KalturaPlayer) {
        self.playlist = playlist
        self.origlPlaylistEntries = playlist.medias ?? []
        self.entries = origlPlaylistEntries
        self.loop = true
        self.player = player
    }
    
    func subscribeToPlayerEvents() {
        
    }
    
    // MARK: - PlaylistController
    
    public func playNext() {
        if currentPlayingIndex == -1 {
            currentPlayingIndex = 0
        } else {
            currentPlayingIndex += 1
        }
        
        guard currentPlayingIndex < self.entries.count else {
            // handle error
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
    
    public func replay() {
        currentPlayingIndex = -1
        playNext()
    }
    
    public func removeItemFromPlaylist(index: Int) {
        
    }
    
    public func addItemToPlayList(index: Int, item: PKMediaEntry) {
        
    }
    
    public func playItem(index: Int) {
        // TODO: add check if index out of range
        currentPlayingIndex = index
        
        let currentEntry = self.entries[currentPlayingIndex]
        
        if let sources = currentEntry.sources, !sources.isEmpty {
            self.player?.mediaEntry = currentEntry
        } else {
            // Entry is not loaded.
            
            guard let loader = self.player as? EntryLoader else {
                return
            }
            
            let options: OVPMediaOptions = OVPMediaOptions()
            options.ks = self.player?.playerOptions.ks
            options.entryId = currentEntry.id
            
            loader.loadMedia(options: options) { (entry: PKMediaEntry?, error: NSError?) in
                currentEntry.sources = entry?.sources
                
                self.player?.mediaEntry = currentEntry
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
        
    }
    
    public func shuffle() {
        
    }
    
}
