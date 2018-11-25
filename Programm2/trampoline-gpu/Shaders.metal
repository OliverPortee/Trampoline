

#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"


using namespace metal;


typedef struct
{
    float3 pos;
    float3 lastPos;
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

/// applies forces to particles determined by spring length and constants
kernel void spring_update(device Particle *particles [[ buffer(ParticleBufferIndex) ]],
                          constant Spring *springs [[ buffer(SpringBufferIndex) ]],
                          constant float *constants [[ buffer(ConstantBufferIndex) ]],
                          constant float *physicalUniforms [[ buffer(PhysicalUniformsBufferIndex) ]],
                          uint id [[ thread_position_in_grid ]])
{
    /// fetching spring from buffer
    Spring spring = springs[id];
    /// fetching particles from buffer according to spring indices
    Particle p1 = particles[spring.indices.x];
    Particle p2 = particles[spring.indices.y];
    /// calculating vector between particels
    float3 d_pos = p2.pos - p1.pos;
    /// calculating distance between particles
    float current_length = length(d_pos);
    /// condition to prevent dividing by zero
    if (current_length != 0.0) {
        /// fetching spring constants
        float springConstant = constants[spring.constantsIndices.x];
        float velConstant = constants[spring.constantsIndices.y];
        /// calculating force on particles
        float dt = physicalUniforms[0];
        float3 vel1, vel2;
        if (dt != 0) {
            vel1 = (p1.pos - p1.lastPos) / physicalUniforms[0];
            vel2 = (p2.pos - p2.lastPos) / physicalUniforms[0];
        } else {
            vel1 = float3(0, 0, 0);
            vel2 = float3(0, 0, 0);
        }

        float3 force_at_p1 = normalize(d_pos) * springConstant * (current_length - spring.initialLength) + velConstant * (vel2 - vel1);
        /// applying force to particles
        particles[spring.indices.x].force += force_at_p1;
        particles[spring.indices.y].force += -force_at_p1;
        
    }
}

/// applies gravity, updates velocity and position of particles and clears force
kernel void particle_update(device Particle *particles [[ buffer(ParticleBufferIndex)]],
                            constant float *physicalUniforms [[ buffer(PhysicalUniformsBufferIndex) ]],
                            uint id [[ thread_position_in_grid ]])
{
    
    if (!particles[id].isLocked) {
        float3 gravity = float3(0, physicalUniforms[1], 0);
        
        float3 pos = particles[id].pos;
        Particle p = particles[id];
        
        particles[id].pos = 2 * p.pos - p.lastPos + ((p.force / p.mass) + gravity) * physicalUniforms[0] * physicalUniforms[0];
        particles[id].lastPos = pos;
    }
    particles[id].force = float3(0, 0, 0);
    
}




/// renders connections between particles
vertex VertexOut particle_vertex_shader(constant Particle *particles [[ buffer(ParticleBufferIndex) ]],
                              constant Spring *springs [[ buffer(SpringBufferIndex) ]],
                              constant Uniforms &uniforms [[ buffer(UniformsBufferIndex) ]],
                              uint vid [[ vertex_id ]])
{
    /// function runs through springs and not through particles in order to display connections between particles; thus it needs to get the particle based on modulo 2 (it can only render one vertex per function call)
    Particle particle;
    if (vid % 2 == 0) {
        particle = particles[springs[vid / 2].indices.x];
    } else {
        particle = particles[springs[(vid - 1) / 2].indices.y];
    }
    /// creating a float4 vector in order to apply matrizes
    float4 position = float4(particle.pos, 1.0);
    /// creating new VertexOut
    VertexOut out;
    /// applying matrizes
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    /// setting color
    out.color = float4(0, 0, 0, 1);
    
    return out;
}

/// basic vertex shader for other rendering (i. e. the ring at the edge of trampoline jumping sheet)
vertex VertexOut basic_vertex_shader(constant VertexIn *vertices [[ buffer(OtherRenderingBufferIndex) ]],
                                     constant Uniforms &uniforms [[ buffer(UniformsBufferIndex) ]],
                                     uint vid [[ vertex_id ]])
{
    /// creating new VertexOut
    VertexOut out;
    /// applying matrizes
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vertices[vid].position, 1);
    /// setting color
    out.color = float4(vertices[vid].color, 1);
    return out;
}

/// fragment function on how to interpolate color at every pixel
fragment half4 fragment_shader(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}


