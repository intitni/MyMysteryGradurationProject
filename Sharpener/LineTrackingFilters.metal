//
//  LineTrackingFilters.metal
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
    int radius = sideWidth / 2;
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

kernel void gradientTensorCalculating(texture2d<float, access::read> inTexture [[texture(0)]],
                                      texture2d<float, access::write> outTexture [[texture(1)]],
                                      texture2d<float, access::read> xOperator [[texture(2)]],
                                      texture2d<float, access::read> yOperator [[texture(3)]],
                                      uint2 gid [[thread_position_in_grid]]) {
    int radius = 1;
    float iX = 0;
    float iY = 0;
    
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
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

kernel void directionTensorCalculating(texture2d<float, access::read> inTexture [[texture(0)]],
                                      texture2d<float, access::write> outTexture [[texture(1)]],
                                      texture2d<float, access::read> xOperator [[texture(2)]],
                                      texture2d<float, access::read> yOperator [[texture(3)]],
                                      uint2 gid [[thread_position_in_grid]]) {
    int radius = 1;
    float iX = 0;
    float iY = 0;
    
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
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

kernel void eigenCalculating(texture2d<float, access::read> gradientTensor [[texture(0)]],
                             texture2d<float, access::write> eigenValues [[texture(1)]],
                             texture2d<float, access::write> eigenVectors [[texture(2)]],
                             uint2 gid [[thread_position_in_grid]]) {
    float a = gradientTensor.read(gid).x;
    float b = gradientTensor.read(gid).y;
    float c = gradientTensor.read(gid).z;
    float d = gradientTensor.read(gid).w;
    float s = pow(a+d, 2) - 4 * (a*d - b*c);
    float maxv = (a + d + sqrt(s))/2;
    float minv = (a + d - sqrt(s))/2;
    
    eigenValues.write(float4(minv, maxv, float2(0)), gid);
    
    // gradient
    float up = b;
    float down = maxv - a;
    
    float2 g = float2(up, down);
    
    // tangential
    down = minv - a;
    
    float2 t = float2(up, down);
    
    eigenVectors.write(float4(g, t), gid);
}

struct HarrisFilterUniforms {
    float alpha; // between 0.04 ~ 0.06
};

kernel void harris(texture2d<float, access::read> gradientTensor [[texture(0)]],
                   texture2d<float, access::write> respondValues [[texture(1)]],
                   constant HarrisFilterUniforms &uniforms [[buffer(0)]],
                   uint2 gid [[thread_position_in_grid]]) {
    float alpha = uniforms.alpha;
    float4 tensor = gradientTensor.read(gid).xyzw;
    float dm = tensor.x * tensor.w - pow(tensor.y, 2);
    float tm = tensor.x + tensor.w;
    float r = dm - alpha * pow(tm, 2);
    if (r < 0) { r = 0; }
    
    respondValues.write(float4(r, float3(0)), gid);
}

kernel void invert(texture2d<float, access::read> inTexture [[texture(0)]],
                   texture2d<float, access::write> outTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]]) {
    float4 input = inTexture.read(gid).rgba;
    outTexture.write(float4(1-input.r, 1-input.g, 1-input.b, 1-input.a), gid);
}
