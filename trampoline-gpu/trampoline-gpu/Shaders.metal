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
    int2 constantsIndices;
} Spring;


typedef struct {
    float4 position [[position]];
    float4 color;
} VertexOut;

typedef struct {
    float3 position;
    float3 color;
} VertexIn;


kernel void spring_update(device Particle *particles [[ buffer(ParticleBufferIndex) ]],
                          constant Spring *springs [[ buffer(SpringBufferIndex) ]],
                          constant float *constants [[ buffer(ConstantBufferIndex) ]],
                          uint id [[ thread_position_in_grid ]])
{
    Spring spring = springs[id];
    Particle p1 = particles[spring.indices.x];
    Particle p2 = particles[spring.indices.y];
    
    float3 d_pos = p2.pos - p1.pos;
    float current_length = length(d_pos);
    
    if (current_length != 0.0) {
        float springConstant = constants[spring.constantsIndices.x];
        float velConstant = constants[spring.constantsIndices.y];
        float3 force_at_p1 = normalize(d_pos) * springConstant * (current_length - spring.initialLength) + velConstant * (p2.vel - p1.vel);
        particles[spring.indices.x].force += force_at_p1;
        particles[spring.indices.y].force += -force_at_p1;
    }
}

kernel void particle_update(device Particle *particles [[ buffer(ParticleBufferIndex)]],
                            constant float *physicalUniforms [[ buffer(PhysicalUniformsBufferIndex) ]],
                            uint id [[ thread_position_in_grid ]])
{
    if (!particles[id].isLocked) {
        float3 gravity = float3(0, physicalUniforms[1], 0);
        particles[id].vel += ((particles[id].force / particles[id].mass) + gravity) * physicalUniforms[0];
        particles[id].pos += particles[id].vel * physicalUniforms[0];
    }
    particles[id].force = float3(0, 0, 0);
    
}





vertex VertexOut particle_vertex_shader(constant Particle *particles [[ buffer(ParticleBufferIndex) ]],
                              constant Spring *springs [[ buffer(SpringBufferIndex) ]],
                              constant Uniforms &uniforms [[ buffer(UniformsBufferIndex) ]],
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

vertex VertexOut basic_vertex_shader(constant VertexIn *vertices [[ buffer(OtherRenderingBufferIndex) ]],
                                     constant Uniforms &uniforms [[ buffer(UniformsBufferIndex) ]],
                                     uint vid [[ vertex_id ]])
{
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vertices[vid].position, 1);
    out.color = float4(vertices[vid].color, 1);
    return out;
}


fragment half4 fragment_shader(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}


