//
//  SPGeometricsStore.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import SwiftyJSON

/// SPGeometricsStore is used to store SPGeometrics
class SPGeometricsStore {
    
    /// Singleton for proccessing progress
    static var universalStore = SPGeometricsStore()
    
    var rawStore = [SPRawGeometric]()
    var shapeStore = [SPShape]()
    var lineStore = [SPLineGroup]()
    var shapeCount: Int { return shapeStore.count }
    var lineCount: Int { return lineStore.count }
    var geometricsCount: Int { return shapeCount + lineCount }
    
    var shapeLayers: [CAShapeLayer] {
        var layers = [CAShapeLayer]()
        for s in shapeStore {
            layers.append(s.shapeLayerPure)
        }
        for l in lineStore {
            layers.append(l.shapeLayerPure)
        }
        return layers
    }
}

// MARK: - Methods
extension SPGeometricsStore {
    func removeAll() {
        shapeStore.removeAll()
        lineStore.removeAll()
        rawStore.removeAll()
    }
    
    func append(shape: SPShape) {
        shapeStore.append(shape)
    }
    
    func append(line: SPLineGroup) {
        lineStore.append(line)
    }
}

// MARK: - JSON
extension SPGeometricsStore {
    var json: JSON {
        var j = [JSON]()
        for shape in shapeStore {
            j.append(jsonForGeometric(shape))
        }
        for linegroup in lineStore {
            j.append(jsonForGeometric(linegroup))
        }
        return JSON(j)
    }
    
    init(json: JSON) {
        
    }

    
    private func jsonForGeometric(geometric: SPGeometrics) -> JSON {
        var json = [String: JSON]()
        
        json["type"] = geometric is SPShape ? "shape" : "linegroup"
        json["curves"] = jsonForCurves(geometric.lines)
        
        return JSON(json)
    }
    
    private func jsonForCurves(curves: [SPCurve]) -> JSON {
        var json = [JSON]()
        for curve in curves {
            json.append(jsonForCurve(curve))
        }
        return JSON(json)
    }
    
    private func jsonForCurve(curve: SPCurve) -> JSON {
        var json = [String: JSON]()
        json["guesses"] = jsonForGuesses(curve.guesses, excludingApplied: curve.applied)
        json["vectorized"] = jsonForVectorized(curve.vectorized)
        if curve.applied != nil {
            json["applied"] = jsonForGuess(curve.applied!)
        }
        return JSON(json)
    }
    
    private func jsonForGuesses(guesses: [SPGuess], excludingApplied applied: SPGuess?) -> JSON {
        var json = [JSON]()
        for g in guesses where g !== applied {
            json.append(jsonForGuess(g))
        }
        return JSON(json)
    }
    
    private func jsonForGuess(guess: SPGuess) -> JSON {
        var gjson = [String: JSON]()
        switch guess.guessType! {
        case .Straight(start: let s, end: let e):
            gjson["type"] = "straight"
            gjson["start_point"] = JSON(["x": s.x, "y": s.y])
            gjson["end_point"] = JSON(["x": e.x, "y": e.y])
        case .Circle(center: let c, radius: let r):
            gjson["type"] = "circle"
            gjson["center"] = JSON(["x": c.x, "y": c.y])
            gjson["radius"] = JSON(r)
        case .Rectangle(center: let c, height: let h, width: let w, rotation: let ro, radius: let ra):
            gjson["type"] = "rectangle"
            gjson["center"] = JSON(["x": c.x, "y": c.y])
            gjson["radius"] = JSON(ra)
            gjson["height"] = JSON(h)
            gjson["width"] = JSON(w)
            gjson["rotation"] = JSON(ro)
        case .Polygon(points: let pts):
            gjson["type"] = "Polygon"
            gjson["points"] = JSON(pts.map { c -> JSON in return JSON(["x": c.x, "y": c.y]) })
        default: break
        }
        return JSON(gjson)
    }
    
    private func jsonForVectorized(vectorized: [SPAnchorPoint]) -> JSON {
        var json = [JSON]()
        for p in vectorized {
            var pjson = [String: JSON]()
            let anchorP: JSON = ["x": p.anchorPoint.x, "y": p.anchorPoint.y]
            pjson["anchor_point"] = anchorP
            if let ca = p.controlPointA {
                let controlA: JSON = ["x": ca.x, "y": ca.y]
                pjson["control_point_A"] = controlA
            }
            if let cb = p.controlPointB {
                let controlB: JSON = ["x": cb.x, "y": cb.y]
                pjson["control_point_B"] = controlB
            }
            json.append(JSON(pjson))
        }
        return JSON(json)
    }
}