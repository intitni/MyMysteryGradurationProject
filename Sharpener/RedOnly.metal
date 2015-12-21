//
//  RedOnly.metal
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void red_only(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    float red = inTexture.read(gid).r;
    float4 newColor = float4(red, 0, 0, 1.0);
    outTexture.write(newColor, gid);
}