


#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>


/// indices of buffers (at which port does the shader function receive the buffer)
typedef NS_ENUM(NSInteger, BufferIndex)
{
    ParticleBufferIndex = 0,
    SpringBufferIndex = 1,
    UniformsBufferIndex = 2,
    ConstantBufferIndex = 3,
    PhysicalUniformsBufferIndex = 4,
    OtherRenderingBufferIndex = 5
};


/// indices determining position of constants in constantsArray
typedef NS_ENUM(NSInteger, ConstantsIndex)
{
    innerSpringConstantsBuffer = 0,
    innerVelConstantsBuffer = 1,
    outerSpringConstant = 2,
    outerVelConstant = 3
};

/// uniforms for the rendering
typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} Uniforms;






#endif
