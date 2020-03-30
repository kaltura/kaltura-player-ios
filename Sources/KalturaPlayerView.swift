//
//  KalturaPlayerView.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 2/10/20.
//

import UIKit
import PlayKit

public class KalturaPlayerView: UIView {
    
    var playerView: PlayerView? {
        didSet {
            playerView?.add(toContainer: self)
            playerView?.contentMode = self.contentMode
        }
    }
    
    public override var contentMode: UIView.ContentMode {
        didSet {
            playerView?.contentMode = self.contentMode
        }
    }
}
