//
//  GaussianBlur.metal
//  Sharpener
//
//  Created by Inti Guo on 2/7/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void gaussianBlur(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         texture2d<float, access::read> weights [[texture(2)]],
                         uint2 gid [[thread_position_in_grid]]) {
    int sideWidth = weights.get_width();
    int radius = sideWidth / 2
    float4 accumulation = float4(0);
    
    for (int i = 0; i < sideWidth; i++) {
        for (int j = 0; j < sideWidth; j++) {
            uint2 textureIndex(gid.x + i - radius, gid.y + j - radius);
            uint2 weightIndex(i, j);
            
            float4 current = inTexture.read(textureIndex).xyzw;
            float currentWeight = weights.read(weightIndex).x;
            accumulation += current * currentWeight;
        }
    }
    
    outTexture.write(accumulation, gid);
}