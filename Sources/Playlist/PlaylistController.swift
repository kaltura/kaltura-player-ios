//
//  PlaylistController.swift
//  PlayKitProviders
//
//  Created by Sergii Chausov on 01.09.2021.
//

import Foundation
import PlayKit

public protocol PlaylistController {
    
    func playNext()
    
    func playPrev()
    
    func removeItemFromPlaylist(index: Int)
    
    func addItemToPlayList(index: Int, item: PKMediaEntry)
    
    func playItem(index: Int)
    
    func isMediaLoaded(index: Int) -> Bool
    
    /// Reset to default given  configuration
    func reset()
    /// Start playlist from index 0
    func replay()
    
    /// Will shuffle the playlist and save the orig list for reset
    func shuffle()
    
    var loop: Bool { get set }
    
    var autoContinue: Bool { get set }
}
