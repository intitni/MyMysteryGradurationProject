//
//  Thresholding.metal
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ThresholdingUniforms {
    float thresholdFactor;
};

kernel void thresholding(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         constant ThresholdingUniforms &uniforms [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    float factor = uniforms.thresholdFactor;
    float brightness = inTexture.read(gid).r;
    float newValue = step(factor, brightness);
    outTexture.write(float4(newValue), gid);
}
