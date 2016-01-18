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
    
    /* dispatch_get_queue() */
    static var mainQueue: dispatch_queue_t {
        return dispatch_get_main_queue()
    }
    static var userInteractiveQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
    }
    static var userInitiatedQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    }
    static var utilityQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }
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
}