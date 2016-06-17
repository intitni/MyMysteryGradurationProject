//
//  MedianFilter.metal
//  Sharpener
//
//  Created by Inti Guo on 12/23/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MedianFilterUniforms {
    int radius;
};

kernel void medianFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         constant MedianFilterUniforms &uniforms [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    int radius = uniforms.radius;
    
    int size = radius * 2 + 1;
    int space = size * size;
    int oneCount = 0;

    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            float current = inTexture.read(textureIndex).r;
            oneCount += current; // plus 1 when 1
        }
    }
    
    float factor = step(float(space)*0.85, float(oneCount));
    float newValue = factor;

    outTexture.write(float4(float3(newValue), 1.0), gid);
}


