//
//  UIManager.swift
//  KalturaPlayer
//
//  Created by Vadik on 23/11/2017.
//

import Foundation
import PlayKit

public class DefaultKalturaUIMananger: KalturaPlayerUIManager {
    public init() {
        
    }
    
    public func addControlsView(to player: Player) {
        let controlsView = ControlsView(player: player)
        if let view = player.view {
            view.addSubview(controlsView)
            controlsView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: controlsView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))
        }
    }
}
