//
//  KalturaBasicPlayerManager.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/27/20.
//

import Foundation

public class KalturaBasicPlayerManager: KalturaPlayerManager {

    public static let shared = KalturaBasicPlayerManager()

    private override init() {
        super.init()
    }
    
    /**
        Set up the Kaltura Player.

        The setup will register any Kaltura's plugin which will be added in the pod file.
        
        Curently supporting PlayKit_IMA pod.
     */
    public static func setup() {
        // This needs to be done in order for it to be initialized.
        let _ = KalturaBasicPlayerManager.shared
    }
}
