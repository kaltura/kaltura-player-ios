//
//  PlaylistController.swift
//  PlayKitProviders
//
//  Created by Sergii Chausov on 01.09.2021.
//

import Foundation
import PlayKit

@objc public protocol PlaylistController {
    
    /// The object that acts as the delegate of the PlaylistController.
    /// As a delegate you may provide plugins config for each item of the playlist.
    /// Also provide a CountdownOptions for individual items.
    weak var delegate: PlaylistControllerDelegate? { get set }
    
    /// Loaded playlist.
    var playlist: PKPlaylist { get }
    
    /// Will set next media to players' playback
    func playNext()
    
    /// Will set previous media to players' playback
    func playPrev()
    
    /// Run Get Playback Context request for next media in the list.
    /// You are able to call this function with your own business logic.
    /// Or this function will be called automatically according to preloadTime.
    func preloadNext()
    
    /// Time interval that manage time in seconds when next media will be preloaded before current media ends.
    /// It counts backwards (from the end of media playback), so set the time you need to preload in seconds before current media ends.
    /// Set it once, it will be applied to each media.
    /// Default value is 10 seconds before media playback ends.
    var preloadTime: TimeInterval { get set }
    
    /**
     Play playlist item at index.
     
     * Parameters:
        * index: The index of media item you would like to play.
     */
    func playItem(index: Int)
    
    /**
     Shows if the media at index contains media sources and is ready to be played.
     
     * Parameters:
        * index: The index of media item.
     */
    func isMediaLoaded(index: Int) -> Bool
    
    /// Reset to default given configuration
    func reset()
    
    /// Start playlist from index 0
    func replay()
    
    /// Set this parameter to true if you need to play the list from the very beginning after last item ends.
    /// Default value is false.
    var loop: Bool { get set }
    
    /// Continue to the next media item after current one ends.
    /// Default value is true.
    var autoContinue: Bool { get set }
    
    /// Skipping (or not) countdown if post-roll available.
    /// By default if countdown options added it will start at the defined time and post-roll will be ignored.
    /// If playlist controller configured with this parameter countdown options will be ignored in case we have post-roll for that media.
    var skipCountdownForPostRoll: Bool { get set }
    
    /// Play next item if current cannot be loaded or any playback error occurred.
    /// Default value is true.
    var recoverOnError: Bool { get set }
    
    /// Index of currently playing media.
    var currentMediaIndex: Int { get }
    
    /// Disables coundown action for current media
    func disableCountdownForCurrentItem()
    
    /// Checks if the previous item in the list is available for playback.
    /// If loop is true isPreviousItemAvailable() will always return true.
    func isPreviousItemAvailable() -> Bool
    
    /// Checks if the next item in the list is available for playback.
    /// If loop is true isNextItemAvailable() will always return true.
    func isNextItemAvailable() -> Bool
}

@objc public protocol PlaylistControllerDelegate: AnyObject {
    
    /**
     Individual media items can opt out of having the dedicated plugin config for each media item.
     
     * Parameters:
        * controller: The PlaylistController which is managing current medias list playback.
        * mediaEntry: The PKMediaEntry.
        * mediaItemIndex: The index of media item.
     * Returns: A flag if it is needed to set dedicated plugins config to item with requested index.
     */
    func playlistController(_ controller: PlaylistController, updatePluginConfigForMediaEntry mediaEntry: PKMediaEntry, atIndex mediaItemIndex: Int) -> Bool
    
    /**
     Individual media items can opt out of having the dedicated plugin config for each media item.
     This method will be called only if playlistController(: updatePluginConfigForMediaItemAtIndex:) returns true.
     
     * Parameters:
        * controller: The PlaylistController which is managing current medias list playback.
        * mediaEntry: The PKMediaEntry.
        * mediaItemIndex: The index of media item.
     * Returns: A plugins config which will be applied to item with requested index.
     In case it returns nil default plugins config will be applied for the media at requested index.
     */
    func playlistController(_ controller: PlaylistController, pluginConfigForMediaEntry mediaEntry: PKMediaEntry, atIndex mediaItemIndex: Int) -> PluginConfig?
    
    /**
     Individual media items can opt out of having the countdown options applied to their playback.
     
     * Parameters:
        * controller: The PlaylistController which is managing current medias list playback.
        * mediaEntry: The PKMediaEntry.
        * mediaItemIndex: The index of media item.
     * Returns: A flag if it is needed to apply countdown options to item with requested index.
     */
    func playlistController(_ controller: PlaylistController, enableCountdownForMediaEntry mediaEntry: PKMediaEntry, atIndex mediaItemIndex: Int) -> Bool
    
    /**
     Individual media items can opt out of having the countdown options applied to their playback.
     This method will be called only if playlistController(: enableCountdownForMediaItemAtIndex:) returns true.
     
     * Parameters:
        * controller: The PlaylistController which is managing current medias list playback.
        * mediaEntry: The PKMediaEntry.
        * mediaItemIndex: The index of media item.
     * Returns: A specific countdown options which will be applied to item with requested index.
     Set nil to skip countdown options for the media at requested index.
     */
    func playlistController(_ controller: PlaylistController, countdownOptionsForMediaEntry mediaEntry: PKMediaEntry, atIndex mediaItemIndex: Int) -> CountdownOptions?
}

public protocol EntryLoader {
    
    func loadMedia(options: MediaOptions, callback: @escaping (_ entry: PKMediaEntry?, _ error: NSError?) -> Void)
}
