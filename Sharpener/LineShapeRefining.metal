//
//  LineShapeRefining.metal
//  Sharpener
//
//  Created by Inti Guo on 1/15/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void lineShapeRefining(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               texture2d<float, access::read> weights [[texture(2)]],
                               constant LineShapeFilteringUniforms &uniforms [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]]) {


}