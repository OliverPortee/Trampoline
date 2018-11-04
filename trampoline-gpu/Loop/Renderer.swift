

import Metal
import GLKit





protocol Renderable {
    var vertexCount: Int { get }
    var setBufferHandlerWhenRendering: ( inout MTLRenderCommandEncoder) -> Void { get }
    var primitiveType: MTLPrimitiveType { get }
    var renderPipelineState: MTLRenderPipelineState { get }
}

protocol BaseRenderable: Renderable {
    var clearColor: MTLClearColor { get set }
    var projectionMatrix: float4x4 { get set }
    var modelViewMatrix: float4x4 { get }
    var otherRendering: [Renderable] { get }
}

protocol Updatable {
    
    var updateHandler: (_ dt: Float) -> Void { get set }
    
    
}

typealias NonRealTimeRenderable = BaseRenderable & Updatable

let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100
let maxBuffersInFlight = 3



class Renderer: NSObject {
    
    
    var device: MTLDevice

    var commandQueue: MTLCommandQueue
    
    var dynamicUniformBuffer: MTLBuffer
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>
    private var recorder: VideoRecorder?
    var movieRenderTime: Double?
    var shouldRenderMovie = false
    
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
        
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        self.dynamicUniformBuffer = self.device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared])!
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to: Uniforms.self, capacity: 1)
        
        super.init()
    }
    
    
    func startRecording(size: CGSize, url: URL) {
        self.recorder = VideoRecorder(outputURL: url, size: size)
        self.recorder!.startRecording()
        movieRenderTime = 0
    }
    
    func stopRecording() {
        self.recorder?.endRecording { print("finished movie") }
        self.recorder = nil
        movieRenderTime = nil
    }
    
    private func renderRenderable(_ renderObject: Renderable, commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {

        var renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderObject.renderPipelineState)
        renderObject.setBufferHandlerWhenRendering(&renderEncoder)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: 0, index: BufferIndex.UniformsBufferIndex.rawValue) // TODO: correct in draw to texture and let renderObject do this task
        renderEncoder.drawPrimitives(type: renderObject.primitiveType, vertexStart: 0, vertexCount: renderObject.vertexCount)
        renderEncoder.endEncoding()

    }
    

    
    func renderFrame(renderObject: BaseRenderable, drawable: CAMetalDrawable, renderOnlyOtherRenderObjects: Bool, dt: Double) {
        
        var shouldClear = true
        func getRenderPassDescriptor(drawable: CAMetalDrawable, clearColor: MTLClearColor) -> MTLRenderPassDescriptor {
            if shouldClear {
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = drawable.texture
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].clearColor = clearColor
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                shouldClear = false
                return renderPassDescriptor
            } else {
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = drawable.texture
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                return renderPassDescriptor
            }
        }
        
//        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
//        let semaphore = inFlightSemaphore
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
//        commandBuffer.addCompletedHandler { (_) in semaphore.signal() }
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
        uniforms[0].projectionMatrix = renderObject.projectionMatrix
        uniforms[0].modelViewMatrix = renderObject.modelViewMatrix

        if renderOnlyOtherRenderObjects == false {
            let renderPassDescriptor = getRenderPassDescriptor(drawable: drawable, clearColor: renderObject.clearColor)
            renderRenderable(renderObject, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        }
        for otherRenderObject in renderObject.otherRendering {
            let renderPassDescriptor = getRenderPassDescriptor(drawable: drawable, clearColor: renderObject.clearColor)
            renderRenderable(otherRenderObject, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        }

        
        if let recorder = self.recorder, movieRenderTime != nil {


            movieRenderTime! += dt
            
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: Int(drawable.texture.width), height: Int(drawable.texture.height), mipmapped: false)
            textureDescriptor.usage = .renderTarget
            textureDescriptor.storageMode = .managed
            let newTexture = device.makeTexture(descriptor: textureDescriptor)!

            copyTexture(buffer: commandBuffer, from: drawable.texture, to: newTexture)
            
//            let newTexture = drawable.texture.makeTextureView(pixelFormat: .a8Unorm)!
            recorder.writeFrame(forTexture: newTexture, time: movieRenderTime!)
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()

    }
    
    func copyTexture(encoder: MTLBlitCommandEncoder, from: MTLTexture, to: MTLTexture) {
        let width = min(from.width, to.width)
        let height = min(from.height, to.height)
        let depth = min(from.depth, to.depth)
        let size = MTLSize(width: width, height: height, depth: depth)
        encoder.copy(from: from, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: size,
                     to: to, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
    }
    func copyTexture(buffer: MTLCommandBuffer, from: MTLTexture, to: MTLTexture) {
        guard let blit = buffer.makeBlitCommandEncoder() else {
            return
        }
        copyTexture(encoder: blit, from: from, to: to)
        blit.synchronize(resource: to)

        blit.endEncoding()
    }

    
//    func drawToTexture(renderObject: BaseRenderable, texture: inout MTLTexture) {
//        var shouldClear = true
//        func getRenderPassDescriptor(clearColor: MTLClearColor) -> MTLRenderPassDescriptor {
//            if shouldClear {
//                let renderPassDescriptor = MTLRenderPassDescriptor()
//                renderPassDescriptor.colorAttachments[0].texture = texture
//                renderPassDescriptor.colorAttachments[0].loadAction = .clear
//                renderPassDescriptor.colorAttachments[0].clearColor = clearColor
//                renderPassDescriptor.colorAttachments[0].storeAction = .store
//                shouldClear = false
//                return renderPassDescriptor
//            } else {
//                let renderPassDescriptor = MTLRenderPassDescriptor()
//                renderPassDescriptor.colorAttachments[0].texture = texture
//                renderPassDescriptor.colorAttachments[0].storeAction = .store
//                return renderPassDescriptor
//            }
//        }
//
//        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
//        let semaphore = inFlightSemaphore
//
//        let commandBuffer = self.commandQueue.makeCommandBuffer()!
//        commandBuffer.addCompletedHandler { (_) in semaphore.signal() }
//
//        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
//        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
//        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
//        uniforms[0].projectionMatrix = renderObject.projectionMatrix
//        uniforms[0].modelViewMatrix = renderObject.modelViewMatrix
//
//
//        let renderPassDescriptor = getRenderPassDescriptor(clearColor: renderObject.clearColor)
//        renderRenderable(renderObject, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
//
//        for otherRenderObject in renderObject.otherRendering {
//            let renderPassDescriptor = getRenderPassDescriptor(clearColor: renderObject.clearColor)
//            renderRenderable(otherRenderObject, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
//        }
//
//        let copybackEncoder = commandBuffer.makeBlitCommandEncoder()!
//        copybackEncoder.synchronize(resource: texture)
//        copybackEncoder.endEncoding()
//
//        commandBuffer.commit()
//
//    }
//


    
//    func renderMovie(size: CGSize, seconds: Float, deltaTime: Float, renderObject: NonRealTimeRenderable, url: URL) {
//
//        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: Int(size.width), height: Int(size.height), mipmapped: false)
//        textureDescriptor.usage = .renderTarget
//        textureDescriptor.storageMode = .managed
//
//
//        var texture = device.makeTexture(descriptor: textureDescriptor)!
//
//
//        let recorder = VideoRecorder(outputURL: url, size: size)
//
//        guard recorder != nil else {
//            fatalError("VideoRecoder could not be initialized")
//        }
//
//        recorder!.startRecording()
//
//        for time in stride(from: 0, through: seconds, by: deltaTime) {
//            renderObject.updateHandler(deltaTime)
//            drawToTexture(renderObject: renderObject, texture: &texture)
//            recorder!.writeFrame(forTexture: texture, time: TimeInterval(time))
//
//        }
//
//
//        recorder!.endRecording{ print("finished rendering") }
//
//
//    }
    

}













