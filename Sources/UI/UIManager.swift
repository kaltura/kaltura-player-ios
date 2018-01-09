// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import PlayKit

public class DefaultKalturaUIMananger: KalturaPlayerUIManager, ControlsViewDelegate {
    
    weak var delegate: KalturaPlayerUIManagerDelegate?
    
    public init() {
        
    }
    
    public func addControlsView(to player: Player, delegate: KalturaPlayerUIManagerDelegate) {
        self.delegate = delegate
        
        let controlsView = ControlsView(player: player)
        controlsView.delegate = self
        
        if let view = player.view {
            view.addSubview(controlsView)
            controlsView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))
        }
    }

    func controlsViewDidRequestPlayWithoutMediaEntry(_ controlsView: ControlsView) {
        delegate?.kalturaPlayerUIManagerDidRequestPlayWithoutMediaEntry(self)
    }
    
}
