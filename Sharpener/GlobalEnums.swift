//
//  GlobalEnums.swift
//  Sharpener
//
//  Created by Inti Guo on 12/23/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation

enum OnOff: Int, CustomStringConvertible, BooleanType {
    case Off, On
    
    func isOn() -> Bool { return self == .On ? true : false }
    func isOff() -> Bool { return !isOn() }
    mutating func toggle() {
        self = OnOff(rawValue: 1-self.rawValue)!
    }
    
    var description: String {
        return self == .On ? "On" : "Off"
    }
    
    var descriptionUpperCased: String {
        return self == .On ? "ON" : "OFF"
    }
    
    var boolValue: Bool {
        return isOn()
    }
}

enum Direction2D {
    case Up, Down, Left, Right
    case North, South, West, East
    
    case UpLeft, DownLeft, UpRight, DownRight
    case Northwest, Southwest, Northeast, Southeast
    
    case Clockwise(degree: Double)
    case CounterClockwise(degree: Double)
}