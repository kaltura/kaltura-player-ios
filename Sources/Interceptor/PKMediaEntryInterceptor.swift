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
    /// In this method we have to take MediaEntry, change MediaSource in it and return Error if needed.
    /// Consider of making this method performing all logic in concurrent thread, if this logic is time consuming.
    @objc func apply(on mediaEntry: PKMediaEntry, completion: @escaping () -> Void)
}
