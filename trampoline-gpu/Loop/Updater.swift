
import Metal
import simd


class MeshUpdater: NSObject {
    
    
    var device: MTLDevice
    var springPipelineState: MTLComputePipelineState
    var particlePipelineState: MTLComputePipelineState
    var commandQueue: MTLCommandQueue
    var gravity: Float = 0
    var dataController: DataController?

    
    
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue, springFunctionName: String, particleFunctionName: String) {
        self.device = device
        self.commandQueue = commandQueue
        let library = device.makeDefaultLibrary()!
        let springFunction = library.makeFunction(name: springFunctionName)!
        let particleFunction = library.makeFunction(name: particleFunctionName)!
        self.springPipelineState = try! device.makeComputePipelineState(function: springFunction)
        self.particlePipelineState = try! device.makeComputePipelineState(function: particleFunction)
    }
    
    func update(dt: Float, mesh: Mesh) {
        updateSprings(mesh: mesh)
        if let dataController = self.dataController {
            dataController.update()
        }
        
        updateParticles(dt: dt, mesh: mesh)
        
    }

    func updateSprings(mesh: Mesh) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(springPipelineState)

        computeCommandEncoder.setBuffer(mesh.particleBuffer, offset: 0, index: BufferIndex.ParticleBufferIndex.rawValue)
        computeCommandEncoder.setBuffer(mesh.springBuffer, offset: 0, index: BufferIndex.SpringBufferIndex.rawValue)

        let h = springPipelineState.threadExecutionWidth
        let threadsPerThreadGroup = MTLSize(width: h, height: 1, depth: 1)
        let threadsPerGrid = MTLSize(width: mesh.springCount, height: 1, depth: 1)

        computeCommandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
    }

    func updateParticles(dt: Float, mesh: Mesh) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(particlePipelineState)

        computeCommandEncoder.setBuffer(mesh.particleBuffer, offset: 0, index: BufferIndex.ParticleBufferIndex.rawValue)
        computeCommandEncoder.setBuffer(mesh.springBuffer, offset: 0, index: BufferIndex.SpringBufferIndex.rawValue)
        let constantsArray = [dt, gravity]
        let constants = device.makeBuffer(bytes: constantsArray, length: MemoryLayout<Float>.stride * 2, options: [])
        computeCommandEncoder.setBuffer(constants, offset: 0, index: BufferIndex.ConstantsBufferIndex.rawValue)
        let h = particlePipelineState.threadExecutionWidth
        let threadsPerThreadGroup = MTLSize(width: h, height: 1, depth: 1)
        let threadsPerGrid = MTLSize(width: mesh.particleCount, height: 1, depth: 1)

        computeCommandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
    }
}


