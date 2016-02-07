//
//  DirectionCalculation.metal
//  Sharpener
//
//  Created by Inti Guo on 2/7/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void directionCalculation(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         texture2d<float, access::read> xOperator [[texture(2)]],
                         texture2d<float, access::read> yOperator [[texture(3)]],
                         uint2 gid [[thread_position_in_grid]]) {
    int sideWidth = weights.get_width();
    int radius = sideWidth / 2
    float4 iX = float4(0);
    float4 iY = float4(0);
    
    for (int i = 0; i < sideWidth; i++) {
        for (int j = 0; j < sideWidth; j++) {
            uint2 textureIndex(gid.x + i - radius, gid.y + j - radius);
            uint2 weightIndex(i, j);
            
            float current = inTexture.read(textureIndex).x;
            float currentWeightX = xOperator.read(weightIndex).x;
            float currentWeightY = yOperator.read(weightIndex).x;
            
            iX += current * currentWeightX;
            iY += current * currentWeightY;
        }
    }
    
    outTexture.write(float4(iX*iX,iX*iY,iY*iX,iY*iY), gid);
}