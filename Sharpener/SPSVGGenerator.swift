//
//  SPSVGGenerator.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPSVGGenerator {
    static let header: String = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<svg width=\"600px\" height=\"800px\" viewBox=\"0 0 600 800\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">"
    static let closer: String = "</svg>"
    
    func title(title: String) -> String {
        return "\t<title>\(title)</title>\n"
    }
    
    func createSVGFor(store: SPGeometricsStore) -> NSURL {
        var raw = SPSVGGenerator.header
        raw += title("Sharpener")
        for (i, shape) in store.shapeStore.enumerate() {
            
            for curve in shape.lines {
            
            }
        }
        return NSURL()
    }
    
    struct groupElement {
        var id: String
        var fillMode: String = "evenodd"
        var fill: String = "none"
        var strokeWidth: CGFloat = 0
        var stroke: Bool = false
        var type: SPGeometricType
        var subelements = [String]()
        
        let head = "<g "
        let tail = "\n</g>"
        
        var string: String {
            var s = head + "id=\"" + id + "\" "
            if type == .Shape {
                 s += "stroke=\"none\" stroke-width=\"\(strokeWidth)\" stroke-linecap=\"square\""
            } else {
                s += "stroke=\"none\" fill-rule=\"" + fillMode + "\" fill=\"none\""
            }
            for sub in subelements {
                s += sub
            }
            s += tail
            return s
        }
        
        init(type: SPGeometricType, id: String) {
            self.type = type
            self.id = id
            switch type {
            case .Line:
                strokeWidth = 4
                stroke = true
            default: break
            }
        }
    }
    
    struct pathElement {
        var d: String
        var id: String
        var fill: String = "#000000"
        
        let head = "<path "
        let tail = "></path>"
        
        init(id: String) { self.id = id; self.d = "" }
        mutating func moveToPoint(point: CGPoint) {
            d += "M\(point.x),\(point.y) "
        }
        mutating func addCurveToPoint(point: SPAnchorPoint) {
            guard point.controlPointA != nil && point.controlPointB != nil else {
                moveToPoint(point.anchorPoint)
                return
            }
            let new = "C\(point.anchorPoint.x),\(point.anchorPoint.y) "
                    + "\(point.controlPointA!.x),\(point.controlPointA!.y) "
                    + "\(point.controlPointB!.x),\(point.controlPointB!.y) "
            d += new
        }
        mutating func addLineToPoint(point: CGPoint) {
            d += "L\(point.x),\(point.y) "
        }
        
        var string: String {
            return head + "d=\"" + d + "\" id=\"" + id + "\" fill=\"" + fill + "\"" + tail
        }
    }
    
    struct circleElement {
        var id: String
        var fill: String = "#000000"
        var cx: CGFloat
        var cy: CGFloat
        var r: CGFloat
        
        let head = "<path "
        let tail = "></path>"
        
        init(id: String, cx: CGFloat, cy: CGFloat, rx: CGFloat, r: CGFloat) {
            self.id = id
            self.cx = cx
            self.cy = cy
            self.r = r
        }
        
        var string: String {
            let d = "M\(cx),\(cy) m\(-r),0 a\(r)\(r) 0 1,0 \(r*2),0 a\(r)\(r) 0 1,0 \(-r*2),0"
            return head + "d=\"" + d + "\" id=\"" + id + "\" fill=\"" + fill + "\"" + tail
        }
    }
    
    struct rectElement {
        var id: String
        var fill: String = "#000000"
        var rect: CGRect
        
        let head = "<path "
        let tail = "></path>"
        
        init(id: String, rect: CGRect) {
            self.id = id
            self.rect = rect
        }
    }
}










