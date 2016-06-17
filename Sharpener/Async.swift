//
//  Async.swift
//  Sharpener
//
//  Created by Inti Guo on 1/17/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

// MARK: -  GCD queues

class GCD {
    
    /// Dispatch to main queue, where UIs and most things should be in.
    static var mainQueue: dispatch_queue_t {
        return dispatch_get_main_queue()
    }
    /// Work that is interacting with the user, such as operating on the main thread, refreshing the user interface, or performing animations.
    static var userInteractiveQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
    }
    /// Work that the user has initiated and requires immediate results, such as opening a saved document or performing an action when the user clicks something in the user interface. The work is required in order to continue user interaction. Focuses on responsiveness and performance.
    static var userInitiatedQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    }
    /// Work that may take some time to complete and doesn’t require an immediate result, such as downloading or importing data. Utility tasks typically have a progress bar that is visible to the user. Focuses on providing a balance between responsiveness, performance, and energy efficiency.
    static var utilityQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }
    /// Work that operates in the background and isn’t visible to the user, such as indexing, synchronizing, and backups. Focuses on energy efficiency.
    static var backgroundQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    }
    static var piorityHighQueue: dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    }
    static var piorityLowQueue: dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    }
    static var piorityDefaultQueue: dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }
    
    static func newSerialQueue(name: String) -> dispatch_queue_t {
        return dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
    }
}