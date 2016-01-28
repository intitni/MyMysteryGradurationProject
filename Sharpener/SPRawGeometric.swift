//
//  SPRawGeometrics.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

struct SPRawGeometric {
    var type: SPGeometricType = .Shape
    var isHidden: Bool = false
    var raw = [CGPoint]()
    var lineSize: Int = 0
    var shapeSize: Int = 0
    var shapeWeight: Int { return shapeSize / (lineSize + shapeSize + 1) }
    var borders = [SPLine]()
    
    init(raw: [CGPoint] = [CGPoint]()) {
        self.raw = raw
    }
    
    func imageInTextureData(var textureData: MXNTextureData, shouldThreshold threshold: Bool = true, shouldInvert invert: Bool = true) -> UIImage {
        let width = textureData.width
        let height = textureData.height
        let newRaw = [UInt8](count: width*height*4, repeatedValue: invert ? 0 : 255)
        textureData.data = newRaw
        for i in 0..<width*height*4 where i % 3 == 0 { // setting alphas to 255
            textureData.data[i] = 255
        }
        raw.forEach {
            let c: UInt8 = invert ? 255 : 0
            let p = RGBAPixel(r: c, g: c, b: c, a: 255)
            textureData[$0] = p
        }
        
        return UIImage(textureData: textureData)
    }
}
