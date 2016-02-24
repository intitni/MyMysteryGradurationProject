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
    
    convenience init(json: JSON) {
        self.init()
        for (_, subJson):(String, JSON) in json {
            let s = self.geometricFromJSON(subJson)
            if s is SPShape {
                self.shapeStore.append(s as! SPShape)
            } else if s is SPLineGroup {
                self.lineStore.append(s as! SPLineGroup)
            }
        }
    }
}

// MARK: - From JSON 
extension SPGeometricsStore {
    private func geometricFromJSON(json: JSON) -> SPGeometrics {
        if json["type"].stringValue == "shape" {
            let s = SPShape()
            s.lines = curvesFromJSON(json["curves"])
            return s
        } else {
            let s = SPLineGroup()
            s.lines = curvesFromJSON(json["curves"])
            return s
        }
    }
    
    private func curvesFromJSON(json: JSON) -> [SPCurve] {
        var curves = [SPCurve]()
        for j in json.arrayValue {
            curves.append(curveFromJSON(j))
        }
        return curves
    }
    
    private func curveFromJSON(json: JSON) -> SPCurve {
        let curve = SPCurve(raw: [])
        curve.guesses = guessesFromJSON(json["guesses"])
        curve.vectorized = vectorizedFromJSON(json["vectorized"])
        if json["applied"].isExists() {
            curve.applied = guessFromJSON(json["applied"])
            if curve.applied != nil {
                curve.guesses.append(curve.applied!)
            }
        }
        return curve
    }

    private func guessesFromJSON(json: JSON) -> [SPGuess] {
        var guesses = [SPGuess]()
        for j in json.arrayValue {
            if let g = guessFromJSON(j) {
                guesses.append(g)
            }
        }
        return guesses
    }
    
    private func guessFromJSON(json: JSON) -> SPGuess? {
        let type = json["type"].stringValue
        switch type {
        case "straight":
            return SPGuess(guessType: .Straight(start: CGPoint(x: CGFloat(json["start_point","x"].floatValue), y: CGFloat(json["start_point","y"].floatValue)), end: CGPoint(x: CGFloat(json["end_point","x"].floatValue), y: CGFloat(json["end_point","y"].floatValue))))
        case "circle":
            return SPGuess(guessType: .Circle(center: CGPoint(x: CGFloat(json["center","x"].floatValue), y: CGFloat(json["center","y"].floatValue)), radius: CGFloat(json["radius"].floatValue)))
        case "rectangle":
            return SPGuess(guessType:
                .Rectangle(center: CGPoint(x: CGFloat(json["center","x"].floatValue), y: CGFloat(json["center","y"].floatValue)),
                    height: CGFloat(json["height"].floatValue),
                    width: CGFloat(json["width"].floatValue),
                    rotation: CGFloat(json["rotation"].floatValue),
                    radius: CGFloat(json["radius"].floatValue)
                )
            )
        case "polygon":
            return SPGuess(guessType: .Polygon(points: json["points"].arrayValue.map({ j in
                return CGPoint(x: CGFloat(j["x"].floatValue), y: CGFloat(j["y"].floatValue))
            })))
        default: break
        }
        return nil
    }
    
    private func vectorizedFromJSON(json: JSON) -> [SPAnchorPoint] {
        var points = [SPAnchorPoint]()
        for pjson in json.arrayValue {
            var p = SPAnchorPoint(point: CGPoint(x: CGFloat(pjson["anchor_point","x"].floatValue), y: CGFloat(pjson["anchor_point","y"].floatValue)))
            if pjson["control_point_A"].isExists() {
                p.controlPointA = CGPoint(x: CGFloat(pjson["control_point_A","x"].floatValue), y: CGFloat(pjson["control_point_A","y"].floatValue))
            }
            if pjson["control_point_B"].isExists() {
                p.controlPointB = CGPoint(x: CGFloat(pjson["control_point_B","x"].floatValue), y: CGFloat(pjson["control_point_B","y"].floatValue))
            }
            points.append(p)
        }
        return points
    }
}

// MARK: - To JSON
extension SPGeometricsStore {
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