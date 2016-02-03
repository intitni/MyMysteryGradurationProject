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
                               uint2 gid [[thread_position_in_grid]]) {
    float3 current = inTexture.read(gid).rgb;
    if (current.r <= 0.81 || current.r >= 0.83) {
        outTexture.write(float4(current, 1), gid);
        return;
    }
    int sideWidth = weights.get_width();
    int radius = sideWidth / 2;
    int stepper = sideWidth / 3;
    int greenCount[8] = {0,0,0,0,0,0,0,0};
    for (int i = 0; i < sideWidth; i++) {
        for (int j = 0; j < sideWidth; j++) {
            uint2 textureIndex(gid.x + i - radius, gid.y + j - radius);
            if (inTexture.read(textureIndex).r <= 0.41 || inTexture.read(textureIndex).r >=0.43) {
                continue;
            }
            if (j < stepper) {
                if (i < stepper) {
                    greenCount[0]++;
                } else if (i >= stepper && i < sideWidth - 2 * stepper) {
                    greenCount[1]++;
                } else if (i >= sideWidth - 2 * stepper) {
                    greenCount[2]++;
                }
            } else if (j >= stepper && j < sideWidth - 2 * stepper) {
                if (i < stepper) {
                    greenCount[3]++;
                } else if (i >= stepper && i < sideWidth - 2 * stepper) {
                    continue;
                } else if (i >= sideWidth - 2 * stepper) {
                    greenCount[4]++;
                }
            } else if (j >= sideWidth - 2 * stepper) {
                if (i < stepper) {
                    greenCount[5]++;
                } else if (i >= stepper && i < sideWidth - 2 * stepper) {
                    greenCount[6]++;
                } else if (i >= sideWidth - 2 * stepper) {
                    greenCount[7]++;
                }
            }
        }
    }
    
    if (greenCount[0] + greenCount[1] + greenCount[2] + greenCount[3] + greenCount[4] + greenCount[5] + greenCount[6] + greenCount[7] <= 0) {
        outTexture.write(float4(current, 1), gid);
        return;
    }
    
    int newGreenCount[8];
    newGreenCount[0] = greenCount[0] + greenCount[1] + greenCount[3];
    newGreenCount[1] = greenCount[1] + greenCount[0] + greenCount[2];
    newGreenCount[2] = greenCount[2] + greenCount[1] + greenCount[4];
    newGreenCount[3] = greenCount[3] + greenCount[0] + greenCount[5];
    newGreenCount[4] = greenCount[4] + greenCount[2] + greenCount[7];
    newGreenCount[5] = greenCount[5] + greenCount[3] + greenCount[6];
    newGreenCount[6] = greenCount[6] + greenCount[5] + greenCount[7];
    newGreenCount[7] = greenCount[7] + greenCount[4] + greenCount[6];
    
    int direction = 0;
    int most = newGreenCount[0];
    for (int i = 0; i < 8; i++) {
        if (newGreenCount[i] > most) {
            direction = i;
            most = newGreenCount[i];
        }
    }
    
    for (int i = 0; i < stepper; i++) {
        
    }
    
    outTexture.write(float4(0.26, 0.52, 0.84, 1), gid);
}