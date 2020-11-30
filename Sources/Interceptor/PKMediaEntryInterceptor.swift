//
//  PKMediaEntryInterceptor.swift
//  KalturaPlayer
//
//  Created by Sergii Chausov on 17.11.2020.
//

import Foundation
import PlayKit

/// Main interface that MediaEntry Interceptor Plugin should adopt.
@objc public protocol PKMediaEntryInterceptor: class {
     /**
        The interceptor will receive a `PKMediaEntry` and perform the necessary changes to it.
        Consider making this method performing all logic in concurrent thread, if this logic is time consuming.
     
        * Parameters:
            * mediaEntry: The media entry to change.
     */
    @objc func apply(on mediaEntry: PKMediaEntry, completion: @escaping () -> Void)
}
