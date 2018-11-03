

import Metal
import GLKit



protocol Renderable {
    
    var vertexCount: Int { get }
    var clearColor: MTLClearColor { get set }
    var projectionMatrix: float4x4 { get set }
    var modelViewMatrix: float4x4 { get }
    var setBufferHandler: ( inout MTLRenderCommandEncoder) -> Void { get }
    var otherRenderingBuffer: MTLBuffer? { get set }
    var otherVertexCount: Int { get } 
}

protocol Updatable {
    
    var updateHandler: (_ dt: Float) -> Void { get set }
    
    
}

typealias NonRealTimeRenderable = Renderable & Updatable

let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100
let maxBuffersInFlight = 3



class Renderer: NSObject {
    
    
    var device: MTLDevice
    var renderPipelineState: MTLRenderPipelineState
    var otherRenderPipelineState: MTLRenderPipelineState?
    var commandQueue: MTLCommandQueue
    var primitiveType: MTLPrimitiveType
    
    var dynamicUniformBuffer: MTLBuffer
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>

    
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue, vertexFunctionName: String, fragmentFunctionName: String, primitiveType: MTLPrimitiveType, vertexDescriptor: MTLVertexDescriptor? = nil, otherFragmentFunctionName: String? = nil) {

        self.device = device
        let library = device.makeDefaultLibrary()!
        let vertexFuntion = library.makeFunction(name: vertexFunctionName)!
        let fragmentFunction = library.makeFunction(name: fragmentFunctionName)!
        
   
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFuntion
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        if let vertexDescriptor = vertexDescriptor {
            renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        }
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        if let name = otherFragmentFunctionName {
            let otherPipelineDescriptor = MTLRenderPipelineDescriptor()
            let otherRenderFunction = library.makeFunction(name: name)!
            otherPipelineDescriptor.vertexFunction = otherRenderFunction
            otherPipelineDescriptor.fragmentFunction = fragmentFunction
            otherPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            self.otherRenderPipelineState = try! device.makeRenderPipelineState(descriptor: otherPipelineDescriptor)
        }
        
        
        self.commandQueue = commandQueue
        self.primitiveType = primitiveType
        
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        self.dynamicUniformBuffer = self.device.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared])!
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to: Uniforms.self, capacity: 1)
        
        super.init()
    }
    
    
    func renderFrame(renderObject: Renderable, drawable: CAMetalDrawable) {
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        let semaphore = inFlightSemaphore
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        commandBuffer.addCompletedHandler { (_) in semaphore.signal() }
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
        uniforms[0].projectionMatrix = renderObject.projectionMatrix
        uniforms[0].modelViewMatrix = renderObject.modelViewMatrix
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = renderObject.clearColor
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        var renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderObject.setBufferHandler(&renderEncoder)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: 0, index: BufferIndex.UniformsBufferIndex.rawValue) // TODO: correct in draw to texture and let renderObject do this task
        renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: renderObject.vertexCount)
        renderEncoder.endEncoding()
        
        if let otherRenderBuffer = renderObject.otherRenderingBuffer, let pipelineState = self.otherRenderPipelineState {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].storeAction = .store

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(otherRenderBuffer, offset: 0, index: BufferIndex.OtherRenderingBufferIndex.rawValue)
            renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: 0, index: BufferIndex.UniformsBufferIndex.rawValue) // TODO: correct in draw to texture and let renderObject do this task
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: renderObject.vertexCount)
            renderEncoder.endEncoding()
            
        }
        
        
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }

    
    func drawToTexture(texture: inout MTLTexture, renderObject: Renderable) {
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        let semaphore = inFlightSemaphore
        
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        commandBuffer.addCompletedHandler { (_) in semaphore.signal() }
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
        uniforms[0].projectionMatrix = renderObject.projectionMatrix
        uniforms[0].modelViewMatrix = renderObject.modelViewMatrix
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = renderObject.clearColor
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        var renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderObject.setBufferHandler(&renderEncoder)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: 0, index: BufferIndex.UniformsBufferIndex.rawValue)
        renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: renderObject.vertexCount)
        renderEncoder.endEncoding()
        
        if let otherRenderBuffer = renderObject.otherRenderingBuffer, let pipelineState = self.otherRenderPipelineState {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(otherRenderBuffer, offset: 0, index: BufferIndex.OtherRenderingBufferIndex.rawValue)
            renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: 0, index: BufferIndex.UniformsBufferIndex.rawValue) // TODO: correct in draw to texture and let renderObject do this task
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: renderObject.vertexCount)
            renderEncoder.endEncoding()
            
        }
        
        
        let copybackEncoder = commandBuffer.makeBlitCommandEncoder()!
        copybackEncoder.synchronize(resource: texture)
        copybackEncoder.endEncoding()
        
        commandBuffer.commit()
        
    }
    


    
    func renderMovie(size: CGSize, seconds: Float, deltaTime: Float, renderObject: NonRealTimeRenderable, url: URL) {
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: Int(size.width), height: Int(size.height), mipmapped: false)
        textureDescriptor.usage = .renderTarget
        textureDescriptor.storageMode = .managed
        
        
        var texture = device.makeTexture(descriptor: textureDescriptor)!
        
        
        let recorder = VideoRecorder(outputURL: url, size: size)
        
        guard recorder != nil else {
            fatalError("VideoRecoder could not be initialized")
        }
        
        recorder!.startRecording()
        
        for time in stride(from: 0, through: seconds, by: deltaTime) {
            renderObject.updateHandler(deltaTime)
            drawToTexture(texture: &texture, renderObject: renderObject)
            recorder!.writeFrame(forTexture: texture, time: TimeInterval(time))
            
        }
        
        
        recorder!.endRecording{ print("finished rendering") }
        
        
    }
    

}













