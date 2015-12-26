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
    float3 input = inTexture.read(gid).rgb;
    // (0.2126*R + 0.7152*G + 0.0722*B)
    float brightness = 0.2*input.r + 0.7*input.g + 0.1*input.b;
    float darkenFactor = 1-step(0.35, brightness);
    float darkenBrightness = darkenFactor * 0.3 * brightness;
    brightness = darkenFactor * darkenBrightness + (1-darkenFactor) * brightness;
    float newValue = step(factor, brightness);
    outTexture.write(float4(newValue, newValue, newValue, 1.0), gid);
}
