//
//  Shaders.metal
//  Renderer
//
//  Created by Oliver Portee on 01.11.18.
//  Copyright © 2018 Oliver Portee. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"


using namespace metal;


typedef struct
{
    float3 pos;
    float3 vel;
    float3 force;
    float mass;
    bool isLocked;
} Particle;

typedef struct
{
    int2 indices;
    float initialLength;
    float springConstant;
    float velConstant;
} Spring;


typedef struct {
    float4 position [[position]];
    float4 color;
} VertexOut;




vertex VertexOut vertex_shader(constant Particle *particles [[ buffer(ParticleBufferIndex) ]],
                              constant Spring *springs [[ buffer(SpringBufferIndex) ]],
                              constant Uniforms & uniforms [[ buffer(UniformsBufferIndex) ]],
                              uint vid [[ vertex_id ]])
{
    Particle particle;
    if (vid % 2 == 0) {
        particle = particles[springs[vid / 2].indices.x];
    } else {
        particle = particles[springs[(vid - 1) / 2].indices.y];
    }
    
    
    float4 position = float4(particle.pos, 1.0);
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.color = float4(1, 1, 1, 1);
    
    return out;
}



fragment half4 fragment_shader(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}


