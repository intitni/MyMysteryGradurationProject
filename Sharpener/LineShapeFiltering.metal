//
//  LineShapeFiltering.metal
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct LineShapeFilteringUniforms {
    float threshold;
};

kernel void lineShapeFiltering(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               texture2d<float, access::read> weights [[texture(2)]],
                               constant LineShapeFilteringUniforms &uniforms [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]]) {
    // inTexture should be thresholded.
    int sideWidth = weights.get_width();
    int radius = sideWidth / 2;
    float input = inTexture.read(gid).r;
    float accumulation = 0;
    
    if (input == 1) {
        outTexture.write(inTexture.read(gid), gid);
        return;
    }
    
    for (int i = 0; i < sideWidth; i++) {
        for (int j = 0; j < sideWidth; j++) {
            uint2 textureIndex(gid.x + i - radius, gid.y + j - radius);
            uint2 weightIndex(i, j);
            float current = inTexture.read(textureIndex).r;
            float currentWeight = weights.read(weightIndex).r;
            accumulation += abs(current - currentWeight);
        }
    }
    
    // when it's close enough to weights computator, it's a texel in a shape
    if (accumulation < uniforms.threshold) {
        outTexture.write(float4(0.819, 0.808, 0.655, 1), gid);
    } else {
        outTexture.write(float4(0.545, 0.631, 0.608, 1), gid);
    }
}




