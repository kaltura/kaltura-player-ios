// ===================================================================================================
// Copyright (C) 2022 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import XCTest
import KalturaPlayer
import CoreMedia

class PlayerControllerTest: XCTestCase {
    
    var player: KalturaPlayer!
    
    override func setUp() {
        super.setUp()
        self.player = self.createPlayer()
    }
    
    override func tearDown() {
        super.tearDown()
        self.destroyPlayer(player)
    }
    
    func testPlayCommand() {
        let asyncExpectation = expectation(description: "play command")
        self.player.play();
        self.player.addObserver(self, events: [KPPlayerEvent.playing]) { event in
            if type(of: event) == KPPlayerEvent.playing {
                asyncExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPauseCommand() {
        let asyncExpectation = expectation(description: "pause command")
        self.player.play();
        self.player.addObserver(self, events: [KPPlayerEvent.pause]) { event in
            if type(of: event) == KPPlayerEvent.pause {
                asyncExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        self.player.addObserver(self, events: [KPPlayerEvent.playing]) { [weak self] event in
            self?.player.pause()
        }
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testIsPlayingValue() {
        let asyncExpectation = expectation(description: "play command")
        self.player.play();
        self.player.addObserver(self, events: [KPPlayerEvent.playing, KPPlayerEvent.pause]) { event in
            
            if type(of: event) == KPPlayerEvent.playing {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    XCTFail()
                }
            } else if type(of: event) == KPPlayerEvent.pause {
                if !self.player.isPlaying {
                    asyncExpectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    /// Test a guard mechanism that prevents receiving pause events after ended event.
    ///
    /// ## The Flow:
    /// 1. play the video.
    /// 2. seek to 2 seconds before the end.
    /// 3. on ended event pause the player.
    ///
    /// **expected result:** shouldn't receive the pause event and expectation should be fullfilled.
    func testEnded() {
        let asyncExpectation = expectation(description: "ended event")
        var isEnded = false
        var isFirstPlay = true
        
        self.player.addObserver(self, events: [KPPlayerEvent.ended]) { info in
            print("ended")
            isEnded = true
            self.player.pause()
        }
        self.player.addObserver(self, events: [KPPlayerEvent.playing, KPPlayerEvent.pause]) { event in
            if type(of: event) == KPPlayerEvent.playing && isFirstPlay && self.player.isPlaying {
                isFirstPlay = false
                // seek to end - 1 second
                self.player.seek(to: self.player.duration - 2)
            }
            // should not fire play/pause after ended
            if isEnded {
                XCTFail()
            }
        }
        player.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    /// Test to make sure pause/play events are received after ended + seeked event.
    ///
    /// ## The Flow:
    /// 1. play the video.
    /// 2. seek to 2 seconds before the end.
    /// 3. on ended event seek again to 2 seconds before the end.
    /// 4. play again
    ///
    /// **expected result:** receive play event after ended + seeked
    func testAnalyticsEndedSeekedPlayed() {
        let asyncExpectation = expectation(description: "ended -> seek -> play events")
        var isEnded = false
        var isFirstPlay = true
        var isSeekedAfterEnded = false
        
        player.addObserver(self, events: [KPPlayerEvent.ended]) { info in
            print("ended")
            isEnded = true
            self.player.seek(to: self.player.duration - 2)
        }
        player.addObserver(self, events: [KPPlayerEvent.playing, KPPlayerEvent.pause]) { event in
            if type(of: event) == KPPlayerEvent.playing && isFirstPlay && self.player.isPlaying {
                isFirstPlay = false
                // seek to end - 2 second
                self.player.seek(to: self.player.duration - 2)
            }
            // should fire play/pause after ended + seeked
            if isSeekedAfterEnded {
                asyncExpectation.fulfill()
            }
        }
        player.addObserver(self, events: [KPPlayerEvent.seeked]) { info in
            if isEnded {
                isSeekedAfterEnded = true
                self.player.play()
            }
        }
        player.play()
        
        waitForExpectations(timeout: 20, handler: nil)
    }

}
