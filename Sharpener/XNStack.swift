//
//  XNStack.swift
//  Sharpener
//
//  Created by Inti Guo on 1/18/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

public struct Stack<T> {
    public var storage: Array<T>
    
    public var isEmpty: Bool { return storage.isEmpty }
    public var count: Int { return storage.count }
    public var bottom: T? { return storage.first }
    public var top: T? { return storage.last }
    public var peek: T? { return top }
    
    public mutating func push(elem: T) {
        storage.append(elem)
    }
    
    public mutating func pop() -> T? {
        return storage.popLast()
    }
    
    subscript(index: Int) -> T {
        return storage[index]
    }
}
