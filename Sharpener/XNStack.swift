//
//  XNStack.swift
//  Sharpener
//
//  Created by Inti Guo on 1/18/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

struct Stack<T> {
    var storage: Array<T>
    
    var isEmpty: Bool { return storage.isEmpty }
    var count: Int { return storage.count }
    var bottom: T? { return storage.first }
    var top: T? { return storage.last }
    
    mutating func push(elem: T) {
        storage.append(elem)
    }
    
    mutating func pop() -> T? {
        return storage.popLast()
    }
    
    subscript(index: Int) -> T {
        return storage[index]
    }
}
