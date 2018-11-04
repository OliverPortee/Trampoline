
import Metal
import simd

/// class for updating the mesh and for interacting with metal's compute shaders (see kernel functions in Shaders.metal file)
class MeshUpdater: NSObject {
    /// represents GPU in software
    var device: MTLDevice
    /// state of computePipeline when springs are updated (i. e. represents spring_update function in Shaders.metal)
    var springPipelineState: MTLComputePipelineState
    /// state of computePipeline when particles are updates (i. e. represents particles_update function in Shaders.metal)
    var particlePipelineState: MTLComputePipelineState
    /// stores all commandBuffer and gives them to GPU
    var commandQueue: MTLCommandQueue
    /// y component of gravity vector in model
    var gravity: Float = 0
    /// delegate of dataController which will be updated during update function once per frame
    var dataController: DataController?
    /**
     Init function of MeshUpdater
     - Parameters:
         - device: device which MeshUpdater should use for GPU computations
         - library: library which contains metal shading language source code and which is used to connect with metal shaders
         - commandQueue: queue which contains all commandBuffers
         - springFunctionName: name of spring function in Shaders.metal (i. e. "spring_update")
         - particleFunctionName: name of particle function in Shaders.metal (i. e. "particle_update")
     
     Initializes MeshUpdater and creates computePipelineStates.
    */
    init(device: MTLDevice, library: MTLLibrary, commandQueue: MTLCommandQueue, springFunctionName: String, particleFunctionName: String) {
        self.device = device
        self.commandQueue = commandQueue
        let springFunction = library.makeFunction(name: springFunctionName)!
        let particleFunction = library.makeFunction(name: particleFunctionName)!
        self.springPipelineState = try! device.makeComputePipelineState(function: springFunction)
        self.particlePipelineState = try! device.makeComputePipelineState(function: particleFunction)
    }
    
    /**
     General update function which is called once per frame and which calls updateSprings(mesh:), updateParticles(dt:mesh:) and the update function of dataController.
     - Parameters:
         - dt: Float which represents virtual frame time (i. e. 1 / framerate)
         - mesh: Mesh which should be updated
    */
    func update(dt: Float, mesh: Mesh) {
        updateSprings(mesh: mesh)
        
        if let dataController = self.dataController {
            dataController.update(dt: dt)
        }
        updateParticles(dt: dt, mesh: mesh)
    }
    /// updates springs
    func updateSprings(mesh: Mesh) {
        /// commandBuffer contains all commands that the GPU should execute
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        /// computeCommandEncoder translates commands into a form that the GPU can understand
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        /// sets spring_update function as current compute function
        computeCommandEncoder.setComputePipelineState(springPipelineState)
        /// sets buffers into computeCommandEncoder that contain model data (such as position of particles of springs contstants)
        computeCommandEncoder.setBuffer(mesh.particleBuffer, offset: 0, index: BufferIndex.ParticleBufferIndex.rawValue)
        computeCommandEncoder.setBuffer(mesh.springBuffer, offset: 0, index: BufferIndex.SpringBufferIndex.rawValue)
        computeCommandEncoder.setBuffer(mesh.constantsBuffer, offset: 0, index: BufferIndex.ConstantBufferIndex.rawValue)
        /// determines how many threads and thread groups are needed in order to handle the update of all springs
        let h = springPipelineState.threadExecutionWidth
        let threadsPerThreadGroup = MTLSize(width: h, height: 1, depth: 1)
        let threadsPerGrid = MTLSize(width: mesh.springCount, height: 1, depth: 1)
        /// sents information about threads to GPU
        computeCommandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        /// finishes the process of translating commands
        computeCommandEncoder.endEncoding()
        /// starts computation process on GPU
        commandBuffer.commit()
        /// wait for the GPU to finish all tasks
        commandBuffer.waitUntilCompleted()
    }
    // updates particles
    func updateParticles(dt: Float, mesh: Mesh) {
        /// commandBuffer contains all commands that the GPU should execute
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        /// computeCommandEncoder translates commands into a form that the GPU can understand
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        /// sets particle_update function as current compute function
        computeCommandEncoder.setComputePipelineState(particlePipelineState)
        /// sets buffers into computeCommandEncoder that contain model data (such as position of particles of springs contstants)
        computeCommandEncoder.setBuffer(mesh.particleBuffer, offset: 0, index: BufferIndex.ParticleBufferIndex.rawValue)
        computeCommandEncoder.setBuffer(mesh.springBuffer, offset: 0, index: BufferIndex.SpringBufferIndex.rawValue)
        let physicalUniforms = [dt, -gravity]
        let constants = device.makeBuffer(bytes: physicalUniforms, length: MemoryLayout<Float>.stride * 2, options: [])
        computeCommandEncoder.setBuffer(constants, offset: 0, index: BufferIndex.PhysicalUniformsBufferIndex.rawValue)
        /// determines how many threads and thread groups are needed in order to handle the update of all springs
        let h = particlePipelineState.threadExecutionWidth
        let threadsPerThreadGroup = MTLSize(width: h, height: 1, depth: 1)
        let threadsPerGrid = MTLSize(width: mesh.particleCount, height: 1, depth: 1)
        /// sents information about threads to GPU
        computeCommandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        /// finishes the process of translating commands
        computeCommandEncoder.endEncoding()
        /// starts computation process on GPU
        commandBuffer.commit()
        /// wait for the GPU to finish all tasks
        commandBuffer.waitUntilCompleted()
    }
}


